Scriptname COR_Bridge extends Quest
{CHIM ORomance Bridge by SaurOff - the AI's actions, done through ORomance Plus.
 CHIM hands them over through COR.DispatchExternalCommand, forwarded as the mod event
 "COR_Command" (npc name, command, parameter); CHIM's fallback event
 "CHIM_CommandReceived" is heard too. Parameters come from the server plugin as
 "<agent>~<item>" ("-" for an empty field). Every outcome is reported back to CHIM as
 a "funcret", so the agent knows what really happened.}

string LastCommandNpc = ""
string LastCommandKey = ""
float LastCommandTime = -100.0

; ---------------------------------------------------------------- registration

Event OnInit()
	Hook()
	RegisterForSingleUpdate(15.0)
EndEvent

Event OnUpdate()
	; CHIM's SKSE plugin can finish loading after this quest starts
	Hook()
EndEvent

; COR_Events calls this on every game load too, so the registrations reach existing saves
Function Hook()
	RegisterForModEvent("COR_Command", "OnChimCommand")          ; from COR.DispatchExternalCommand
	RegisterForModEvent("CHIM_CommandReceived", "OnChimCommand") ; CHIM's fallback path
EndFunction

; ---------------------------------------------------------------- entry point

Event OnChimCommand(String npcname, String command, String parameter)
	If StringUtil.Find(command, "ExtCmdCOR_") != 0
		Return
	EndIf
	; the same command can come in both ways; act on it once. Real time restarts with
	; the game, so a time from before a restart (now < LastCommandTime) never matches.
	float now = Utility.GetCurrentRealTime()
	String cmdKey = command + "@" + parameter
	If cmdKey == LastCommandKey && now >= LastCommandTime && now - LastCommandTime < 5.0
		Return
	EndIf
	LastCommandKey = cmdKey
	LastCommandTime = now
	LastCommandNpc = npcname
	COR_Config.Log("command " + command + " from " + npcname + ": " + parameter)
	If !COR_Config.B("bEnabled:General")
		Report(command, parameter, "cannot: the CHIM ORomance Bridge is turned off in its MCM")
		Return
	EndIf
	Actor npc = ResolveAgent(parameter)
	If !npc
		Report(command, parameter, "cannot: the AI agent could not be identified in the game")
		Return
	EndIf
	string item = ArgOf(parameter, 1)
	If command == "ExtCmdCOR_Affection"
		If !COR_Config.B("bAffection:Love")
			Report(command, parameter, "nothing to do: feelings are not passed to ORomance (MCM)")
			Return
		EndIf
		Report(command, parameter, COR_Romance.AddAffection(npc, Kind(item, "compliment")))
	ElseIf command == "ExtCmdCOR_Hurt"
		If !COR_Config.B("bAffection:Love")
			Report(command, parameter, "nothing to do: feelings are not passed to ORomance (MCM)")
			Return
		EndIf
		Report(command, parameter, COR_Romance.AddHurt(npc, Kind(item, "insult")))
	ElseIf command == "ExtCmdCOR_Partner"
		WaitUntilSilent(npc)
		Report(command, parameter, COR_Romance.BecomePartner(npc))
	ElseIf command == "ExtCmdCOR_Marry"
		If npc.IsInCombat() || Game.GetPlayer().IsInCombat()
			Report(command, parameter, "refuses: there is a fight going on")
			Return
		EndIf
		WaitUntilSilent(npc)
		Report(command, parameter, COR_Romance.Marry(npc))
	ElseIf command == "ExtCmdCOR_Duty"
		If !COR_Romance.IsSpouse(npc)
			Report(command, parameter, "cannot: only a spouse shares the household duties")
			Return
		EndIf
		If item == ""
			Report(command, parameter, "nothing to do: no duty was named")
			Return
		EndIf
		Report(command, parameter, npc.GetDisplayName() + " takes on the household duty: " + item)
	ElseIf command == "ExtCmdCOR_Meal"
		WaitUntilSilent(npc)
		Report(command, parameter, COR_Romance.Meal(npc))
	EndIf
EndEvent

; the kinds the server allows; anything else counts as the default
string Function Kind(string item, string fallback)
	string[] kinds = new string[8]
	kinds[0] = "compliment"
	kinds[1] = "gift"
	kinds[2] = "kindness"
	kinds[3] = "kiss"
	kinds[4] = "love"
	kinds[5] = "insult"
	kinds[6] = "cruelty"
	kinds[7] = "cheating"
	int i = 0
	While i < kinds.Length
		If StringUtil.Find(item, kinds[i]) > -1
			Return kinds[i]
		EndIf
		i += 1
	EndWhile
	Return fallback
EndFunction

; waits (at most about half a minute) until the agent has finished speaking, so what
; ORomance makes them say does not cut into their own line
Function WaitUntilSilent(Actor npc)
	string n = npc.GetDisplayName()
	float t = 0.0
	While t < 2.0 && AIAgentFunctions.isActorTalking(n) == 0
		Utility.Wait(0.25)
		t += 0.25
	EndWhile
	t = 0.0
	While t < 30.0 && AIAgentFunctions.isActorTalking(n) != 0
		Utility.Wait(0.25)
		t += 0.25
	EndWhile
	Utility.Wait(0.3)
EndFunction

; ---------------------------------------------------------------- helpers

String Function ArgOf(String parameter, Int index)
	String[] parts = StringUtil.Split(parameter, "~")
	If index < 0 || index >= parts.Length
		Return ""
	EndIf
	String v = COR_Config.Trim(parts[index])
	If v == "-" ; the server writes "-" for an empty field so Split never drops it
		Return ""
	EndIf
	Return v
EndFunction

Actor Function ResolveAgent(String parameter)
	String name = ArgOf(parameter, 0)
	If name == ""
		name = LastCommandNpc
	EndIf
	Actor a = None
	If name != ""
		a = AIAgentFunctions.getAgentByName(name)
	EndIf
	If !a
		a = AIAgentFunctions.getClosestAgent()
	EndIf
	Return a
EndFunction

; Reported the way CHIM's own actions report: logMessageForActor with "funcret" and the
; agent's name. An unaddressed report left CHIM's command open and broke its queue.
Function Report(String command, String parameter, String result)
	COR_Config.Note(command + " -> " + result)
	String npc = ArgOf(parameter, 0)
	If npc == ""
		npc = LastCommandNpc
	EndIf
	AIAgentFunctions.logMessageForActor("command@" + command + "@" + parameter + "@" + result, "funcret", npc)
EndFunction
