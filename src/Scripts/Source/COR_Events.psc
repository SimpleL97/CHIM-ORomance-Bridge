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
   date|Name       the player and this spouse or partner spent time together at an inn
   home|Name|Home  this spouse moved into that home (Move_In)
   people|... "k"  also the player's children (Fertility Mode births by the player): mother,
                   age in days, name
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
	RegisterForModEvent("FertilityModeLabor", "OnFMLabor")
	RegisterForModEvent("FMChildRenamed", "OnFMChildRenamed")
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
		COR_Romance.KeepBridesFollowing() ; every poll: the wedding dismisses a follower bride or groom (MCM)
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
	; an inn (LocTypeInn) with a spouse or partner close by: a date (MCM), once a game day each
	Location here = p.GetCurrentLocation()
	bool atInn = COR_Config.B("bDates:Spouses") && here && here.HasKeyword(Game.GetFormFromFile(0x01CB87, "Skyrim.esm") as Keyword)
	int today = now as int
	string j = ""
	int i = 0
	While i < around.Length
		Actor a = around[i]
		If a && a != p && !a.IsDead() && !a.IsChild()
			string name = COR_Config.Clean(a.GetDisplayName())
			bool spouse = a.IsInFaction(married)
			bool partner = StorageUtil.GetIntValue(a, "or_k_part", -1) == 1
			bool seeded = StorageUtil.GetIntValue(a, "or_k_seeded", -1) == 1
			If spouse || partner
				Sharing(a, name)
				If atInn && a.GetDistance(p) < 800.0 && StorageUtil.GetIntValue(a, "COR_DateDay", -1) != today
					StorageUtil.SetIntValue(a, "COR_DateDay", today)
					SendState("date|" + name)
				EndIf
			EndIf
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
				If seeded && a.GetRelationshipRank(p) < 0
					; ORomance made them hostile (a breakup, being caught cheating): Feel_Affection "forgive" ends it
					j += ",\"fo\":1"
				EndIf
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
	j = "{\"pg\":" + p.GetActorBase().GetSex() + ",\"p\":{" + j + "}" + KidsJson(now) + "}"
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
		If Utility.GetCurrentGameTime() - StorageUtil.GetFloatValue(a, "COR_LaborAt", -100.0) < 2.0
			Return ; already told by Fertility Mode's own labor event (OnFMLabor), with the father
		EndIf
		COR_Config.Note(name + " has given birth")
		AIAgentFunctions.requestMessage("(" + name + " has given birth to a child)", "cor_birth")
	EndIf
EndFunction

; ---------------------------------------------------------------- children (MCM: bKids)

; Fertility Mode's labor event (SendTrackingEvent: name, mother, her tracking index). A child
; of the player's is added to the bridge's list (StorageUtil, global): mother, game time of the
; birth, name ("" until Fertility Mode names it). The father is Fertility Mode's own record;
; failing that, the last man the bridge saw climax in her (OnActorOrgasm).
Event OnFMLabor(string eventName, Form akSender, int index)
	Actor mother = akSender as Actor
	If !mother || !COR_Config.B("bEnabled:General")
		Return
	EndIf
	Actor p = Game.GetPlayer()
	Form father = None
	_JSW_BB_Storage storage = COR_Config.FMStorage()
	If storage && index >= 0 && index < storage.LastFatherForm.Length && storage.TrackedActors[index] == mother
		father = storage.LastFatherForm[index]
	EndIf
	If !father
		father = StorageUtil.GetFormValue(mother, "COR_LastFather")
	EndIf
	string name = COR_Config.Clean(mother.GetDisplayName())
	float now = Utility.GetCurrentGameTime()
	StorageUtil.SetFloatValue(mother, "COR_LaborAt", now)
	string fatherName = ""
	If father as Actor
		fatherName = (father as Actor).GetDisplayName()
	EndIf
	bool mine = father == p
	If mine && COR_Config.B("bKids:Children")
		StorageUtil.FormListAdd(None, "COR_KidMother", mother, True)
		StorageUtil.FloatListAdd(None, "COR_KidBorn", now, True)
		StorageUtil.StringListAdd(None, "COR_KidName", "", True)
		lastPeople = "" ; the children changed: sent on the next poll
		COR_Config.Note(name + " gave birth to " + p.GetDisplayName() + "'s child")
	EndIf
	If COR_Config.B("bNews:Children") && (mine || mother.GetDistance(p) < 4000.0)
		string msg = name + " has given birth to a child"
		If fatherName != ""
			msg += " - the father is " + fatherName
		EndIf
		AIAgentFunctions.requestMessage("(" + msg + ")", "cor_birth")
	EndIf
EndEvent

; Fertility Mode names a child (FMChildRenamed: the child, its name): the newest unnamed child
; of the player's gets it
Event OnFMChildRenamed(Form child, string newName)
	newName = COR_Config.Clean(newName)
	If newName == ""
		Return
	EndIf
	int i = StorageUtil.StringListCount(None, "COR_KidName")
	While i > 0
		i -= 1
		If StorageUtil.StringListGet(None, "COR_KidName", i) == ""
			StorageUtil.StringListSet(None, "COR_KidName", i, newName)
			lastPeople = ""
			COR_Config.Note("child named " + newName)
			Return
		EndIf
	EndWhile
EndEvent

; ,"k":[{"m":mother,"d":age in days,"n":name}, ...] - the player's children, or ""
string Function KidsJson(float now)
	If !COR_Config.B("bKids:Children")
		Return ""
	EndIf
	int n = StorageUtil.FormListCount(None, "COR_KidMother")
	If n == 0
		Return ""
	EndIf
	string j = ""
	int i = 0
	While i < n
		Actor mother = StorageUtil.FormListGet(None, "COR_KidMother", i) as Actor
		If mother
			If j != ""
				j += ","
			EndIf
			int days = (now - StorageUtil.FloatListGet(None, "COR_KidBorn", i)) as int
			j += "{\"m\":\"" + COR_Config.Clean(mother.GetDisplayName()) + "\",\"d\":" + days + ",\"n\":\"" + StorageUtil.StringListGet(None, "COR_KidName", i) + "\"}"
		EndIf
		i += 1
	EndWhile
	Return ",\"k\":[" + j + "]"
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
	StorageUtil.SetFormValue(mother, "COR_LastFather", male) ; for OnFMLabor, if Fertility Mode's own record is missing
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

; ORomance Plus's jealousy: a partner or spouse who watches the player in an OStim scene with
; someone else "catches them cheating" (dislike, hate, the scene ended, often a breakup) when
; their monogamy desire (StorageUtil "or_k_monogamy", 1..100) is 16 or more - whatever their
; character says about sharing. MCM bShare: kept at 10 for them, the old value remembered
; ("COR_Monogamy") and given back when the option is turned off.
Function Sharing(Actor a, string name)
	int m = StorageUtil.GetIntValue(a, "or_k_monogamy", -1)
	If COR_Config.B("bShare:Love")
		If m >= 16
			If !StorageUtil.HasIntValue(a, "COR_Monogamy")
				StorageUtil.SetIntValue(a, "COR_Monogamy", m)
			EndIf
			StorageUtil.SetIntValue(a, "or_k_monogamy", 10)
			COR_Config.Log(name + " shares the player without jealousy (ORomance monogamy " + m + " -> 10)")
		EndIf
	ElseIf StorageUtil.HasIntValue(a, "COR_Monogamy")
		StorageUtil.SetIntValue(a, "or_k_monogamy", StorageUtil.GetIntValue(a, "COR_Monogamy"))
		StorageUtil.UnsetIntValue(a, "COR_Monogamy")
		COR_Config.Log(name + ": ORomance monogamy back to " + StorageUtil.GetIntValue(a, "or_k_monogamy"))
	EndIf
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
	j += ",\"kids\":" + COR_Config.Bit(COR_Config.B("bKids:Children"))
	j += ",\"move_in\":" + COR_Config.Bit(COR_Config.B("bMoveIn:Spouses") && COR_Config.SpouseHouses() != None)
	j += ",\"dates\":" + COR_Config.Bit(COR_Config.B("bDates:Spouses"))
	j += ",\"date_days\":" + COR_Config.I("iDateDays:Spouses")
	j += "}"
	SendState("config|" + j)
EndFunction
