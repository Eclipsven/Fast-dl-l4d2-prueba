printl("[VScript] Melee Shove during Smoker Pull Fix v1.21");

::sm_melee_shove_fix <-
{
	function OnGameEvent_choke_start(params){
		local surv = GetPlayerFromUserID(params.victim);
		
		if(IsPlayerABot(surv))
			return;
		
		surv.ValidateScriptScope();
		local SurvScope = surv.GetScriptScope();
		SurvScope.SmIsChokeStart <- true;
	}
	
	function OnGameEvent_tongue_grab(params){
		local smoker = GetPlayerFromUserID(params.userid);
		local surv = GetPlayerFromUserID(params.victim);
		
		if(IsPlayerABot(surv))
			return;
	
		surv.ValidateScriptScope();
		local SurvScope = surv.GetScriptScope();
		if("SmShoveThinkDummy" in SurvScope)
			return;

		SurvScope.SmIsChokeStart <- false;

		local dummy = SpawnEntityFromTable("logic_script", {});
		dummy.ValidateScriptScope();
		SurvScope.SmShoveThinkDummy <- dummy;
		
		dummy.GetScriptScope().SmShoveCheckThink <- function()
		{
			if(surv == null || !surv.IsValid()){
				delete SurvScope.SmShoveThinkDummy;
				self.Kill();
				return 1;
			}
			
			if(surv.IsIncapacitated() || surv.IsHangingFromLedge() || surv.IsDying()){
				delete SurvScope.SmShoveThinkDummy;
				self.Kill();
				return 1;
			}
			
			if(smoker == null || !smoker.IsValid() || NetProps.GetPropEntity(surv, "m_tongueOwner") == null){
				delete SurvScope.SmShoveThinkDummy;
				self.Kill();
				return 1;
			}
			
			if(SurvScope.SmIsChokeStart){
				delete SurvScope.SmShoveThinkDummy;
				self.Kill();
				return 1;
			}
			
			local survAct = surv.GetSequenceActivityName(surv.GetSequence());
			if(survAct == "ACT_TERROR_DRAGGING_FROM_TONGUE"){
				delete SurvScope.SmShoveThinkDummy;
				self.Kill();
				return 1;
			}
			
			//ClientPrint(null,3,format("surv act: %s, seq %d", surv.GetSequenceActivityName(surv.GetSequence()), surv.GetSequence()));
            
			// GetButtonMask() は押しっぱなし中だけ判定される
			if((NetProps.GetPropInt(surv, "m_afButtonPressed") & (1 << 11)) > 0)
			{
				
				local activeWeapon = surv.GetActiveWeapon();
				if(activeWeapon && activeWeapon.GetClassname() == "weapon_melee"){
					
					local act = activeWeapon.GetSequenceActivityName(activeWeapon.GetSequence());
					//ClientPrint(null,3,format("weapon act: %s, seq %d", act, activeWeapon.GetSequence()));
	
					if(act == "ACT_VM_IDLE" || act == "ACT_VM_IDLE_TO_LOWERED_IDLE"){
	
						local time = Time();
						local melee_next = NetProps.GetPropFloat(activeWeapon, "m_flNextSecondaryAttack");
						if(time >= melee_next){
	
							local viewModel = NetProps.GetPropEntity(surv, "m_hViewModel");
							
							// ↓3rd Person アニメーション
							NetProps.SetPropIntArray(surv, "m_NetGestureSequence", surv.LookupSequence("ACT_SHOOT_SECONDARY_GUITAR"), 6); //パターンが違う, GUITAR, BAT, AXE, FLYINGPAN
							NetProps.SetPropIntArray(surv, "m_NetGestureActivity", surv.LookupActivity("ACT_SHOOT_SECONDARY_GUITAR"), 6);
							NetProps.SetPropFloatArray(surv, "m_NetGestureStartTime", Time(), 6);
							
							
							// ↓FOV アニメーション
							local lu_seq = activeWeapon.LookupSequence("ACT_VM_SECONDARYATTACK");
							NetProps.SetPropIntArray(activeWeapon, "m_NetGestureSequence", lu_seq, 5);
							NetProps.SetPropIntArray(activeWeapon, "m_NetGestureActivity", activeWeapon.LookupActivity("ACT_VM_SECONDARYATTACK"), 5);
							NetProps.SetPropFloatArray(activeWeapon, "m_NetGestureStartTime", 0, 5);
							NetProps.SetPropInt( viewModel, "m_nLayerSequence", lu_seq );
							NetProps.SetPropInt( viewModel, "m_nLayer", 0 );
							
							NetProps.SetPropFloat( viewModel, "m_flLayerStartTime", time );
							local duration = viewModel.GetSequenceDuration( lu_seq );
							NetProps.SetPropFloat( activeWeapon, "m_helpingHandSuppressionTimer.m_duration", 1 );
							NetProps.SetPropFloat( activeWeapon, "m_helpingHandSuppressionTimer.m_timestamp", time + 1 );
							NetProps.SetPropInt( activeWeapon, "m_helpingHandState", 0 );
							EmitSoundOn("Weapon.Swing", surv);
	
						
							local surv_pos = surv.GetOrigin();
							local smoker_pos = smoker.GetOrigin();
							local dist = (smoker_pos - surv_pos).Length();
							//ClientPrint(null,3,format("dist %.1f", dist));
							if (dist <= 120.0){
								if(::sm_melee_shove_fix.viewCheck(surv, smoker))
								{
									smoker.Stagger(surv.GetOrigin());
									if(dist > 115.0) //音が出ないことがある
										EmitSoundOn("Weapon.HitInfected", surv);
									
									//ClientPrint(null,3,"HIT");
								}
								else{  //Smokerに視点が合っていない状態で、高速で視点を向けた時に、入らなくなる
									DoEntFire("!self", "RunScriptCode", "::sm_melee_shove_fix.angleNormRetry(activator, caller)", 0.1, surv, smoker);
								}
							}
	
							local interval = Convars.GetFloat("z_gun_swing_interval");
							if(interval < -1.0)
								interval = -1.0;
							return interval;
						}
					}
				}
			}
			return -1;
		}
		AddThinkToEnt(dummy, "SmShoveCheckThink");
	}
	
	function angleNormRetry(surv, smoker)
	{
		if(surv == null || !surv.IsValid() || smoker == null || !smoker.IsValid())
			return;
		
		if(surv.GetScriptScope().SmIsChokeStart)
			return;
	
		local survAct = surv.GetSequenceActivityName(surv.GetSequence());
		if(survAct == "ACT_TERROR_DRAGGING_FROM_TONGUE")
			return;
		
		local smoker_pos = smoker.GetOrigin();
		if(::sm_melee_shove_fix.viewCheck(surv, smoker))
		{
			local surv_pos = surv.GetOrigin();
			smoker.Stagger(surv_pos);
			
			local dist = (smoker_pos - surv_pos).Length();
			EmitSoundOn("Weapon.HitInfected", surv);
			
			//ClientPrint(null,3,"HIT 2");
		}
	}
	
	function viewCheck(surv, target){
		local startpos = surv.EyePosition();
		local target_pos = target.GetOrigin() + Vector(0, 0, 30);
		local targetNorm = Vector(target_pos.x, target_pos.y, target_pos.z);
		targetNorm.x -= startpos.x;	targetNorm.y -= startpos.y;	targetNorm.z -= startpos.z;
		targetNorm.x = targetNorm.x/targetNorm.Norm();
		targetNorm.y = targetNorm.y/targetNorm.Norm();
		targetNorm.z = targetNorm.z/targetNorm.Norm();

		local viewerAng = surv.EyeAngles().Forward();
		local tolerance = 180/PI*acos(viewerAng.Dot(targetNorm));
		//ClientPrint(null,3,format("%.2f", tolerance));
		
		return (180/PI*acos(viewerAng.Dot(targetNorm)) < 50);
	}
}

__CollectEventCallbacks(::sm_melee_shove_fix, "OnGameEvent_", "GameEventCallbacks", RegisterScriptGameEventListener);