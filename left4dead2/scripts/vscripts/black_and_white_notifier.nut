Convars.SetValue("sv_consistency", 0);
Convars.SetValue("sv_pure_kick_clients", 0);

::AddTimerss <-
{
	TimersList = {}
	TimersID = {}
	ClockList = {}
	count = 0
}

::AddTimerByName <- function(strName, delay, repeat, func, paramTable = null, flags = 0, value = {}){
	::RemoveTimerByName(strName);
	::AddTimerss.TimersID[strName] <- ::AddTimer(delay, repeat, func, paramTable, flags, value);
	return strName;
}

::RemoveTimerByName <- function(strName){
	if (strName in ::AddTimerss.TimersID)
	{
		::AddTimerss.RemoveTimer(::AddTimerss.TimersID[strName]);
		delete ::AddTimerss.TimersID[strName];
	}
}

::itemExRemoveTimer <- function(idx){
	if (idx in ::AddTimerss.TimersList)
		delete ::AddTimerss.TimersList[idx];
}

::AddTimer <- function(delay, repeat, func, paramTable = null, flags = 0, value = {})
{
	local TIMER_FLAG_COUNTDOWN = (1 << 2);
	local TIMER_FLAG_DURATION = (1 << 3);
	local TIMER_FLAG_DURATION_VARIANT = (1 << 4);
	local countg = ::AddTimerss.count;
	
	delay = delay.tofloat();
	repeat = repeat.tointeger();
	
	local rep = (repeat > 0) ? true : false;
	
	if (paramTable == null)
		paramTable = {};
	
	if (typeof value != "table")
	{
		//printf("VSLib Timer Error: Illegal parameter: 'value' parameter needs to be a table.");
		return -1;
	}
	else if (flags & TIMER_FLAG_COUNTDOWN && !("countg" in value))
	{
		//printf("VSLib Timer Error: Could not create the countdown timer because the 'count' field is missing from 'value'.");
		return -1;
	}
	else if ((flags & TIMER_FLAG_DURATION || flags & TIMER_FLAG_DURATION_VARIANT) && !("duration" in value))
	{
		//printf("VSLib Timer Error: Could not create the duration timer because the 'duration' field is missing from 'value'.");
		return -1;
	}
	
	// Convert the flag into countdown
	if (flags & TIMER_FLAG_DURATION)
	{
		flags = flags & ~TIMER_FLAG_DURATION;
		flags = flags | TIMER_FLAG_COUNTDOWN;
		
		value["countg"] <- floor(value["duration"].tofloat() / delay);
	}
	
	++countg;
	::AddTimerss.TimersList[countg] <-
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
	
	::AddTimerss.count = countg;
	return countg;
}

::T_thinkFunc <- function()
{
	local TIMER_FLAG_COUNTDOWN = (1 << 2);
	local TIMER_FLAG_DURATION_VARIANT = (1 << 4);
	
	// current time
	local curtime = Time();
	
	// Execute timers as needed
	foreach (idx, timer in ::AddTimerss.TimersList)
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
				delete ::AddTimerss.TimersList[idx];
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
				//printf("VSLib Timer caught exception; closing timer %d. Error was: %s", idx, id.tostring());
				local deadFunc = timer._func;
				local params = timer._params;
				delete ::AddTimerss.TimersList[idx];
				deadFunc(params); // this will most likely throw
				continue;
			}
			
			if (timer._repeat)
				timer._startTime = curtime;
			else
				if (idx in ::AddTimerss.TimersList) // recheck-- timer may have been removed by timer callback
					delete ::AddTimerss.TimersList[idx];
		}
	}
	foreach (idx, timer in ::AddTimerss.ClockList)
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

/*
 * Create a think timer
 */
if (!("_thinkTimer" in ::AddTimerss))
{
	::AddTimerss._thinkTimer <- SpawnEntityFromTable("info_target", { targetname = "vslib_timer" });
	if (::AddTimerss._thinkTimer != null)
	{
		::AddTimerss._thinkTimer.ValidateScriptScope();
		local scrScope = ::AddTimerss._thinkTimer.GetScriptScope();
		scrScope["ThinkTimer"] <- ::T_thinkFunc;
		AddThinkToEnt(::AddTimerss._thinkTimer, "ThinkTimer");
	}
	else
		return;
}

::BAWYammy<-
{
	bawn_outline = 1
	bawn_outline_flash = 0
	bawn_color = 1
	bawn_color_R = 255
	bawn_time = 30
	bawn_time_float = 30.0
	bawn_chat = 1
}

if (!Entities.FindByName(null, "b_a_w_notifier1")) {SpawnEntityFromTable("logic_timer",{targetname="b_a_w_notifier1",RefireTime = 0.1 , OnTimer = "!caller,runscriptcode,b_a_w_notifier1_think()"});}
::on <- 1;
::ent <- null;
::b_a_w_notifier1_think <-function()
{
	while(ent = Entities.FindByClassname(ent,"player"))
	{
		if(ent != null && ent.IsValid())
		{
			if(ent.IsSurvivor())
			{
				if(NetProps.GetPropInt(ent, "m_bIsOnThirdStrike") != 1 || ent.IsDead() || ent.IsDying() || ::BAWYammy.bawn_outline == 0)
				{
					if(NetProps.GetPropInt(ent, "m_Glow.m_iGlowType") != 0)
					{
						NetProps.SetPropInt(ent, "m_Glow.m_iGlowType", 0);
					}
				}
			}
				
			if(!ent.IsSurvivor())
			{
				//if(ent.GetZombieType() == 8 || ent.GetZombieType() == 6 || ent.GetZombieType() == 5 || ent.GetZombieType() == 4 || ent.GetZombieType() == 3 || ent.GetZombieType() == 2 || ent.GetZombieType() == 1 || ent.IsGhost())
				//{
					if(NetProps.GetPropInt(ent, "m_Glow.m_iGlowType") != 0)
					{
						NetProps.SetPropInt(ent, "m_Glow.m_iGlowType", 0);
					}
				//}
			}
		}
	}
}
		
::BAWYam<-
{
	function OnGameEvent_player_say(params)
	{
		local Sayer = GetPlayerFromUserID(params.userid);
		local chat = params.text.tolower(); // params.text.tolower
	
		if(Sayer == GetListenServerHost())
		{

			local arr = split(chat, " "); 
	
			// Build an argument array
			local args = {};
			local idx = -1;
			foreach (k, v in arr)
			{
				if (k != -1 && v != null && v != "")
				{
					args[idx] <- v;
					idx++;
				}
			}
	
			// Store it.
			LastArgs <- args;
				
			local Command = LastArgs[-1];
			
			switch ( Command )
			{
				case "!bawn_outline":
				{
					if(!(0 in LastArgs))
					{
						ClientPrint(Sayer,3,format("Enable outline of black-and-white survivor (current value: " + ::BAWYammy.bawn_outline + ")"));
						ClientPrint(Sayer,3,format("[Usage] !bawn_outline VALUE[1:Enable / 0:Disable]"));
						return;
					}
					
					if (LastArgs[0])
					{
						local CommandValue = LastArgs[0];
						local CommandValueInt = CommandValue.tointeger();
					
						if(CommandValueInt == 1)
						{
							ClientPrint(Sayer,3,format("Outline of black-and-white survivor is now enabled"));
							
							::BAWYammy.bawn_outline = CommandValueInt;
							StringToFile("black_and_white_notifier/bawn_outline.txt", "1");
							return;
						}
						if(CommandValueInt == 0)
						{
							ClientPrint(Sayer,3,format("Outline of black-and-white survivor is now disabled"));
							
							::BAWYammy.bawn_outline = CommandValueInt;
							StringToFile("black_and_white_notifier/bawn_outline.txt", "0");
							return;
						}
						else
						{
						
							ClientPrint(Sayer,3,format("Incorrect value. It must be 1 or 0"));
							return;
						}
					}
				}
				
				case "!bawn_color":
				{
					if(!(0 in LastArgs))
					{
						ClientPrint(Sayer,3,format("Set the color of outline of black-and-white survivor (current value: " + ::BAWYammy.bawn_color + ")"));
						ClientPrint(Sayer,3,format("[Usage] !bawn_color VALUE[1:Red/2:Faint dark red/3:Green/4:Yellow/5:Blue/6:White/7:Pink]")); // 80(dark red), 255(red), 65280(green), 65535(yellow), 16711680(blue) , 16777215(white), 16711935(pink?)
						return;
					}
					
					if (LastArgs[0])
					{
						local CommandValue = LastArgs[0];
						local CommandValueInt = CommandValue.tointeger();
					
						if(CommandValueInt == 1)
						{
							ClientPrint(Sayer,3,format("The color of outline is now red"));
							
							::BAWYammy.bawn_color = CommandValueInt;
							StringToFile("black_and_white_notifier/bawn_color.txt", "1");
							
							::BAWYammy.bawn_color_R = 255;
							return;
						}
						if(CommandValueInt == 2)
						{
							ClientPrint(Sayer,3,format("The color of outline is now faint dark red"));
							
							::BAWYammy.bawn_color = CommandValueInt;
							StringToFile("black_and_white_notifier/bawn_color.txt", "2");
							
							::BAWYammy.bawn_color_R = 80;
							return;
						}
						if(CommandValueInt == 3)
						{
							ClientPrint(Sayer,3,format("The color of outline is now green"));
							
							::BAWYammy.bawn_color = CommandValueInt;
							StringToFile("black_and_white_notifier/bawn_color.txt", "3");
							
							::BAWYammy.bawn_color_R = 65280;
							return;
						}
						if(CommandValueInt == 4)
						{
							ClientPrint(Sayer,3,format("The color of outline is now yellow"));
							
							::BAWYammy.bawn_color = CommandValueInt;
							StringToFile("black_and_white_notifier/bawn_color.txt", "4");
							
							::BAWYammy.bawn_color_R = 65535;
							return;
						}
						if(CommandValueInt == 5)
						{
							ClientPrint(Sayer,3,format("The color of outline is now blue"));
							
							::BAWYammy.bawn_color = CommandValueInt;
							StringToFile("black_and_white_notifier/bawn_color.txt", "5");
							
							::BAWYammy.bawn_color_R = 16711680;
							return;
						}
						if(CommandValueInt == 6)
						{
							ClientPrint(Sayer,3,format("The color of outline is now white"));
							
							::BAWYammy.bawn_color = CommandValueInt;
							StringToFile("black_and_white_notifier/bawn_color.txt", "6");
							
							::BAWYammy.bawn_color_R = 16777215;
							return;
						}
						if(CommandValueInt == 7)
						{
							ClientPrint(Sayer,3,format("The color of outline is now pink"));
							
							::BAWYammy.bawn_color = CommandValueInt;
							StringToFile("black_and_white_notifier/bawn_color.txt", "7");
							
							::BAWYammy.bawn_color_R = 16711935;
							return;
						}
						else
						{
						
							ClientPrint(Sayer,3,format("Incorrect value. It must be 1(Red), 2(Faint dark red), 3(Green), 4(Yellow), 5(Blue), 6(White) or 7(Pink)"));
							return;
						}
					}
				}
				
				case "!bawn_time":
				{
					if(!(0 in LastArgs))
					{
						ClientPrint(Sayer,3,format("Set the duration of outline of black-and-white survivor (unit: second) (current value: " + ::BAWYammy.bawn_time + ")"));
						ClientPrint(Sayer,3,format("[Usage] !bawn_time VALUE[1 ~ 120 / 0: Infinite]"));
						return;
					}
					
					if (LastArgs[0])
					{
						local CommandValue = LastArgs[0];
						local CommandValueInt = CommandValue.tointeger();
					
						if(CommandValueInt >= 1 && CommandValueInt <= 120)
						{
							ClientPrint(Sayer,3,format("The duration of outline changed from " + ::BAWYammy.bawn_time + " to " +  CommandValueInt ));
							
							::BAWYammy.bawn_time = CommandValueInt;
							::BAWYammy.bawn_time_float = ::BAWYammy.bawn_time.tofloat();
							local CommandValueString = CommandValueInt.tostring();
							StringToFile("black_and_white_notifier/bawn_time.txt", CommandValueString);
							return;
						}
						if(CommandValueInt == 0)
						{
							ClientPrint(Sayer,3,format("The duration of outline is now infinite"));
							
							::BAWYammy.bawn_time = CommandValueInt;
							::BAWYammy.bawn_time_float = 0.0;
							StringToFile("black_and_white_notifier/bawn_time.txt", "0");
							return;
						}
						else
						{
							ClientPrint(Sayer,3,format("Incorrect value. It must be between 1 and 120 or 0"));
							return;
						}
					}
				}
				
				case "!bawn_chat":
				{
					if(!(0 in LastArgs))
					{
						ClientPrint(Sayer,3,format("Enable chat notifier of black-and-white survivor (current value: " + ::BAWYammy.bawn_chat + ")"));
						ClientPrint(Sayer,3,format("[Usage] !bawn_chat VALUE[1:Enable / 0:Disable]"));
						return;
					}
					
					if (LastArgs[0])
					{
						local CommandValue = LastArgs[0];
						local CommandValueInt = CommandValue.tointeger();
					
						if(CommandValueInt == 1)
						{
							ClientPrint(Sayer,3,format("Chat notifier of black-and-white survivor is now enabled"));
							
							::BAWYammy.bawn_chat = CommandValueInt;
							StringToFile("black_and_white_notifier/bawn_chat.txt", "1");
							return;
						}
						if(CommandValueInt == 0)
						{
							ClientPrint(Sayer,3,format("Chat notifier of black-and-white survivor is now disabled"));
							
							::BAWYammy.bawn_chat = CommandValueInt;
							StringToFile("black_and_white_notifier/bawn_chat.txt", "0");
							return;
						}
						else
						{
						
							ClientPrint(Sayer,3,format("Incorrect value. It must be 1 or 0"));
							return;
						}
					}
				}
				
				case "!bawn_outline_flash":
				{
					if(!(0 in LastArgs))
					{
						ClientPrint(Sayer,3,format("Enable the flash effect of outline (current value: " + ::BAWYammy.bawn_outline_flash + ")"));
						ClientPrint(Sayer,3,format("[Usage] !bawn_outline_flash VALUE[1:Enable / 0:Disable]"));
						return;
					}
					
					if (LastArgs[0])
					{
						local CommandValue = LastArgs[0];
						local CommandValueInt = CommandValue.tointeger();
					
						if(CommandValueInt == 1)
						{
							ClientPrint(Sayer,3,format("The flash effect of outline is now enabled"));
							
							::BAWYammy.bawn_outline_flash = CommandValueInt;
							StringToFile("black_and_white_notifier/bawn_outline_flash.txt", "1");
							return;
						}
						if(CommandValueInt == 0)
						{
							ClientPrint(Sayer,3,format("The flash effect of outline is now disabled"));
							
							::BAWYammy.bawn_outline_flash = CommandValueInt;
							StringToFile("black_and_white_notifier/bawn_outline_flash.txt", "0");
							return;
						}
						else
						{
							ClientPrint(Sayer,3,format("Incorrect value. It must be 1 or 0"));
							return;
						}
					}
				}
			}
		}
	}
				
				
	function OnGameEvent_revive_success(params)
	{
		local ent = GetPlayerFromUserID(params.subject);
		{
			if(ent != null && ent.IsValid() && ent != 0)
			{
				if(ent.IsPlayer() && ent.GetZombieType() == 9)
				{
					local IsHang = (params.ledge_hang) ? true : false;
					local IsLast = (params.lastlife) ? true : false;

					if(IsHang == false)
					{
						if(IsLast == true && NetProps.GetPropInt(ent, "m_bIsOnThirdStrike") == 1)
						{
						
							if(::BAWYammy.bawn_outline == 1)
							{
								NetProps.SetPropInt(ent, "m_Glow.m_iGlowType", 3);
								NetProps.SetPropInt(ent, "m_Glow.m_glowColorOverride", ::BAWYammy.bawn_color_R); // 80(dark red), 255(red), 65280(green), 65535(yellow), 16711680(blue) , 16777215(white)
								
								if(::BAWYammy.bawn_outline_flash == 1)
								{
									NetProps.SetPropInt(ent, "m_Glow.m_bFlashing", 10);
								}
								if(::BAWYammy.bawn_outline_flash == 0)
								{
									NetProps.SetPropInt(ent, "m_Glow.m_bFlashing", 0);
								}
							}
							
							local Chara = ent.GetModelName();
							if(Chara == "models/survivors/survivor_gambler.mdl")
							{
								if(Entities.FindByName(null, "DelGlowNick"))
								Entities.FindByName(null, "DelGlowNick").Kill();
										
								if(::BAWYammy.bawn_time != 0)
								{
									if (!Entities.FindByName(null, "DelGlowNick")) 
									{
										{SpawnEntityFromTable("logic_timer",{targetname="DelGlowNick",RefireTime = ::BAWYammy.bawn_time_float , OnTimer = "!caller,runscriptcode,DelGlowNick()"});}
										::on <- 1;
										::ent <- null;
										::DelGlowNick <-function()
										{
											if(NetProps.GetPropInt(ent, "m_Glow.m_iGlowType") != 0)
												NetProps.SetPropInt(ent, "m_Glow.m_iGlowType", 0);
											
											if(Entities.FindByName(null, "DelGlowNick"))
												Entities.FindByName(null, "DelGlowNick").Kill();
										}
									}
								}
									
								if(::BAWYammy.bawn_chat == 1)
								{
									local entityx;
									while(entityx = Entities.FindByClassname(entityx,"player"))
									{
										if(entityx != null && entityx.IsValid())
										{
											if(entityx.IsSurvivor())
											{
												if(IsPlayerABot(ent))
												ClientPrint(entityx,3,format("Nick is black and white"));
												
												if(!IsPlayerABot(ent))
												{
													local entName = ent.GetPlayerName();
													ClientPrint(entityx,3,format(entName+" (Nick) is black and white"));
												}
											}
										}
									}
								}
							}
							
							if(Chara == "models/survivors/survivor_coach.mdl")
							{
								if(Entities.FindByName(null, "DelGlowCoach"))
								Entities.FindByName(null, "DelGlowCoach").Kill();
								
								if(::BAWYammy.bawn_time != 0)
								{	
									if (!Entities.FindByName(null, "DelGlowCoach")) 
									{
										{SpawnEntityFromTable("logic_timer",{targetname="DelGlowCoach",RefireTime = ::BAWYammy.bawn_time_float , OnTimer = "!caller,runscriptcode,DelGlowCoach()"});}
										::on <- 1;
										::ent <- null;
										::DelGlowCoach <-function()
										{
											if(NetProps.GetPropInt(ent, "m_Glow.m_iGlowType") != 0)
												NetProps.SetPropInt(ent, "m_Glow.m_iGlowType", 0);
											
											if(Entities.FindByName(null, "DelGlowCoach"))
												Entities.FindByName(null, "DelGlowCoach").Kill();
										}
									}
								}
								
								if(::BAWYammy.bawn_chat == 1)
								{
									local entityx;
									while(entityx = Entities.FindByClassname(entityx,"player"))
									{
										if(entityx != null && entityx.IsValid())
										{
											if(entityx.IsSurvivor())
											{
												if(IsPlayerABot(ent))
												ClientPrint(entityx,3,format("Coach is black and white"));
												
												if(!IsPlayerABot(ent))
												{
													local entName = ent.GetPlayerName();
													ClientPrint(entityx,3,format(entName+" (Coach) is black and white"));
												}
											}
										}
									}
								}
							}
							if(Chara == "models/survivors/survivor_producer.mdl")
							{
								if(Entities.FindByName(null, "DelGlowRochelle"))
								Entities.FindByName(null, "DelGlowRochelle").Kill();
								
								if(::BAWYammy.bawn_time != 0)
								{	
									if (!Entities.FindByName(null, "DelGlowRochelle")) 
									{
										{SpawnEntityFromTable("logic_timer",{targetname="DelGlowRochelle",RefireTime = ::BAWYammy.bawn_time_float , OnTimer = "!caller,runscriptcode,DelGlowRochelle()"});}
										::on <- 1;
										::ent <- null;
										::DelGlowRochelle <-function()
										{
											if(NetProps.GetPropInt(ent, "m_Glow.m_iGlowType") != 0)
												NetProps.SetPropInt(ent, "m_Glow.m_iGlowType", 0);
											
											if(Entities.FindByName(null, "DelGlowRochelle"))
												Entities.FindByName(null, "DelGlowRochelle").Kill();
										}
									}
								}
									
								if(::BAWYammy.bawn_chat == 1)
								{
									local entityx;
									while(entityx = Entities.FindByClassname(entityx,"player"))
									{
										if(entityx != null && entityx.IsValid())
										{
											if(entityx.IsSurvivor())
											{
												if(IsPlayerABot(ent))
												ClientPrint(entityx,3,format("Rochelle is black and white"));
												
												if(!IsPlayerABot(ent))
												{
													local entName = ent.GetPlayerName();
													ClientPrint(entityx,3,format(entName+" (Rochelle) is black and white"));
												}
											}
										}
									}
								}
							}
							if(Chara == "models/survivors/survivor_mechanic.mdl")
							{
								if(Entities.FindByName(null, "DelGlowEllis"))
									Entities.FindByName(null, "DelGlowEllis").Kill();
									
								if(::BAWYammy.bawn_time != 0)
								{	
									if (!Entities.FindByName(null, "DelGlowEllis")) 
									{
										{SpawnEntityFromTable("logic_timer",{targetname="DelGlowEllis",RefireTime = ::BAWYammy.bawn_time_float , OnTimer = "!caller,runscriptcode,DelGlowEllis()"});}
										::on <- 1;
										::ent <- null;
										::DelGlowEllis <-function()
										{
											if(NetProps.GetPropInt(ent, "m_Glow.m_iGlowType") != 0)
												NetProps.SetPropInt(ent, "m_Glow.m_iGlowType", 0);
											
											if(Entities.FindByName(null, "DelGlowEllis"))
												Entities.FindByName(null, "DelGlowEllis").Kill();
										}
									}
								}
								
								if(::BAWYammy.bawn_chat == 1)
								{
									local entityx;
									while(entityx = Entities.FindByClassname(entityx,"player"))
									{
										if(entityx != null && entityx.IsValid())
										{
											if(entityx.IsSurvivor())
											{
												if(IsPlayerABot(ent))
												ClientPrint(entityx,3,format("Ellis is black and white"));
												
												if(!IsPlayerABot(ent))
												{
													local entName = ent.GetPlayerName();
													ClientPrint(entityx,3,format(entName+" (Ellis) is black and white"));
												}
											}
										}
									}
								}
							}
						
							if(Chara == "models/survivors/survivor_namvet.mdl")
							{
								if(Entities.FindByName(null, "DelGlowBill"))
									Entities.FindByName(null, "DelGlowBill").Kill();
									
								if(::BAWYammy.bawn_time != 0)
								{	
									if (!Entities.FindByName(null, "DelGlowBill")) 
									{
										{SpawnEntityFromTable("logic_timer",{targetname="DelGlowBill",RefireTime = ::BAWYammy.bawn_time_float , OnTimer = "!caller,runscriptcode,DelGlowBill()"});}
										::on <- 1;
										::ent <- null;
										::DelGlowBill <-function()
										{
											if(NetProps.GetPropInt(ent, "m_Glow.m_iGlowType") != 0)
												NetProps.SetPropInt(ent, "m_Glow.m_iGlowType", 0);
											
											if(Entities.FindByName(null, "DelGlowBill"))
												Entities.FindByName(null, "DelGlowBill").Kill();
										}
									}
								}
								
								if(::BAWYammy.bawn_chat == 1)
								{
									local entityx;
									while(entityx = Entities.FindByClassname(entityx,"player"))
									{
										if(entityx != null && entityx.IsValid())
										{
											if(entityx.IsSurvivor())
											{
												if(IsPlayerABot(ent))
												ClientPrint(entityx,3,format("Bill is black and white"));
												
												if(!IsPlayerABot(ent))
												{
													local entName = ent.GetPlayerName();
													ClientPrint(entityx,3,format(entName+" (Bill) is black and white"));
												}
											}
										}
									}
								}
							}
							
							if(Chara == "models/survivors/survivor_teenangst.mdl")
							{
								if(Entities.FindByName(null, "DelGlowZoey"))
									Entities.FindByName(null, "DelGlowZoey").Kill();
									
								if(::BAWYammy.bawn_time != 0)
								{	
									if (!Entities.FindByName(null, "DelGlowZoey")) 
									{
										{SpawnEntityFromTable("logic_timer",{targetname="DelGlowZoey",RefireTime = ::BAWYammy.bawn_time_float , OnTimer = "!caller,runscriptcode,DelGlowZoey()"});}
										::on <- 1;
										::ent <- null;
										::DelGlowZoey <-function()
										{
											if(NetProps.GetPropInt(ent, "m_Glow.m_iGlowType") != 0)
												NetProps.SetPropInt(ent, "m_Glow.m_iGlowType", 0);
											
											if(Entities.FindByName(null, "DelGlowZoey"))
												Entities.FindByName(null, "DelGlowZoey").Kill();
										}
									}
								}
							
								if(::BAWYammy.bawn_chat == 1)
								{
									local entityx;
									while(entityx = Entities.FindByClassname(entityx,"player"))
									{
										if(entityx != null && entityx.IsValid())
										{
											if(entityx.IsSurvivor())
											{
												if(IsPlayerABot(ent))
												ClientPrint(entityx,3,format("Zoey is black and white"));
												
												if(!IsPlayerABot(ent))
												{
													local entName = ent.GetPlayerName();
													ClientPrint(entityx,3,format(entName+" (Zoey) is black and white"));
												}
											}
										}
									}
								}
							}
							
							if(Chara == "models/survivors/survivor_manager.mdl")
							{
								if(Entities.FindByName(null, "DelGlowLouis"))
									Entities.FindByName(null, "DelGlowLouis").Kill();
								
								if(::BAWYammy.bawn_time != 0)
								{	
									if (!Entities.FindByName(null, "DelGlowLouis")) 
									{
										{SpawnEntityFromTable("logic_timer",{targetname="DelGlowLouis",RefireTime = ::BAWYammy.bawn_time_float , OnTimer = "!caller,runscriptcode,DelGlowLouis()"});}
										::on <- 1;
										::ent <- null;
										::DelGlowLouis <-function()
										{
											if(NetProps.GetPropInt(ent, "m_Glow.m_iGlowType") != 0)
												NetProps.SetPropInt(ent, "m_Glow.m_iGlowType", 0);
											
											if(Entities.FindByName(null, "DelGlowLouis"))
												Entities.FindByName(null, "DelGlowLouis").Kill();
										}
									}
								}
								
								if(::BAWYammy.bawn_chat == 1)
								{
									local entityx;
									while(entityx = Entities.FindByClassname(entityx,"player"))
									{
										if(entityx != null && entityx.IsValid())
										{
											if(entityx.IsSurvivor())
											{
												if(IsPlayerABot(ent))
												ClientPrint(entityx,3,format("Louis is black and white"));
												
												if(!IsPlayerABot(ent))
												{
													local entName = ent.GetPlayerName();
													ClientPrint(entityx,3,format(entName+" (Louis) is black and white"));
												}
											}
										}
									}
								}
							}
							if(Chara == "models/survivors/survivor_biker.mdl")
							{
								if(Entities.FindByName(null, "DelGlowFrancis"))
									Entities.FindByName(null, "DelGlowFrancis").Kill();
								
								if(::BAWYammy.bawn_time != 0)
								{	
									if (!Entities.FindByName(null, "DelGlowFrancis")) 
									{
										{SpawnEntityFromTable("logic_timer",{targetname="DelGlowFrancis",RefireTime = ::BAWYammy.bawn_time_float , OnTimer = "!caller,runscriptcode,DelGlowFrancis()"});}
										::on <- 1;
										::ent <- null;
										::DelGlowFrancis <-function()
										{
											if(NetProps.GetPropInt(ent, "m_Glow.m_iGlowType") != 0)
												NetProps.SetPropInt(ent, "m_Glow.m_iGlowType", 0);
											
											if(Entities.FindByName(null, "DelGlowFrancis"))
												Entities.FindByName(null, "DelGlowFrancis").Kill();
										}
									}
								}
								
								if(::BAWYammy.bawn_chat == 1)
								{
									local entityx;
									while(entityx = Entities.FindByClassname(entityx,"player"))
									{
										if(entityx != null && entityx.IsValid())
										{
											if(entityx.IsSurvivor())
											{
												if(IsPlayerABot(ent))
												ClientPrint(entityx,3,format("Francis is black and white"));
												
												if(!IsPlayerABot(ent))
												{
													local entName = ent.GetPlayerName();
													ClientPrint(entityx,3,format(entName+" (Francis) is black and white"));
												}
											}
										}
									}
								}
							}
						}
					}
				}
			}
		}
	}
	
	function OnGameEvent_round_start_post_nav(params)
	{
		if(Entities.FindByName(null, "DelGlowNick"))
		Entities.FindByName(null, "DelGlowNick").Kill();
		
		if(Entities.FindByName(null, "DelGlowEllis"))
		Entities.FindByName(null, "DelGlowEllis").Kill();
		
		if(Entities.FindByName(null, "DelGlowRochelle"))
		Entities.FindByName(null, "DelGlowRochelle").Kill();
		
		if(Entities.FindByName(null, "DelGlowCoach"))
		Entities.FindByName(null, "DelGlowCoach").Kill();
		
		if(Entities.FindByName(null, "DelGlowBill"))
		Entities.FindByName(null, "DelGlowBill").Kill();
		
		if(Entities.FindByName(null, "DelGlowZoey"))
		Entities.FindByName(null, "DelGlowZoey").Kill();
		
		if(Entities.FindByName(null, "DelGlowLouis"))
		Entities.FindByName(null, "DelGlowLouis").Kill();
		
		if(Entities.FindByName(null, "DelGlowFrancis"))
		Entities.FindByName(null, "DelGlowFrancis").Kill();
		
		local bawn_outline_temp = FileToString("black_and_white_notifier/bawn_outline.txt");
		if(bawn_outline_temp != null)
		{
			local bawn_outline_temp_int = bawn_outline_temp.tointeger();
			if(bawn_outline_temp_int == 1 || bawn_outline_temp_int == 0)
			{
				::BAWYammy.bawn_outline = bawn_outline_temp_int;
			}
		}
		
		local bawn_color_temp = FileToString("black_and_white_notifier/bawn_color.txt");
		if(bawn_color_temp != null)
		{
			local bawn_color_temp_int = bawn_color_temp.tointeger();
			if(bawn_color_temp_int == 1)
			{
				::BAWYammy.bawn_color = bawn_color_temp_int;
				
				::BAWYammy.bawn_color_R = 255;
			}
			if(bawn_color_temp_int == 2)
			{
				::BAWYammy.bawn_color = bawn_color_temp_int;
				
				::BAWYammy.bawn_color_R = 80;
			}
			if(bawn_color_temp_int == 3)
			{
				::BAWYammy.bawn_color = bawn_color_temp_int;
				
				::BAWYammy.bawn_color_R = 65280;
			}
			if(bawn_color_temp_int == 4)
			{
				::BAWYammy.bawn_color = bawn_color_temp_int;
				
				::BAWYammy.bawn_color_R = 65535;
			}
			if(bawn_color_temp_int == 5)
			{
				::BAWYammy.bawn_color = bawn_color_temp_int;
				
				::BAWYammy.bawn_color_R = 16711680;
			}
			if(bawn_color_temp_int == 6)
			{	
				::BAWYammy.bawn_color = bawn_color_temp_int;
				
				::BAWYammy.bawn_color_R = 16777215;
			}
			if(bawn_color_temp_int == 7)
			{
				::BAWYammy.bawn_color = bawn_color_temp_int;
				
				::BAWYammy.bawn_color_R = 16711935;
			}
		}
		
		local bawn_time_temp = FileToString("black_and_white_notifier/bawn_time.txt");
		if(bawn_time_temp != null)
		{
			local bawn_time_temp_int = bawn_time_temp.tointeger();
			if(bawn_time_temp_int >= 0 && bawn_time_temp_int <= 120)
			{
				::BAWYammy.bawn_time = bawn_time_temp_int;
				::BAWYammy.bawn_time_float = ::BAWYammy.bawn_time.tofloat();
			}
		}
		
		local bawn_chat_temp = FileToString("black_and_white_notifier/bawn_chat.txt");
		if(bawn_chat_temp != null)
		{
			local bawn_chat_temp_int = bawn_chat_temp.tointeger();
			if(bawn_chat_temp_int == 1 || bawn_chat_temp_int == 0)
			{
				::BAWYammy.bawn_chat = bawn_chat_temp_int;
			}
		}
		
		local bawn_outline_flash_temp = FileToString("black_and_white_notifier/bawn_outline_flash.txt");
		if(bawn_outline_flash_temp != null)
		{
			local bawn_outline_flash_temp_int = bawn_outline_flash_temp.tointeger();
			if(bawn_outline_flash_temp_int == 1 || bawn_outline_flash_temp_int == 0)
			{
				::BAWYammy.bawn_outline_flash = bawn_outline_flash_temp_int;
			}
		}
	}
	
	function OnGameEvent_player_transitioned(params)
	{
		local ent = GetPlayerFromUserID(params.userid);
		if(ent != null && ent.IsValid())
		{
			if(ent.IsSurvivor())
			{
				if(::BAWYammy.bawn_outline == 1)
				{
					if(NetProps.GetPropInt(ent, "m_bIsOnThirdStrike") == 1)
					{
						if(NetProps.GetPropInt(ent, "m_Glow.m_iGlowType") != 3)
						{
							NetProps.SetPropInt(ent, "m_Glow.m_iGlowType", 3);
							NetProps.SetPropInt(ent, "m_Glow.m_glowColorOverride", ::BAWYammy.bawn_color_R); // 80(dark red), 255(red), 65280(green), 65535(yellow), 16711680(blue) , 16777215(white)
							
							if(::BAWYammy.bawn_outline_flash == 1)
							{
								NetProps.SetPropInt(ent, "m_Glow.m_bFlashing", 10);
							}
							if(::BAWYammy.bawn_outline_flash == 0)
							{
								NetProps.SetPropInt(ent, "m_Glow.m_bFlashing", 0);
							}
							
							if(::BAWYammy.bawn_time != 0)
							{
								local Chara = ent.GetModelName();
								if(Chara == "models/survivors/survivor_gambler.mdl")
								{
									if (!Entities.FindByName(null, "DelGlowNick")) 
									{
										{SpawnEntityFromTable("logic_timer",{targetname="DelGlowNick",RefireTime = ::BAWYammy.bawn_time_float , OnTimer = "!caller,runscriptcode,DelGlowNick()"});}
										::on <- 1;
										::ent <- null;
										::DelGlowNick <-function()
										{
											if(NetProps.GetPropInt(ent, "m_Glow.m_iGlowType") != 0)
												NetProps.SetPropInt(ent, "m_Glow.m_iGlowType", 0);
											
											if(Entities.FindByName(null, "DelGlowNick"))
												Entities.FindByName(null, "DelGlowNick").Kill();
										}
									}
								}
								
								if(Chara == "models/survivors/survivor_coach.mdl")
								{
									if (!Entities.FindByName(null, "DelGlowCoach")) 
									{
										{SpawnEntityFromTable("logic_timer",{targetname="DelGlowCoach",RefireTime = ::BAWYammy.bawn_time_float , OnTimer = "!caller,runscriptcode,DelGlowCoach()"});}
										::on <- 1;
										::ent <- null;
										::DelGlowCoach <-function()
										{
											if(NetProps.GetPropInt(ent, "m_Glow.m_iGlowType") != 0)
												NetProps.SetPropInt(ent, "m_Glow.m_iGlowType", 0);
											
											if(Entities.FindByName(null, "DelGlowCoach"))
												Entities.FindByName(null, "DelGlowCoach").Kill();
										}
									}
								}
								if(Chara == "models/survivors/survivor_producer.mdl")
								{
									if (!Entities.FindByName(null, "DelGlowRochelle")) 
									{
										{SpawnEntityFromTable("logic_timer",{targetname="DelGlowRochelle",RefireTime = ::BAWYammy.bawn_time_float , OnTimer = "!caller,runscriptcode,DelGlowRochelle()"});}
										::on <- 1;
										::ent <- null;
										::DelGlowRochelle <-function()
										{
											if(NetProps.GetPropInt(ent, "m_Glow.m_iGlowType") != 0)
												NetProps.SetPropInt(ent, "m_Glow.m_iGlowType", 0);
											
											if(Entities.FindByName(null, "DelGlowRochelle"))
												Entities.FindByName(null, "DelGlowRochelle").Kill();
										}
									}
								}
								if(Chara == "models/survivors/survivor_mechanic.mdl")
								{
									if (!Entities.FindByName(null, "DelGlowEllis")) 
									{
										{SpawnEntityFromTable("logic_timer",{targetname="DelGlowEllis",RefireTime = ::BAWYammy.bawn_time_float , OnTimer = "!caller,runscriptcode,DelGlowEllis()"});}
										::on <- 1;
										::ent <- null;
										::DelGlowEllis <-function()
										{
											if(NetProps.GetPropInt(ent, "m_Glow.m_iGlowType") != 0)
												NetProps.SetPropInt(ent, "m_Glow.m_iGlowType", 0);
											
											if(Entities.FindByName(null, "DelGlowEllis"))
												Entities.FindByName(null, "DelGlowEllis").Kill();
										}
									}
								}
							
								if(Chara == "models/survivors/survivor_namvet.mdl")
								{
									if (!Entities.FindByName(null, "DelGlowBill")) 
									{
										{SpawnEntityFromTable("logic_timer",{targetname="DelGlowBill",RefireTime = ::BAWYammy.bawn_time_float , OnTimer = "!caller,runscriptcode,DelGlowBill()"});}
										::on <- 1;
										::ent <- null;
										::DelGlowBill <-function()
										{
											if(NetProps.GetPropInt(ent, "m_Glow.m_iGlowType") != 0)
												NetProps.SetPropInt(ent, "m_Glow.m_iGlowType", 0);
											
											if(Entities.FindByName(null, "DelGlowBill"))
												Entities.FindByName(null, "DelGlowBill").Kill();
										}
									}
								}
								if(Chara == "models/survivors/survivor_teenangst.mdl")
								{
									if (!Entities.FindByName(null, "DelGlowZoey")) 
									{
										{SpawnEntityFromTable("logic_timer",{targetname="DelGlowZoey",RefireTime = ::BAWYammy.bawn_time_float , OnTimer = "!caller,runscriptcode,DelGlowZoey()"});}
										::on <- 1;
										::ent <- null;
										::DelGlowZoey <-function()
										{
											if(NetProps.GetPropInt(ent, "m_Glow.m_iGlowType") != 0)
												NetProps.SetPropInt(ent, "m_Glow.m_iGlowType", 0);
											
											if(Entities.FindByName(null, "DelGlowZoey"))
												Entities.FindByName(null, "DelGlowZoey").Kill();
										}
									}
								}
								if(Chara == "models/survivors/survivor_manager.mdl")
								{
									if (!Entities.FindByName(null, "DelGlowLouis")) 
									{
										{SpawnEntityFromTable("logic_timer",{targetname="DelGlowLouis",RefireTime = ::BAWYammy.bawn_time_float , OnTimer = "!caller,runscriptcode,DelGlowLouis()"});}
										::on <- 1;
										::ent <- null;
										::DelGlowLouis <-function()
										{
											if(NetProps.GetPropInt(ent, "m_Glow.m_iGlowType") != 0)
												NetProps.SetPropInt(ent, "m_Glow.m_iGlowType", 0);
											
											if(Entities.FindByName(null, "DelGlowLouis"))
												Entities.FindByName(null, "DelGlowLouis").Kill();
										}
									}
								}
								if(Chara == "models/survivors/survivor_biker.mdl")
								{
									if (!Entities.FindByName(null, "DelGlowFrancis")) 
									{
										{SpawnEntityFromTable("logic_timer",{targetname="DelGlowFrancis",RefireTime = ::BAWYammy.bawn_time_float , OnTimer = "!caller,runscriptcode,DelGlowFrancis()"});}
										::on <- 1;
										::ent <- null;
										::DelGlowFrancis <-function()
										{
											if(NetProps.GetPropInt(ent, "m_Glow.m_iGlowType") != 0)
												NetProps.SetPropInt(ent, "m_Glow.m_iGlowType", 0);
											
											if(Entities.FindByName(null, "DelGlowFrancis"))
												Entities.FindByName(null, "DelGlowFrancis").Kill();
										}
									}
								}
							}
						}
					}
				}
			}
		}
	}
}

__CollectEventCallbacks(::BAWYam, "OnGameEvent_", "GameEventCallbacks", RegisterScriptGameEventListener);