::raya_timer <-
{
	TimersList = {}
	TimersID = {}
	ClockList = {}
	count = 0
}

::raya_timer.AddTimerByName <- function(strName, delay, repeat, func, paramTable = null, flags = 0, value = {}){
	::raya_timer.RemoveTimerByName(strName);
	::raya_timer.TimersID[strName] <- ::raya_timer.AddTimer(delay, repeat, func, paramTable, flags, value);
	return strName;
}

::raya_timer.RemoveTimerByName <- function(strName){
	if (strName in ::raya_timer.TimersID)
	{
		::raya_timer.RemoveTimer(::raya_timer.TimersID[strName]);
		delete ::raya_timer.TimersID[strName];
	}
}

::raya_timer.itemExRemoveTimer <- function(idx){
	if (idx in ::raya_timer.TimersList)
		delete ::raya_timer.TimersList[idx];
}

::raya_timer.AddTimer <- function(delay, repeat, func, paramTable = null, flags = 0, value = {})
{
	local TIMER_FLAG_COUNTDOWN = (1 << 2);
	local TIMER_FLAG_DURATION = (1 << 3);
	local TIMER_FLAG_DURATION_VARIANT = (1 << 4);
	local countg = ::raya_timer.count;
	
	delay = delay.tofloat();
	repeat = repeat.tointeger();
	
	local rep = (repeat > 0) ? true : false;
	
	if (paramTable == null)
		paramTable = {};
	
	if (typeof value != "table")
	{
		return -1;
	}
	else if (flags & TIMER_FLAG_COUNTDOWN && !("countg" in value))
	{
		return -1;
	}
	else if ((flags & TIMER_FLAG_DURATION || flags & TIMER_FLAG_DURATION_VARIANT) && !("duration" in value))
	{
		return -1;
	}
	
	if (flags & TIMER_FLAG_DURATION)
	{
		flags = flags & ~TIMER_FLAG_DURATION;
		flags = flags | TIMER_FLAG_COUNTDOWN;
		
		value["countg"] <- floor(value["duration"].tofloat() / delay);
	}
	
	++countg;
	::raya_timer.TimersList[countg] <-
	{
		_delay = delay
		_func = func
		_params = paramTable
		_startTime = Time()
		_baseTime = Time()
		_repeat = rep
		_flags = flags
		_opval = value
	}
	
	::raya_timer.count = countg;
	return countg;
}

::raya_timer.T_thinkFunc <- function()
{
	local TIMER_FLAG_COUNTDOWN = (1 << 2);
	local TIMER_FLAG_DURATION_VARIANT = (1 << 4);
	
	local curtime = Time();
	
	foreach (idx, timer in ::raya_timer.TimersList)
	{
		if ((curtime - timer._startTime) >= timer._delay)
		{
			if (timer._flags & TIMER_FLAG_COUNTDOWN)
			{
				timer._params["TimerCount"] <- timer._opval["count"];
				
				if ((--timer._opval["count"]) <= 0)
					timer._repeat = false;
			}
			
			if (timer._flags & TIMER_FLAG_DURATION_VARIANT && (curtime - timer._baseTime) > timer._opval["duration"])
			{
				delete ::raya_timer.TimersList[idx];
				continue;
			}
			
			try
			{
				if (timer._func(timer._params) == false)
					timer._repeat = false;
			}
			catch (id)
			{
				if(id == null)return;
				local deadFunc = timer._func;
				local params = timer._params;
				delete ::raya_timer.TimersList[idx];
				deadFunc(params);
				continue;
			}
			
			if (timer._repeat)
				timer._startTime = curtime;
			else
				if (idx in ::raya_timer.TimersList)
					delete ::raya_timer.TimersList[idx];
		}
	}

	foreach (idx, timer in ::raya_timer.ClockList)
	{
		if ( Time() > timer._lastUpdateTime )
		{
			local newTime = Time() - timer._lastUpdateTime;
			
			if ( timer._command == 1 )
				timer._value += newTime;
			else if ( timer._command == 2 )
			{
				if ( timer._allowNegTimer )
					timer._value -= newTime;
				else
				{
					if ( timer._value > 0 )
						timer._value -= newTime;
				}
			}
			
			timer._lastUpdateTime <- Time();
		}
	}
}

if (!("_thinkTimer" in ::raya_timer))
{
	::raya_timer._thinkTimer <- SpawnEntityFromTable("info_target", { targetname = "vslib_timer" });
	if (::raya_timer._thinkTimer != null)
	{
		::raya_timer._thinkTimer.ValidateScriptScope();
		local scrScope = ::raya_timer._thinkTimer.GetScriptScope();
		scrScope["ThinkTimer"] <- ::raya_timer.T_thinkFunc;
		AddThinkToEnt(::raya_timer._thinkTimer, "ThinkTimer");
	}
	else
		return;
}