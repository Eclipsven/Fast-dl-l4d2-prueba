easy_item_ping_geeb <-
{

	function highlight(ent1)
	{
        	NetProps.SetPropInt(ent1, "m_Glow.m_iGlowType", 3);
        	NetProps.SetPropInt(ent1, "m_Glow.m_glowColorOverride", 65025);
		NetProps.SetPropInt(ent1, "m_Glow.m_nGlowRange", 2000);
	}

	function lowlight(ent1)
	{
		NetProps.SetPropInt(ent1, "m_Glow.m_iGlowType", 0);
		NetProps.SetPropInt(ent1, "m_Glow.m_glowColorOverride", 0);
		NetProps.SetPropInt(ent1, "m_Glow.m_nGlowRange", 0);
	}

	function OnGameEvent_player_use(event)
	{
		local player = GetPlayerFromUserID(event.userid);
		local origin = player.GetOrigin()
		local ent1 = EntIndexToHScript(event.targetid);
		local ent2 = ent1.GetModelName()
		local ent3 = ent1.GetClassname()
		local ent4 = null;
		while(ent4 = Entities.FindByClassnameWithin(ent4, ent3, origin, 50))
		{
			local isglowing = NetProps.GetPropInt(ent4, "m_Glow.m_glowColorOverride");
			if(isglowing == 65025)
			{
				lowlight(ent4)
			}
		}
		local isglowing = NetProps.GetPropInt(ent1, "m_Glow.m_glowColorOverride");
		if(isglowing == 65025)
		{
			lowlight(ent1)
			return;
		}
	}
	
	validmodels = ["models/props/terror/ammo_stack.mdl", "models/w_models/weapons/w_pistol_B.mdl", "models/props_unique/spawn_apartment/coffeeammo.mdl", "models/w_models/weapons/w_pistol_A.mdl", "models/w_models/weapons/50cal.mdl", "models/w_models/weapons/w_minigun.mdl", "models/w_models/weapons/w_sniper_military.mdl", "models/w_models/weapons/w_rifle_m16a2.mdl", "models/w_models/weapons/w_autoshot_m4super.mdl", "models/w_models/weapons/w_shotgun_spas.mdl", "models/w_models/weapons/w_smg_uzi.mdl", "models/w_models/weapons/w_smg_a.mdl", "models/w_models/weapons/w_smg_mp5.mdl", "models/w_models/weapons/w_shotgun.mdl", "models/w_models/weapons/w_pumpshotgun_A.mdl", "models/w_models/weapons/w_desert_rifle.mdl", "models/w_models/weapons/w_desert_eagle.mdl", "models/w_models/weapons/w_sniper_mini14.mdl", "models/w_models/weapons/w_sniper_scout.mdl", "models/w_models/weapons/w_sniper_awp.mdl", "models/w_models/weapons/w_rifle_sg552.mdl", "models/w_models/weapons/w_rifle_ak47.mdl", "models/w_models/weapons/w_m60.mdl", "models/w_models/weapons/w_grenade_launcher.mdl", "models/w_models/weapons/w_eq_pipebomb.mdl", "models/w_models/weapons/w_eq_molotov.mdl", "models/w_models/weapons/w_eq_bile_flask.mdl", "models/w_models/weapons/w_eq_defibrillator.mdl", "models/w_models/weapons/w_eq_Medkit.mdl", "models/props_interiors/medicalcabinet02.mdl", "models/w_models/weapons/w_eq_adrenaline.mdl", "models/w_models/weapons/w_eq_painpills.mdl", "models/props_junk/gascan001a.mdl", "models/props_junk/explosive_box001.mdl", "models/props_junk/propanecanister001a.mdl", "models/w_models/weapons/w_eq_explosive_ammopack.mdl", "models/props/terror/exploding_ammo.mdl", "models/w_models/weapons/w_eq_incendiary_ammopack.mdl", "models/props/terror/incendiary_ammo.mdl", "models/w_models/Weapons/w_laser_sights.mdl", "models/w_models/weapons/w_knife_t.mdl", "models/weapons/melee/w_machete.mdl", "models/weapons/melee/w_fireaxe.mdl", "models/weapons/melee/w_shovel.mdl", "models/weapons/melee/w_golfclub.mdl", "models/weapons/melee/w_bat.mdl", "models/weapons/melee/w_chainsaw.mdl", "models/weapons/melee/w_cricket_bat.mdl", "models/weapons/melee/w_crowbar.mdl", "models/weapons/melee/w_electric_guitar.mdl", "models/weapons/melee/w_frying_pan.mdl", "models/weapons/melee/w_katana.mdl", "models/weapons/melee/w_tonfa.mdl", "models/weapons/melee/w_pitchfork.mdl", "models/props_equipment/oxygentank01.mdl", "models/w_models/weapons/w_cola.mdl", "models/props_junk/gnome.mdl"]

	function OnGameEvent_entity_shoved(event)
	{
		local player = GetPlayerFromUserID(event.attacker);
		if(!IsPlayerABot(player) && ("entityid" in event))
		{
			local flags = player.GetButtonMask();
			if(flags & (1 << 17))
			{
				local ent1 = EntIndexToHScript(event.entityid);
				local ent2 = ent1.GetModelName()
				if(ent2 == "models/props/terror/ammo_stack.mdl" || ent2 == "models/props_unique/spawn_apartment/coffeeammo.mdl")
				{
					ClientPrint(null, DirectorScript.HUD_PRINTTALK, "\x03" + player.GetPlayerName() + ": Ammo here!")
				}
				if(ent2 == "models/w_models/weapons/w_pistol_B.mdl" || ent2 == "models/w_models/weapons/w_pistol_A.mdl")
				{
					ClientPrint(null, DirectorScript.HUD_PRINTTALK, "\x03" + player.GetPlayerName() + ": Pistol here!")
				}
				if(ent2 == "models/w_models/weapons/50cal.mdl")
				{
					ClientPrint(null, DirectorScript.HUD_PRINTTALK, "\x03" + player.GetPlayerName() + ": Mounted Gun here!")
				}
				if(ent2 == "models/w_models/weapons/w_minigun.mdl")
				{
					ClientPrint(null, DirectorScript.HUD_PRINTTALK, "\x03" + player.GetPlayerName() + ": Minigun here!")
				}
				if(ent2 == "models/w_models/weapons/w_sniper_military.mdl")
				{
					ClientPrint(null, DirectorScript.HUD_PRINTTALK, "\x03" + player.GetPlayerName() + ": Military Sniper here!")
				}
				if(ent2 == "models/w_models/weapons/w_rifle_m16a2.mdl")
				{
					ClientPrint(null, DirectorScript.HUD_PRINTTALK, "\x03" + player.GetPlayerName() + ": Rifle here!")
				}
				if(ent2 == "models/w_models/weapons/w_autoshot_m4super.mdl")
				{
					ClientPrint(null, DirectorScript.HUD_PRINTTALK, "\x03" + player.GetPlayerName() + ": Autoshotgun here!")
				}
				if(ent2 == "models/w_models/weapons/w_shotgun_spas.mdl")
				{
					ClientPrint(null, DirectorScript.HUD_PRINTTALK, "\x03" + player.GetPlayerName() + ": Spas Shotgun here!")
				}
				if(ent2 == "models/w_models/weapons/w_smg_uzi.mdl")
				{
					ClientPrint(null, DirectorScript.HUD_PRINTTALK, "\x03" + player.GetPlayerName() + ": SMG here!")
				}
				if(ent2 == "models/w_models/weapons/w_smg_a.mdl")
				{
					ClientPrint(null, DirectorScript.HUD_PRINTTALK, "\x03" + player.GetPlayerName() + ": Silenced SMG here!")
				}
				if(ent2 == "models/w_models/weapons/w_smg_mp5.mdl")
				{
					ClientPrint(null, DirectorScript.HUD_PRINTTALK, "\x03" + player.GetPlayerName() + ": MP5 here!")
				}
				if(ent2 == "models/w_models/weapons/w_shotgun.mdl")
				{
					ClientPrint(null, DirectorScript.HUD_PRINTTALK, "\x03" + player.GetPlayerName() + ": Pump Shotgun here!")
				}
				if(ent2 == "models/w_models/weapons/w_pumpshotgun_A.mdl")
				{
					ClientPrint(null, DirectorScript.HUD_PRINTTALK, "\x03" + player.GetPlayerName() + ": Chrome Shotgun here!")
				}
				if(ent2 == "models/w_models/weapons/w_desert_rifle.mdl")
				{
					ClientPrint(null, DirectorScript.HUD_PRINTTALK, "\x03" + player.GetPlayerName() + ": Desert Rifle here!")
				}
				if(ent2 == "models/w_models/weapons/w_desert_eagle.mdl")
				{
					ClientPrint(null, DirectorScript.HUD_PRINTTALK, "\x03" + player.GetPlayerName() + ": Magnum here!")
				}
				if(ent2 == "models/w_models/weapons/w_sniper_mini14.mdl")
				{
					ClientPrint(null, DirectorScript.HUD_PRINTTALK, "\x03" + player.GetPlayerName() + ": Hunting Rifle here!")
				}
				if(ent2 == "models/w_models/weapons/w_sniper_scout.mdl")
				{
					ClientPrint(null, DirectorScript.HUD_PRINTTALK, "\x03" + player.GetPlayerName() + ": Scout here!")
				}
				if(ent2 == "models/w_models/weapons/w_sniper_awp.mdl")
				{
					ClientPrint(null, DirectorScript.HUD_PRINTTALK, "\x03" + player.GetPlayerName() + ": AWP here!")
				}
				if(ent2 == "models/w_models/weapons/w_rifle_sg552.mdl")
				{
					ClientPrint(null, DirectorScript.HUD_PRINTTALK, "\x03" + player.GetPlayerName() + ": SG552 here!")
				}
				if(ent2 == "models/w_models/weapons/w_rifle_ak47.mdl")
				{
					ClientPrint(null, DirectorScript.HUD_PRINTTALK, "\x03" + player.GetPlayerName() + ": AK47 here!")
				}
				if(ent2 == "models/w_models/weapons/w_m60.mdl")
				{
					ClientPrint(null, DirectorScript.HUD_PRINTTALK, "\x03" + player.GetPlayerName() + ": M60 here!")
				}
				if(ent2 == "models/w_models/weapons/w_grenade_launcher.mdl")
				{
					ClientPrint(null, DirectorScript.HUD_PRINTTALK, "\x03" + player.GetPlayerName() + ": Grenade Launcher here!")
				}
				if(ent2 == "models/w_models/weapons/w_eq_pipebomb.mdl")
				{
					ClientPrint(null, DirectorScript.HUD_PRINTTALK, "\x03" + player.GetPlayerName() + ": Pipe Bomb here!")
				}
				if(ent2 == "models/w_models/weapons/w_eq_molotov.mdl")
				{
					ClientPrint(null, DirectorScript.HUD_PRINTTALK, "\x03" + player.GetPlayerName() + ": Molotov here!")
				}
				if(ent2 == "models/w_models/weapons/w_eq_bile_flask.mdl")
				{
					ClientPrint(null, DirectorScript.HUD_PRINTTALK, "\x03" + player.GetPlayerName() + ": Bile Bomb here!")
				}
				if(ent2 == "models/w_models/weapons/w_eq_defibrillator.mdl")
				{
					ClientPrint(null, DirectorScript.HUD_PRINTTALK, "\x03" + player.GetPlayerName() + ": Defibrillator here!")
				}
				if(ent2 == "models/w_models/weapons/w_eq_Medkit.mdl")
				{
					ClientPrint(null, DirectorScript.HUD_PRINTTALK, "\x03" + player.GetPlayerName() + ": Medkit here!")
				}	
				if(ent2 == "models/props_interiors/medicalcabinet02.mdl")
				{
					ClientPrint(null, DirectorScript.HUD_PRINTTALK, "\x03" + player.GetPlayerName() + ": First Aid Cabinet here!")
				}
				if(ent2 == "models/w_models/weapons/w_eq_adrenaline.mdl")
				{
					ClientPrint(null, DirectorScript.HUD_PRINTTALK, "\x03" + player.GetPlayerName() + ": Adrenaline here!")
				}
				if(ent2 == "models/w_models/weapons/w_eq_painpills.mdl")
				{
					ClientPrint(null, DirectorScript.HUD_PRINTTALK, "\x03" + player.GetPlayerName() + ": Pills here!")
				}
				if(ent2 == "models/props_junk/gascan001a.mdl")
				{
					ClientPrint(null, DirectorScript.HUD_PRINTTALK, "\x03" + player.GetPlayerName() + ": Gas Can here!")
				}
				if(ent2 == "models/props_junk/explosive_box001.mdl")
				{
					ClientPrint(null, DirectorScript.HUD_PRINTTALK, "\x03" + player.GetPlayerName() + ": Fireworks here!")
				}
				if(ent2 == "models/props_junk/propanecanister001a.mdl")
				{
					ClientPrint(null, DirectorScript.HUD_PRINTTALK, "\x03" + player.GetPlayerName() + ": Propane Tank here!")
				}
				if(ent2 == "models/w_models/weapons/w_eq_explosive_ammopack.mdl")
				{
					ClientPrint(null, DirectorScript.HUD_PRINTTALK, "\x03" + player.GetPlayerName() + ": Explosive Ammo here!")
				}
				if(ent2 == "models/props/terror/exploding_ammo.mdl")
				{
					ClientPrint(null, DirectorScript.HUD_PRINTTALK, "\x03" + player.GetPlayerName() + ": Grab some Explosive Ammo!")
				}
				if(ent2 == "models/w_models/weapons/w_eq_incendiary_ammopack.mdl")
				{
					ClientPrint(null, DirectorScript.HUD_PRINTTALK, "\x03" + player.GetPlayerName() + ": Incendiary Ammo here!")
				}
				if(ent2 == "models/props/terror/incendiary_ammo.mdl")
				{
					ClientPrint(null, DirectorScript.HUD_PRINTTALK, "\x03" + player.GetPlayerName() + ": Grab some Incendiary Ammo!")
				}
				if(ent2 == "models/w_models/Weapons/w_laser_sights.mdl")
				{
					ClientPrint(null, DirectorScript.HUD_PRINTTALK, "\x03" + player.GetPlayerName() + ": Laser Sights here!")
				}
				if(ent2 == "models/w_models/weapons/w_knife_t.mdl")
				{
					ClientPrint(null, DirectorScript.HUD_PRINTTALK, "\x03" + player.GetPlayerName() + ": Knife here!")
				}
				if(ent2 == "models/weapons/melee/w_machete.mdl")
				{
					ClientPrint(null, DirectorScript.HUD_PRINTTALK, "\x03" + player.GetPlayerName() + ": Machete here!")
				}
				if(ent2 == "models/weapons/melee/w_fireaxe.mdl")
				{
					ClientPrint(null, DirectorScript.HUD_PRINTTALK, "\x03" + player.GetPlayerName() + ": Fireaxe here!")
				}
				if(ent2 == "models/weapons/melee/w_shovel.mdl")
				{
					ClientPrint(null, DirectorScript.HUD_PRINTTALK, "\x03" + player.GetPlayerName() + ": Shovel here!")
				}
				if(ent2 == "models/weapons/melee/w_golfclub.mdl")
				{
					ClientPrint(null, DirectorScript.HUD_PRINTTALK, "\x03" + player.GetPlayerName() + ": Golf Club here!")
				}
				if(ent2 == "models/weapons/melee/w_bat.mdl")
				{
					ClientPrint(null, DirectorScript.HUD_PRINTTALK, "\x03" + player.GetPlayerName() + ": Baseball Bat here!")
				}
				if(ent2 == "models/weapons/melee/w_chainsaw.mdl")
				{
					ClientPrint(null, DirectorScript.HUD_PRINTTALK, "\x03" + player.GetPlayerName() + ": Chainsaw here!")
				}
				if(ent2 == "models/weapons/melee/w_cricket_bat.mdl")
				{
					ClientPrint(null, DirectorScript.HUD_PRINTTALK, "\x03" + player.GetPlayerName() + ": Cricket Bat here!")
				}
				if(ent2 == "models/weapons/melee/w_crowbar.mdl")
				{
					ClientPrint(null, DirectorScript.HUD_PRINTTALK, "\x03" + player.GetPlayerName() + ": Crowbar here!")
				}
				if(ent2 == "models/weapons/melee/w_electric_guitar.mdl")
				{
					ClientPrint(null, DirectorScript.HUD_PRINTTALK, "\x03" + player.GetPlayerName() + ": Guitar here!")
				}
				if(ent2 == "models/weapons/melee/w_frying_pan.mdl")
				{
					ClientPrint(null, DirectorScript.HUD_PRINTTALK, "\x03" + player.GetPlayerName() + ": Frying Pan here!")
				}	
				if(ent2 == "models/weapons/melee/w_katana.mdl")
				{
					ClientPrint(null, DirectorScript.HUD_PRINTTALK, "\x03" + player.GetPlayerName() + ": Katana here!")
				}
				if(ent2 == "models/weapons/melee/w_tonfa.mdl")
				{
					ClientPrint(null, DirectorScript.HUD_PRINTTALK, "\x03" + player.GetPlayerName() + ": Nightstick here!")
				}
				if(ent2 == "models/weapons/melee/w_pitchfork.mdl")
				{
					ClientPrint(null, DirectorScript.HUD_PRINTTALK, "\x03" + player.GetPlayerName() + ": Pitchfork here!")
				}
				if(ent2 == "models/props_equipment/oxygentank01.mdl")
				{
					ClientPrint(null, DirectorScript.HUD_PRINTTALK, "\x03" + player.GetPlayerName() + ": Oxygen Tank here!")
				}
				if(ent2 == "models/w_models/weapons/w_cola.mdl")
				{
					ClientPrint(null, DirectorScript.HUD_PRINTTALK, "\x03" + player.GetPlayerName() + ": Cola here!")
				}
				if(ent2 == "models/props_junk/gnome.mdl")
				{
					ClientPrint(null, DirectorScript.HUD_PRINTTALK, "\x03" + player.GetPlayerName() + ": Gnome here!")
				}
				if(validmodels.find(ent2) == null)
				{
					return null;
				}
				local isglowing = NetProps.GetPropInt(ent1, "m_Glow.m_glowColorOverride");
				if(isglowing != 65025)
				{
					highlight(ent1)
					return null;
				}
				lowlight(ent1)
			}
		}
	}
}

__CollectEventCallbacks(easy_item_ping_geeb, "OnGameEvent_", "GameEventCallbacks", RegisterScriptGameEventListener);