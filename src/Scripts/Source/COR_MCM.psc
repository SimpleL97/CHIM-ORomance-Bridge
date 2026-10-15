Scriptname COR_MCM extends MCM_ConfigBase
{CHIM ORomance Bridge by SaurOff - the MCM (MCM Helper reads MCM/Config/CHIMORomanceBridge/config.json).
 Any change is pushed to the CHIM server on the next COR_Events poll.}

Event OnConfigInit()
	Push()
EndEvent

Event OnSettingChange(string a_ID)
	Push()
EndEvent

Event OnGameReload()
	parent.OnGameReload()
	Push()
EndEvent

Function Push()
	COR_Events ev = Game.GetFormFromFile(0x000801, "CHIMORomanceBridge.esp") as COR_Events
	If ev
		ev.ConfigChanged()
	EndIf
EndFunction
