::rs_introFunc<-
{
	function introSkip(){		
		switch(Director.GetMapName()){
			case "c1m1_hotel":
				EntFire("sound_chopperleave","Kill"); //Specific intro sounds.
				EntFire("rescue_chopper","Kill"); //Specific models of rescue vehicles.
				EntFire("lcs_intro","Kill"); //Remove survivor voices during intro.
				EntFire("fade_intro","Kill"); //Remove entity of fade control.
				EntFire("director","FinishIntro",null,0.1); //Stop survivor animations during intro.
				EntFire("director","ReleaseSurvivorPositions",null,0.1); //Teleport to start points+unfreezing.
				EntFire("point_viewcontrol_survivor","Kill"); //Remove intro cameras.
			break;
			case "c2m1_highway":
				EntFire("lcs_intro","Kill");
				EntFire("fade_intro","Kill");
				EntFire("director","FinishIntro",null,0.1);
				EntFire("director","ReleaseSurvivorPositions",null,0.1);
				EntFire("point_viewcontrol_survivor","Kill");
			break;
			case "c3m1_plankcountry":
				EntFire("lcs_intro","Kill");
				EntFire("fade_intro","Kill");
				EntFire("director","ReleaseSurvivorPositions",null,0.1);
				EntFire("point_viewcontrol_survivor","Kill");
			break;
			case "c4m1_milltown_a":
				EntFire("PugTug","Kill");
				EntFire("@skybox_PugTug","Kill");
				EntFire("lcs_intro","Kill");
				EntFire("fade_intro","Kill");
				EntFire("@director","FinishIntro",null,0.1);
				EntFire("@director","ReleaseSurvivorPositions",null,0.1);
				EntFire("point_viewcontrol_survivor","Kill");
			break;
			case "c5m1_waterfront":
				EntFire("orator","Kill");
				EntFire("tug_boat_intro","Kill");
				EntFire("@skybox_tug_boat_intro","Kill");
				EntFire("fade_intro","Kill");
				EntFire("director","FinishIntro",null,0.1);
				EntFire("director","ReleaseSurvivorPositions",null,0.1);
				EntFire("point_viewcontrol_survivor","Kill");
			break;
			case "c6m1_riverbank":
				/*Prohibit "relay_intro_start" forcing a FireConceptToAny input.
				P.S.: Usually we avoid using such methods,
				but only this time... Made sure,that DirectorOptions loads properly.*/

				EntFire("@director","FinishIntro");
				EntFire("@director","AddOutput","targetname director_temp");
				EntFire("director_temp","AddOutput","targetname @director",0.1);
				EntFire("fade_intro","Kill");
				EntFire("point_viewcontrol_survivor","Kill");
			break;
			case "c7m1_docks":
				EntFire("intro_train_steam1","Kill");
				EntFire("intro_train_steam2","Kill");
				EntFire("intro_train_steam3","Kill");
				EntFire("train","AddOutput","origin 13168.001,2768.000,50.000");
				EntFire("infected_chase","Kill");
				EntFire("infected_spawner","Kill");
				EntFire("fade_outro_1","Kill");
				EntFire("fade_outro_4","Kill");
				EntFire("director","ReleaseSurvivorPositions",null,0.1);
				EntFire("point_viewcontrol_survivor","Kill");
			break;
			case "c8m1_apartment":
				EntFire("lcs_intro_survivors","Kill");
				EntFire("tarp_sound","Kill");
				EntFire("tarp_animated","Kill");
				EntFire("ghostAnim","Kill");
				EntFire("sound_chopper","Kill");
				EntFire("helicopter_speaker","Kill");
				EntFire("helicopter_animated","Kill");
				EntFire("fade_intro","Kill");
				EntFire("director","FinishIntro",null,0.3);
				EntFire("director","ReleaseSurvivorPositions",null,0.3);
				EntFire("camera_intro_airplane","Kill");
			break;
			case "c9m1_alleys":
				EntFire("lcs_intro","Kill");
				EntFire("fade_intro","Kill");
				EntFire("@director","FinishIntro",null,0.1);
				EntFire("@director","ReleaseSurvivorPositions",null,0.1);
				EntFire("point_viewcontrol_survivor","Kill");
			break;
			case "c10m1_caves":
				EntFire("lcs_intro","Kill");
				EntFire("fade_intro","Kill");
				EntFire("director","FinishIntro",null,0.3);
				EntFire("director","ReleaseSurvivorPositions",null,0.3);
				EntFire("point_viewcontrol_survivor","Kill");
			break;
			case "c11m1_greenhouse":
				EntFire("light_hanging03","AddOutput","targetname ");
				EntFire("light_hanging02","AddOutput","targetname ");
				EntFire("light_hanging01","AddOutput","targetname ");
				EntFire("greenhouse_panel02","Kill");
				EntFire("greenhouse_panel01","Kill");
				EntFire("greenhouse_particles","Kill");
				EntFire("sound_airplane_intro","Kill");
				EntFire("airplane_animated_intro","Kill");
				EntFire("lcs_intro_airport_01","Kill");
				EntFire("fade_intro","Kill");
				EntFire("director","FinishIntro",null,0.3);
				EntFire("director","ReleaseSurvivorPositions",null,0.3);
				EntFire("point_viewcontrol_survivor","Kill");
			break;
			case "c12m1_hilltop":
				EntFire("lcs_intro","Kill");
				EntFire("fade_intro","Kill");
				EntFire("director","FinishIntro",null,0.3);
				EntFire("director","ReleaseSurvivorPositions",null,0.3);
				EntFire("point_viewcontrol_survivor","Kill");
			break;
			case "c13m1_alpinecreek":
				EntFire("gamesound","PlaySound");
				EntFire("lcs_intro","Kill");
				EntFire("scene_relay","Kill");
				EntFire("b_Signboard01","Kill");
				EntFire("fade_intro","Kill");
				EntFire("director","FinishIntro",null,0.1);
				EntFire("director","ReleaseSurvivorPositions",null,0.1);
				EntFire("point_viewcontrol_survivor","Kill");
			break;
			default:
				local IntroMap = (Entities.FindByName( null, "lcs_intro" ) || Entities.FindByName( null, "fade_intro" ) || Entities.FindByName( null, "intro_fade" )
					|| Entities.FindByName( null, "intro_lr" ) || Entities.FindByName( null, "intro_relay" ));
				if(IntroMap != null){
					// 最小・安全寄り:
					// Killしない、AddOutputしない、targetname変更しない、class全体走査もしない。
					// 既知のintro targetnameだけを緩く停止し、director解除を複数回投げる。
					::rs_introFunc.stopIntroTargetNames();
					::rs_introFunc.forceFinishIntro();
					
					/*
					::rs_cp.debugPrint("-- INTRO MAP");
					local ent = null;
					while (ent = Entities.FindByName(ent, "relay_intro_setup")){
						if (ent.IsValid())DoEntFire("!self", "Kill", "", 0, null, ent);
					}

					local ent = null;
					while (ent = Entities.FindByName(ent, "relay_intro_start")){
						if (ent.IsValid()){
							DoEntFire("!self", "AddOutput", "OnTrigger camera_intro:Disable::0:-1", 0, null, ent);
							DoEntFire("!self", "AddOutput", "OnTrigger relay_intro_finished:Trigger::1:-1", 0, null, ent);
							DoEntFire("!self", "Trigger", "", 0, null, ent);
						}
					}
					
					local ent = null;
					while (ent = Entities.FindByClassname(ent, "logic_relay")){
						if (ent.IsValid() && ent.GetName().find("intro") != null){
							DoEntFire("!self", "AddOutput", "OnTrigger camera_intro:Disable::0:-1", 0, null, ent);
							DoEntFire("!self", "AddOutput", "OnTrigger relay_intro_finished:Trigger::1:-1", 0, null, ent);
							DoEntFire("!self", "Trigger", "", 0, null, ent);
						}
					}
					
					local ent = null;
					while (ent = Entities.FindByClassname(ent, "info_director")){
						if (ent.IsValid() && ent.GetName().find("intro") != null){
							DoEntFire("!self", "AddOutput", "OnTrigger camera_intro:Disable::0:-1", 0, null, ent);
							DoEntFire("!self", "AddOutput", "OnTrigger relay_intro_finished:Trigger::1:-1", 0, null, ent);
							DoEntFire("!self", "Trigger", "", 0, null, ent);
						}
					}*/
					
					//↓以下イントロが残ってたマップ
					/*
					Outputsは "My Output : Target Entity : Target Input : Parameter : Delay : Refires" の順番
					Inputsは "Source : Output : My Input : Parameter : Delay : Refires" の順番
					*/
					
					/*
					Map1
					
					Classname = "logic_relay"
					Name = "ConvoBegin"
					Outputs = "OnTrigger : director : FireConceptToAny : dkr_m1_motel_intro : 0.00 : -1"
					Inputs = "relay_intro_start_valve : OnTrigger : Trigger : : 1.00 : -1"
					
					Classname = "info_director"
					Name = "director"
					Outputs1 = "OnGameplayStart : relay_intro_start : Trigger :  : 0.00 : 1"
					Outputs2 = "OnScavengeOvertimeStart : AutoInstance1-relay_scvng_overtime_start : Trigger :  : 0.00 : 1" ←関係ないのも入っている
					Inputs1 = "relay_intro_start : OnTrigger : ForceSurvivorPositions : : 0.00 : -1"
					Inputs2 = "relay_intro_start_valve : OnTrigger : ForceSurvivorPositions : : 0.00 : -1"
					Inputs3 = "ConvoBegin : OnTrigger : FireConceptToAny : dkr_m1_motel_intro : 0.00 : -1"
					Inputs4 = "relay_intro_start : OnTrigger : StartIntro : : 1.00 : -1"
					Inputs5 = "relay_intro_finished_valve : OnTrigger : ReleaseSurvivorPositions : : 1.00 : -1"
					Inputs6 = "relay_intro_finished_valve : OnTrigger : FinishIntro : : 1.00 : -1"
					
					Classname = "logic_relay"
					Name = "relay_intro_finished"
					Outputs = "OnTrigger : relay_intro_start_valve : Trigger : : 1.00 : -1"
					Inputs = "relay_intro_survivor_cameras : OnTrigger : Trigger : : 0.00 : -1"
					
					Classname = "logic_relay"
					Name = "relay_intro_survivor_cameras"
					Outputs = "OnTrigger : relay_intro_finished : Trigger : : 0.00 : -1"
					Inputs = "relay_intro_start : OnTrigger : Trigger : : 11.00 : -1"
					
					Classname = "logic_relay"
					Name = "relay_intro_setup"
					Outputs = "OnTrigger : gameinstructor_disable : GenerateGameEvent : : 0.00 : -1"
					Inputs = "relay_intro_start : OnTrigger : Trigger : : 0.00 : -1"
					
					Classname = "logic_relay"
					Name = "relay_intro_start"
					Outputs1 = "OnTrigger : fade_intro : Fade : : 0.00 : -1"
					Outputs2 = "OnTrigger : relay_intro_setup : Trigger : : 0.00 : -1"
					Outputs3 = "OnTrigger : director : ForceSurvivorPositions : : 0.00 : -1"
					Outputs4 = "OnTrigger : director : StartIntro : : 1.00 : -1"
					Outputs5 = "OnTrigger : relay_intro_survivor_cameras : Trigger : : 11.00 : -1"
					Outputs6 = "OnTrigger : fade_intro2 : Fade : : 9.00 : -1"
					Inputs = "director : OnGameplayStart : Trigger : : 0.00 : 1"
					
					Classname = "logic_relay"
					Name = "relay_intro_start_valve"
					Outputs1 = "OnTrigger : director : ForceSurvivorPositions : : 0.00 : -1"
					Outputs2 = "OnTrigger : fade_intro_valve : Fade : : 0.00 : -1"
					Outputs3 = "OnTrigger : relay_intro_start_valve : Trigger : : 0.00 : -1"
					Outputs4 = "OnTrigger : ghostanim_intro2 : SetAnimation : c2m1_intro : 0.00 : -1"
					Outputs5 = "OnTrigger : kill_all_intro_entities : Trigger : : 0.01 : -1"
					Outputs6 = "OnTrigger : ConvoBegin : Trigger : : 1.00 : -1"
					Outputs7 = "OnTrigger : relay_intro_survivor_cameras_valve : Trigger : : 13.00 : -1"
					Inputs = "relay_intro_finished : OnTrigger : Trigger : : 1.00 : -1"
					
					Classname = "logic_relay"
					Name = "relay_intro_setup_valve"
					Outputs1 = "OnTrigger : gameinstructor_disable : GenerateGameEvent : : 0.00 : -1"
					Inputs = "relay_intro_start_valve : OnTrigger : Trigger : : 0.00 : -1"
					*/
					
					/*
					Map2
					
					Classname = "info_director"
					Name = "director"
					Outputs = "OnGameplayStart : relay_intro_start : Trigger : : 0.00 : -1"
					Inputs1 = "logic_auto : OnMapSpawn : BeginScript : : 0.00 : -1"
					Inputs2 = "relay_intro_start : OnTrigger : ForceSurvivorPositions : : 0.00 : -1"
					Inputs3 = "relay_intro_start : OnTrigger : StartIntro : : 0.00 : -1"
					Inputs4 = "panic_alarm : OnTrigger : BeginScript : : 0.00 : 1"
					Inputs5 = "panic_alarm : OnTrigger : PanicEvent : : 0.00 : 1"
					Inputs6 = "relay_intro_finished : OnTrigger : ReleaseSurvivorPositions : : 1.00 : -1"
					Inputs7 = "relay_intro_finished : OnTrigger : FinishIntro : : 1.00 : -1"
					
					Classname = "logic_relay"
					Name = "relay_intro_finished"
					Outputs1 = "OnTrigger : director : ReleaseSurvivorPositions : : 1.00 : -1"
					Outputs2 = "OnTrigger : director : FinishIntro : : 1.00 : -1"
					Inputs1 = "info_gamemode : OnSurvival : Kill : : 0.00 : -1"
					Inputs2 = "relay_intro_survivor_cameras : OnTrigger : Trigger : : 1.00 : -1"
					
					Classname = "logic_relay"
					Name = "relay_intro_start"
					Outputs1 = "OnTrigger : director : ForceSurvivorPositions : : 0.00 : -1"
					Outputs2 = "OnTrigger : fade_intro : Fade : : 0.00 : -1"
					Outputs3 = "OnTrigger : relay_intro_survivor_cameras : Trigger : : 13.00 : -1"
					Inputs1 = "director : OnGameplayStart : Trigger : : 0.00 : -1"
					Inputs2 = "relay_survival : OnTrigger : Kill : : 0.00 : -1"
					*/
				}
			break;
		}
	}

	function stopIntroTargetNames()
	{
		
		local target_list = [
			//"lcs_intro",
			//"lcs_intro_survivors"
			//"lcs_intro_airport_01"
			//
			//"fade_intro"
			//"fade_intro2"
			//"fade_intro_valve"
			//
			//"camera_intro"
			//"camera_intro_airplane"
			"point_viewcontrol_survivor"
			"point_viewcontrol_multiplayer"

			//"intro_lr"
			//"intro_relay"
			//
			//"relay_intro_setup"
			//"relay_intro_setup_valve"
			//"relay_intro_start"
			//"relay_intro_start_valve"
			//"relay_intro_finished"
			//"relay_intro_finished_valve"
			//"relay_intro_survivor_cameras"
			//"relay_intro_survivor_cameras_valve"

			"ConvoBegin"
			"convobegin"
			"convo_begin"
		];

		foreach(target in target_list){
			EntFire(target, "CancelPending");
			EntFire(target, "Disable");

			// カメラ・フェード・会話だけは、それぞれ安全そうな停止Inputを投げる
			EntFire(target, "Cancel");
			EntFire(target, "FadeReverse");
		}
		
		for(local ent; ent = Entities.FindByName(ent, "*intro*"); )
		{
			if(ent.IsValid()){
				local target = ent.GetName();
				if(target.find("intro") != null){
					//ClientPrint(null,3,format("%s", target));
					EntFire(target, "CancelPending");
					EntFire(target, "Disable");
		
					EntFire(target, "Cancel");
					EntFire(target, "FadeReverse");
				}
			}
		}
	}

	function forceFinishIntro()
	{
		// relayやentityを壊さず、director側だけ後解除
		local delay_list = [0.0, 0.1, 0.3, 1.0, 2.0, 5.0, 11.1, 13.1, 14.0];

		foreach(delay in delay_list){
			EntFire("director", "FinishIntro", null, delay);
			EntFire("director", "ReleaseSurvivorPositions", null, delay);

			EntFire("@director", "FinishIntro", null, delay);
			EntFire("@director", "ReleaseSurvivorPositions", null, delay);

			EntFire("point_viewcontrol_survivor", "Disable", null, delay);
			EntFire("camera_intro", "Disable", null, delay);
			EntFire("camera_intro_airplane", "Disable", null, delay);
		}
	}
}

__CollectEventCallbacks(::rs_introFunc, "OnGameEvent_", "GameEventCallbacks", RegisterScriptGameEventListener);