"Resource/UI/HUD/TeammatePanel.res"
{
	"BackgroundImage"
	{
		"ControlName"	"ImagePanel"
		"fieldName"		"BackgroundImage"
		"xpos"			"-3" //was -2
		"ypos"			"9"
		"wide"			"143" //was 140
		"tall"			"70"
		"zpos"			"-1"
		"visible"		"1"
		"enabled"		"1"
		"scaleImage"	"1"
		"drawColor"		"80 76 82 255"
		"image"			"hud/healthbar_bg_1"
	}

	"Voice"
	{
		"ControlName"	"TeamDisplayVoicePanel"
		"fieldName"		"Voice"
		"xpos"			"26"
		"ypos"			"3"
		"wide"			"16"
		"tall"			"16"
		"visible"		"0"
		"enabled"		"1"
		"zpos"			"3"
		"voice_icon"	"voice_player"
	}

	"Head"
	{
		"ControlName"	"ImagePanel"
		"fieldName"		"Head"
		"xpos"			"3"
		"ypos"			"16"
		"wide"			"35"
		"tall"			"35"
		"visible"		"1"
		"enabled"		"1"
		"scaleImage"	"1"
	}
		
	"Dead"
	{
		"ControlName"	"ImagePanel"
		"fieldName"		"Dead"
		"xpos"			"0"
		"ypos"			"16"
		"wide"			"256"
		"tall"			"128"
		"zpos"			"3"
		"visible"		"0"
		"enabled"		"1"
		"scaleImage"	"1"
		"image"			"hud/overlay_dead"
	}
	
	"Health"
	{
		"ControlName"	"HealthPanel"
		"fieldName"		"Health"
		"xpos"			"40" //was 40 before stretching bg
		"ypos"			"40"
		"wide"			"94" //was 92
		"tall"			"12"
		"visible"		"1"
		"enabled"		"1"
		"zpos"			"1"
		"textAlignment"	"east"
		
		"new_material_style"	"1"		
		"healthbar_image_high"			"vgui/hud/healthbar_withglow_green"
		"healthbar_image_medium"		"vgui/hud/healthbar_withglow_orange"
		"healthbar_image_low"			"vgui/hud/healthbar_withglow_red"
		"healthbar_image_grey"			"vgui/hud/healthbar_withglow_white"
		
		"healthbar_image_high_ticks"	"vgui/hud/healthbar_ticks_withglow_green"
		"healthbar_image_medium_ticks"	"vgui/hud/healthbar_ticks_withglow_orange"
		"healthbar_image_low_ticks"	"vgui/hud/healthbar_ticks_withglow_red"
		"healthbar_image_grey_ticks"	"vgui/hud/healthbar_ticks_withglow_white"		
	}

	"HealthIcon"
	{
		"ControlName"	"Label"
		"fieldName"		"HealthIcon"
		"xpos"			"41" //40 current 41^
		"ypos"			"17" //21 current 18^
		"wide"			"70"
		"tall"			"26"
		"visible"		"1"
		"enabled"		"1"
		"labelText"		","
		"textAlignment"	"west"
		"font"			"L4D_Icons"
		"zpos"			"2"
	}

	"HealthNumber"
	{
		"ControlName"	"Label"
		"fieldName"		"HealthNumber"
		"xpos"			"51" [!$OSX] //51 current 52^
		"xpos"			"55" [$OSX] //51 current 52^
		"ypos"			"18" //21 current 18^ 19^^
		"wide"			"70"
		"tall"			"26"
		"visible"		"1"
		"enabled"		"1"
		"labelText"		"%HealthNumber%"
		"textAlignment"	"west"
		"font"			"HUDHealth"
		"zpos"			"2"
	}

	"Name"
	{
		"ControlName"	"Label"
		"fieldName"		"Name"
		"xpos"			"13"
		"ypos"			"55"
		"wide"			"120"
		"tall"			"12"
		"visible"		"1"
		"enabled"		"1"
		"labelText"		""
		"textAlignment"	"west"
		"font"			"PlayerDisplayName"
		"zpos"			"3"
		"fgcolor_override" "White"
	}
	
	"Status"
	{
		"ControlName"	"Label"
		"fieldName"		"Status"
		"xpos"			"4" //"41"
		"ypos"			"0" //"13"
		"wide"			"70"
		"tall"			"12"
		"visible"		"1" //0
		"enabled"		"1"
		"labelText"		""
		"textAlignment"	"west" //east
		"font"			"PlayerDisplayName"
		"zpos"			"3"
		"fgcolor_override" "White"
	}
	
	"IconForSlot_Grenade"
	{
		"ControlName"	"CIconPanel"
		"fieldName"		"IconForSlot_Grenade"
		"xpos"			"84"
		"ypos"			"23"
		"wide"			"14"
		"tall"			"14"
		"visible"		"0"
		"enabled"		"1"
		"zpos"			"2"
		"scaleImage"	"1"
		"icon"			"icon_equip_pipebomb_small"
	}
	
	"IconForSlot_First_Aid"
	{
		"ControlName"	"CIconPanel"
		"fieldName"		"IconForSlot_First_Aid"
		"xpos"			"98"
		"ypos"			"23"
		"wide"			"14"
		"tall"			"14"
		"visible"		"0"
		"enabled"		"1"
		"zpos"			"2"
		"scaleImage"	"1"
		"icon"			"icon_equip_medkit_small"
	}
	
	"IconForSlot_Pills"
	{
		"ControlName"	"CIconPanel"
		"fieldName"		"IconForSlot_Pills"
		"xpos"			"112"
		"ypos"			"23"
		"wide"			"14"
		"tall"			"14"
		"visible"		"0"
		"enabled"		"1"
		"zpos"			"2"
		"scaleImage"	"1"
		"icon"			"icon_equip_pills_small"
	}
	
}