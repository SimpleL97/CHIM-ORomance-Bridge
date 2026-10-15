Scriptname COR Hidden
{CHIM ORomance Bridge by SaurOff - the entry point CHIM looks for.
 For a command "ExtCmdCOR_<Action>" CHIM's game plugin first calls the global
 COR.DispatchExternalCommand(npc, command, parameter); only without it does it fall
 back to its own mod event, which crashes CHIM's command queue after the first action
 of a session (found with the CHIM OStim Bridge). Forwarded to COR_Bridge as the mod
 event "COR_Command".}

bool Function DispatchExternalCommand(string asNpcName, string asCommand, string asParameter) Global
	int handle = ModEvent.Create("COR_Command")
	If !handle
		Return False
	EndIf
	ModEvent.PushString(handle, asNpcName)
	ModEvent.PushString(handle, asCommand)
	ModEvent.PushString(handle, asParameter)
	ModEvent.Send(handle)
	Return True
EndFunction
