Scriptname COR_Events extends Quest
{CHIM ORomance Bridge by SaurOff - what the AI agents hear about.
 Comment-worthy events (LLM):
   cor_married    someone just got engaged to or married the player
   cor_wives      two or more of the player's spouses are together: one starts talking
                  to another (household, duties, their husband, children) - MCM chance
   cor_pregnant   Fertility Mode says a spouse, partner or woman in love with the player
                  is pregnant now (MCM: news of pregnancies and births)
   cor_birth      ... or has given birth
 Silent bookkeeping (cor_state, never reaches the LLM):
   config|<json>   the MCM settings the server needs
   people|<json>   everyone near the player who matters to ORomance: spouse, partner,
                   ORomance like / love / dislike, Fertility Mode state, gender
   intimate|A,B    a scene of the player with these spouses or partners just ended
   married|Name    a marriage through this mod
   engaged|Name    an engagement (the first spouse: the wedding at the Temple of Mara follows)
 Also tells Fertility Mode about vaginal climaxes in OStim Standalone scenes.}

bool ready = False
bool configSent = False
int polls = 0
string lastPeople = ""
float lastWivesMsg = -1000.0
float lastRealTime = 0.0

float Property PollSeconds = 5.0 AutoReadOnly Hidden

; ---------------------------------------------------------------- startup

Event OnInit()
	ready = True
	Hook()
	RegisterForSingleUpdate(PollSeconds)
EndEvent

Function Hook()
	RegisterForModEvent("ostim_actor_orgasm", "OnActorOrgasm")
	RegisterForModEvent("ostim_thread_end", "OnSceneEnd")
	COR_Bridge bridge = Game.GetFormFromFile(0x000800, "CHIMORomanceBridge.esp") as COR_Bridge
	If bridge
		bridge.Hook()
	EndIf
EndFunction

; called by COR_MCM when a setting changes, the menu is first built, or a save loads
Function ConfigChanged()
	configSent = False
	lastPeople = ""
	Hook() ; every game load: mod event registrations added by an update reach existing saves
	; real time restarts with the game: a cooldown saved in an earlier session would
	; otherwise hold the next message back until the clock caught up
	float now = Utility.GetCurrentRealTime()
	If lastWivesMsg > now
		lastWivesMsg = -1000.0
	EndIf
	; a smaller real time than last time means a new game launch: a fresh log file
	; (loading saves within one launch keeps it)
	If now < lastRealTime || lastRealTime == 0.0
		COR_Config.NewLog()
	EndIf
	lastRealTime = now
	COR_Config.Log("loaded; settings sent to CHIM on the next poll")
EndFunction

; ---------------------------------------------------------------- polling

Event OnUpdate()
	polls += 1
	lastRealTime = Utility.GetCurrentRealTime()
	If polls == 1 || polls % 100 == 0
		Hook()
	EndIf
	If COR_Config.B("bEnabled:General")
		If !configSent
			SendConfig()
			configSent = True
		EndIf
		If polls % 6 == 1
			SendPeople()
		EndIf
		If polls % 6 == 4
			COR_Romance.RepairWedding() ; an engagement the Temple of Mara never heard of
		EndIf
		If polls % 12 == 6
			WivesTalk()
		EndIf
	EndIf
	RegisterForSingleUpdate(PollSeconds)
EndEvent

; Everyone near the player who matters here, read straight from ORomance's own storage
; (StorageUtil keys of ORomanceScript) so that nothing is written for NPCs it never met.
; Sent only when something changed.
Function SendPeople()
	Actor p = Game.GetPlayer()
	Actor[] around = MiscUtil.ScanCellNPCs(p, 4000.0)
	Faction married = COR_Config.PlayerMarriedFaction()
	Faction fertility = None
	If COR_Config.B("bFertility:Children")
		fertility = COR_Config.FertilityFaction()
	EndIf
	float now = Utility.GetCurrentGameTime()
	; ORomance's odds (MCM): would it accept a couple / a marriage right now? So the agent
	; knows beforehand instead of saying yes and then being turned down by ORomance
	ORomanceScript main = None
	If COR_Config.B("bOdds:General")
		main = COR_Romance.Main()
	EndIf
	string j = ""
	int i = 0
	While i < around.Length
		Actor a = around[i]
		If a && a != p && !a.IsDead() && !a.IsChild()
			string name = COR_Config.Clean(a.GetDisplayName())
			bool spouse = a.IsInFaction(married)
			bool partner = StorageUtil.GetIntValue(a, "or_k_part", -1) == 1
			bool seeded = StorageUtil.GetIntValue(a, "or_k_seeded", -1) == 1
			bool wants = COR_Config.InList("sWantChildren:Children", name)
			float like = 0.0
			float love = 0.0
			float dislike = 0.0
			If seeded
				like = Faded(a, "or_k_li", "or_k_li_last", now)
				love = StorageUtil.GetFloatValue(a, "or_k_love", 0.0)
				dislike = Faded(a, "or_k_di", "or_k_di_last", now)
			EndIf
			If spouse || partner || wants || love >= 1.0 || like >= 1.0 || dislike >= 1.0
				If j != ""
					j += ","
				EndIf
				j += "\"" + name + "\":{\"g\":" + a.GetActorBase().GetSex()
				j += ",\"s\":" + COR_Config.Bit(spouse) + ",\"pt\":" + COR_Config.Bit(partner)
				j += ",\"li\":" + (like as int) + ",\"lo\":" + (love as int) + ",\"di\":" + (dislike as int)
				If main && seeded && !spouse
					j += ",\"ao\":" + COR_Config.Bit(partner || main.TryAskOut(a))
					j += ",\"mo\":" + COR_Config.Bit(main.TryPropose(a))
				EndIf
				If fertility && a.IsInFaction(fertility)
					int fm = a.GetFactionRank(fertility)
					j += ",\"fm\":" + fm
					PregnancyNews(a, name, fm)
				EndIf
				j += "}"
			EndIf
		EndIf
		i += 1
	EndWhile
	j = "{\"pg\":" + p.GetActorBase().GetSex() + ",\"p\":{" + j + "}}"
	If j != lastPeople
		lastPeople = j
		SendState("people|" + j)
	EndIf
EndFunction

; Fertility Mode's state changed from not pregnant to pregnant (0..127), or from pregnant to
; recovering after a birth (-85 and below): the AI agents around hear of it. The last state
; seen is kept per woman, so nothing is announced the first time she is seen.
Function PregnancyNews(Actor a, string name, int fm)
	int before = StorageUtil.GetIntValue(a, "COR_FM", -999)
	If before == fm
		Return
	EndIf
	StorageUtil.SetIntValue(a, "COR_FM", fm)
	If before == -999 || !COR_Config.B("bNews:Children")
		Return
	EndIf
	If before < 0 && before > -85 && fm >= 0
		COR_Config.Note(name + " is pregnant")
		AIAgentFunctions.requestMessage("(" + name + " has found out that she is pregnant)", "cor_pregnant")
	ElseIf before >= 0 && fm <= -85
		COR_Config.Note(name + " has given birth")
		AIAgentFunctions.requestMessage("(" + name + " has given birth to a child)", "cor_birth")
	EndIf
EndFunction

; ORomance lets like and dislike fade by 3 a game day from their last access
float Function Faded(Actor a, string valueKey, string lastKey, float now)
	float v = StorageUtil.GetFloatValue(a, valueKey, 0.0)
	float last = StorageUtil.GetFloatValue(a, lastKey, now)
	v -= (now - last) * 3.0
	If v < 0.0
		v = 0.0
	EndIf
	Return v
EndFunction

; Two or more spouses together, nothing else going on: now and then one of them starts
; talking to another. CHIM picks who speaks; the prompt (cor_wives) says what about.
Function WivesTalk()
	If !COR_Config.B("bWivesTalk:Spouses")
		Return
	EndIf
	Actor p = Game.GetPlayer()
	If p.IsInCombat() || InAnyScene(p)
		Return
	EndIf
	float now = Utility.GetCurrentRealTime()
	float gap = COR_Config.I("iWivesMinutes:Spouses") * 60.0
	If gap <= 0.0
		gap = 1200.0
	EndIf
	If now >= lastWivesMsg && now - lastWivesMsg < gap
		Return
	EndIf
	Faction married = COR_Config.PlayerMarriedFaction()
	Actor[] around = MiscUtil.ScanCellNPCs(p, 2000.0)
	string names = ""
	int n = 0
	int i = 0
	While i < around.Length
		Actor a = around[i]
		If a && a != p && !a.IsDead() && a.IsInFaction(married) && !a.IsInCombat() && !InAnyScene(a)
			If names != ""
				names += ", "
			EndIf
			names += COR_Config.Clean(a.GetDisplayName())
			n += 1
		EndIf
		i += 1
	EndWhile
	If n < 2 || !COR_Config.Roll(COR_Config.I("iWivesChance:Spouses"))
		Return
	EndIf
	lastWivesMsg = now
	COR_Config.Note("cor_wives: " + names)
	AIAgentFunctions.requestMessage("(" + p.GetDisplayName() + "'s spouses " + names + " are here together)", "cor_wives")
EndFunction

; ---------------------------------------------------------------- OStim events

; marital duty: a scene of the player with spouses or partners resets their wait
Event OnSceneEnd(string eventName, string json, float numArg, Form sender)
	Actor[] acts = OJSON.GetActors(json)
	Actor p = Game.GetPlayer()
	If !acts || acts.Find(p) < 0
		Return
	EndIf
	Faction married = COR_Config.PlayerMarriedFaction()
	; sex counts in ORomance too - but not a scene tagged aggressive
	string sceneId = OJSON.GetScene(json)
	bool tender = COR_Config.B("bEnabled:General") && !(sceneId != "" && OMetadata.HasSceneTag(sceneId, "aggressive"))
	string names = ""
	int i = 0
	While i < acts.Length
		Actor a = acts[i]
		If a && a != p && !a.IsChild()
			If tender
				COR_Romance.SexAffection(a)
			EndIf
			If a.IsInFaction(married) || StorageUtil.GetIntValue(a, "or_k_part", -1) == 1
				If names != ""
					names += ","
				EndIf
				names += COR_Config.Clean(a.GetDisplayName())
			EndIf
		EndIf
		i += 1
	EndWhile
	If names != ""
		SendState("intimate|" + names)
	EndIf
EndEvent

; Fertility Mode 3 Fixes and Updates listens to the OStim NG event for the player's own
; scene only; OStim Standalone scenes between anyone reach it through its public
; insemination event (FertilityModeAddSperm: mother, father's name, father).
Event OnActorOrgasm(string eventName, string sceneId, float threadId, Form sender)
	Actor male = sender as Actor
	If !male || !COR_Config.B("bInseminate:Children") || !COR_Config.FertilityFaction()
		Return
	EndIf
	If male.GetActorBase().GetSex() != 0
		Return
	EndIf
	int tid = threadId as int
	int pos = OThread.GetActorPosition(tid, male)
	int act = OMetadata.FindActionForActor(sceneId, pos, "vaginalsex")
	If pos < 0 || act < 0
		Return
	EndIf
	Actor[] acts = OThread.GetActors(tid)
	int target = OMetadata.GetActionTarget(sceneId, act)
	If target < 0 || target >= acts.Length
		Return
	EndIf
	Actor mother = acts[target]
	If !mother || mother.GetActorBase().GetSex() != 1
		Return
	EndIf
	int handle = ModEvent.Create("FertilityModeAddSperm")
	If handle
		ModEvent.PushForm(handle, mother)
		ModEvent.PushString(handle, male.GetDisplayName())
		ModEvent.PushForm(handle, male)
		ModEvent.Send(handle)
		COR_Config.Note("Fertility Mode: " + male.GetDisplayName() + " -> " + mother.GetDisplayName())
	EndIf
EndEvent

; ---------------------------------------------------------------- marriage

Function Married(Actor npc, string result, bool engaged = False)
	If engaged
		SendState("engaged|" + COR_Config.Clean(npc.GetDisplayName()))
	Else
		SendState("married|" + COR_Config.Clean(npc.GetDisplayName()))
	EndIf
	lastPeople = "" ; the spouse list changed: send it again on the next poll
	COR_Config.Note(result)
	AIAgentFunctions.requestMessage("(" + result + ")", "cor_married")
EndFunction

; ---------------------------------------------------------------- helpers

bool Function InAnyScene(Actor a)
	int[] ids = OThread.GetAllThreadIDs()
	int i = 0
	While i < ids.Length
		If OThread.GetActorPosition(ids[i], a) > -1
			Return True
		EndIf
		i += 1
	EndWhile
	Return False
EndFunction

Function SendState(string s)
	COR_Config.Log("state " + s)
	AIAgentFunctions.requestMessage(s, "cor_state")
EndFunction

; the settings the server side needs, as JSON (names lose any double quotes)
Function SendConfig()
	string j = "{"
	j += "\"version\":\"" + COR_Config.Version() + "\""
	j += ",\"enabled\":" + COR_Config.Bit(COR_Config.B("bEnabled:General"))
	j += ",\"log\":" + COR_Config.Bit(COR_Config.B("bLog:Debug"))
	j += ",\"news\":" + COR_Config.Bit(COR_Config.B("bNews:Children"))
	j += ",\"odds\":" + COR_Config.Bit(COR_Config.B("bOdds:General"))
	j += ",\"affection\":" + COR_Config.Bit(COR_Config.B("bAffection:Love"))
	j += ",\"feelings\":" + COR_Config.Bit(COR_Config.B("bFeelings:Love"))
	j += ",\"spouse_life\":" + COR_Config.Bit(COR_Config.B("bSpouseLife:Spouses"))
	j += ",\"duties\":" + COR_Config.Bit(COR_Config.B("bDuties:Spouses"))
	j += ",\"duty\":" + COR_Config.Bit(COR_Config.B("bDuty:Spouses"))
	j += ",\"duty_hours\":" + COR_Config.I("iDutyHours:Spouses")
	j += ",\"duty_names\":\"" + COR_Config.Clean(COR_Config.S("sDutyHours:Spouses")) + "\""
	j += ",\"children\":" + COR_Config.Bit(COR_Config.B("bChildren:Children"))
	j += ",\"children_names\":\"" + COR_Config.Clean(COR_Config.S("sWantChildren:Children")) + "\""
	j += ",\"fertility\":" + COR_Config.Bit(COR_Config.B("bFertility:Children") && COR_Config.FertilityFaction() != None)
	j += "}"
	SendState("config|" + j)
EndFunction
