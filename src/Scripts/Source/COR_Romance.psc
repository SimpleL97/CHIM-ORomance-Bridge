Scriptname COR_Romance Hidden
{CHIM ORomance Bridge by SaurOff - everything that goes through ORomance Plus: its
 like / love / dislike stats, partners and marriage. Shared by COR_Bridge (the AI's
 actions) and COR_TIF_Propose (the proposal line in the normal dialogue menu).
 ORomance keeps its stats per NPC from 0 to 30 and lets "like" fade by 3 a day.}

ORomanceScript Function Main() Global
	Return Game.GetFormFromFile(0x000800, "ORomance.esp") as ORomanceScript ; ORomanceQuest
EndFunction

; ---------------------------------------------------------------- stats

; Raises like (and love for the deepest moments) the way ORomance's own compliments
; and kisses do, capped per NPC and game day by the MCM. Returns the outcome for the AI.
string Function AddAffection(Actor npc, string kind) Global
	ORomanceScript main = Main()
	If !main
		Return "cannot: ORomance Plus is not running"
	EndIf
	main.SeedIfNeeded(npc)
	string who = npc.GetDisplayName()
	string you = Game.GetPlayer().GetDisplayName()
	If kind == "forgive"
		Return Forgive(npc)
	EndIf
	float like = COR_Config.I("iLikeGain:Love") as float
	float love = 0.0
	If kind == "gift"
		like = like * 2.0
	ElseIf kind == "love" || kind == "kiss"
		love = COR_Config.I("iLoveGain:Love") as float
	EndIf
	; daily cap on what conversation alone can give
	int cap = COR_Config.I("iDailyLike:Love")
	int day = Utility.GetCurrentGameTime() as int
	If StorageUtil.GetIntValue(npc, "COR_LikeDay", -1) != day
		StorageUtil.SetIntValue(npc, "COR_LikeDay", day)
		StorageUtil.SetFloatValue(npc, "COR_LikeToday", 0.0)
	EndIf
	float today = StorageUtil.GetFloatValue(npc, "COR_LikeToday", 0.0)
	If cap > 0 && today >= cap as float
		Return who + " is touched, but has already been won over as much as one day allows (like " + Stat(main.getlikeStat(npc)) + ", love " + Stat(main.getloveStat(npc)) + ")"
	EndIf
	If cap > 0 && today + like > cap as float
		like = cap as float - today
	EndIf
	StorageUtil.SetFloatValue(npc, "COR_LikeToday", today + like)
	If like > 0.0
		main.increaselikestat(npc, like)
	EndIf
	If love > 0.0
		main.increaselovestat(npc, love)
	EndIf
	Return who + " feels warmer toward " + you + " (like " + Stat(main.getlikeStat(npc)) + ", love " + Stat(main.getloveStat(npc)) + ")"
EndFunction

; A scene with the player: like and love grow, the way ORomance's own scenes do, with
; ORomance's own ceilings for love from sex (10 for anyone, 20 for a partner, 30 for a
; spouse). ORomance adds its own +3 like / +1 love when the NPC climaxes in the player's
; scene (through OStim's older events); this counts every scene, climax or not.
Function SexAffection(Actor npc) Global
	ORomanceScript main = Main()
	If !main || !npc
		Return
	EndIf
	main.SeedIfNeeded(npc)
	int like = COR_Config.I("iSexLike:Love")
	int love = COR_Config.I("iSexLove:Love")
	If like > 0
		main.increaselikestat(npc, like as float)
	EndIf
	If love > 0
		float ceiling = 10.0
		If IsSpouse(npc)
			ceiling = 30.0
		ElseIf main.isPlayerPartner(npc)
			ceiling = 20.0
		EndIf
		float now = main.getloveStat(npc)
		If now + love > ceiling
			love = (ceiling - now) as int
		EndIf
		If love > 0
			main.increaselovestat(npc, love as float)
		EndIf
	EndIf
	COR_Config.Note(npc.GetDisplayName() + " after the scene: like " + Stat(main.getlikeStat(npc)) + ", love " + Stat(main.getloveStat(npc)))
EndFunction

; Making up after a quarrel, a breakup or being caught cheating. ORomance has no way back
; from that but its apology, which always fails once "hate" reaches 10: a breakup leaves
; dislike at 30 and both relationship ranks at -2 (the NPC will not talk, "I don't like
; you"). When the agent forgives in character, dislike drops by 10 and hate by 5, and a
; hostile rank becomes friendly again; love and partnership are not given back.
string Function Forgive(Actor npc) Global
	ORomanceScript main = Main()
	Actor player = Game.GetPlayer()
	float dislike = main.getdislikeStat(npc) - 10.0
	If dislike < 0.0
		dislike = 0.0
	EndIf
	main.setdislikestat(npc, dislike)
	float hate = main.gethateStat(npc) - 5.0
	If hate < 0.0
		hate = 0.0
	EndIf
	main.sethatestat(npc, hate)
	If npc.GetRelationshipRank(player) < 1
		npc.SetRelationshipRank(player, 1)
		player.SetRelationshipRank(npc, 1)
	EndIf
	If npc.GetCombatTarget() == player
		npc.StopCombat()
	EndIf
	COR_Config.Log(npc.GetDisplayName() + " forgives: dislike " + Stat(dislike) + ", hate " + Stat(hate))
	Return npc.GetDisplayName() + " forgives " + player.GetDisplayName() + " (dislike " + Stat(dislike) + ")"
EndFunction

string Function AddHurt(Actor npc, string kind) Global
	ORomanceScript main = Main()
	If !main
		Return "cannot: ORomance Plus is not running"
	EndIf
	main.SeedIfNeeded(npc)
	float hurt = COR_Config.I("iDislikeGain:Love") as float
	If kind == "cheating" || kind == "cruelty"
		hurt = hurt * 2.0
	EndIf
	main.increasedislikestat(npc, hurt)
	Return npc.GetDisplayName() + " is hurt by " + Game.GetPlayer().GetDisplayName() + " (dislike " + Stat(main.getdislikeStat(npc)) + ")"
EndFunction

string Function Stat(float v) Global
	If v < 0.0
		v = 0.0
	EndIf
	Return (v as int) + "/30"
EndFunction

; ---------------------------------------------------------------- partners and marriage

bool Function IsSpouse(Actor npc) Global
	Return npc.IsInFaction(COR_Config.PlayerMarriedFaction())
EndFunction

bool Function IsPartner(Actor npc) Global
	ORomanceScript main = Main()
	Return main && main.isPlayerPartner(npc)
EndFunction

; becoming the player's girlfriend / boyfriend ("Confess love" in ORomance)
string Function BecomePartner(Actor npc) Global
	ORomanceScript main = Main()
	string who = npc.GetDisplayName()
	string you = Game.GetPlayer().GetDisplayName()
	If !main
		Return "cannot: ORomance Plus is not running"
	EndIf
	main.SeedIfNeeded(npc)
	If IsSpouse(npc)
		Return "nothing to do: " + who + " already is married to " + you
	EndIf
	If main.isPlayerPartner(npc)
		Return "nothing to do: " + who + " already is " + you + "'s partner"
	EndIf
	If COR_Config.B("bOdds:General") && !main.TryAskOut(npc)
		Return "cannot: " + who + " is not ready yet - ORomance Plus says there is not enough affection between them (like " + Stat(main.getlikeStat(npc)) + ", love " + Stat(main.getloveStat(npc)) + ")"
	EndIf
	main.setPlayerPartner(npc, True)
	Return who + " is now " + you + "'s partner"
EndFunction

; The way ORomance Plus's own "Propose marriage" goes when it succeeds: the first spouse
; is engaged (vanilla wedding at the Temple of Mara), every later one too (ORomance Plus's own
; wedding there, RelationshipMarriage_OR).
; bOdds on: ORomance's own proposal check decides first. Returns the outcome for the AI.
string Function Marry(Actor npc) Global
	ORomanceScript main = Main()
	Actor player = Game.GetPlayer()
	string who = npc.GetDisplayName()
	string you = player.GetDisplayName()
	If !main
		Return "cannot: ORomance Plus is not running"
	EndIf
	If !player.IsEquipped(COR_Config.AmuletOfMara())
		Return "cannot: " + you + " is not wearing an Amulet of Mara"
	EndIf
	main.SeedIfNeeded(npc)
	If main.IsPlayerSpouse(npc)
		Return "nothing to do: " + who + " already is married to " + you
	EndIf
	If main.IsMarried(npc)
		Return "cannot: " + who + " is married to someone else"
	EndIf
	If main.isVanillaMarriageLocked()
		Return "cannot: " + you + " is already engaged, and that wedding at the Temple of Mara has to happen first"
	EndIf
	If main.isORMarriageLocked()
		Actor waiting = FurtherBetrothed()
		If waiting == npc
			Return "nothing to do: " + who + " and " + you + " already are engaged; the wedding at the Temple of Mara in Riften is waiting"
		ElseIf waiting
			Return "cannot: " + you + " is already engaged to " + waiting.GetDisplayName() + ", and that wedding at the Temple of Mara has to happen first"
		EndIf
		Return "cannot: ORomance Plus does not allow a marriage right now"
	EndIf
	If COR_Config.B("bOdds:General") && !main.TryPropose(npc)
		Return "cannot: " + who + " is not ready to marry yet - ORomance Plus says there is not enough love between them (love " + Stat(main.getloveStat(npc)) + ")"
	EndIf
	Quest wedding = Game.GetFormFromFile(0x074793, "Skyrim.esm") as Quest ; RelationshipMarriage
	bool first = wedding && !wedding.IsStopped()
	NoteFollowingBride(npc)
	main.Marry(npc)
	string result = who + " is now married to " + you
	Utility.Wait(4.0) ; the spoken acceptance, if there is one, sets the stage meanwhile
	If first
		RepairWedding(npc)
		result = who + " and " + you + " are engaged; the wedding will be held at the Temple of Mara in Riften"
	Else
		RepairFurtherWedding(npc)
		If FurtherBetrothed() == npc
			first = True ; reported as an engagement: the wedding comes first
			result = who + " and " + you + " are engaged; the wedding will be held at the Temple of Mara in Riften"
		ElseIf !main.IsPlayerSpouse(npc)
			Return "cannot: ORomance Plus did not take " + who + " as a further spouse (the number of spouses it allows may be reached)"
		EndIf
	EndIf
	COR_Events ev = Game.GetFormFromFile(0x000801, "CHIMORomanceBridge.esp") as COR_Events
	If ev
		ev.Married(npc, result, first)
	EndIf
	Return result
EndFunction

; ORomance's vanilla engagement sets RelationshipMarriage to stage 10 and has the NPC say
; the vanilla acceptance line, whose fragment names them the love interest and sets stage
; 20 - the stage Maramal's wedding dialogue needs. A follower with a voice of their own has
; no such line: the quest stays at 10 with nobody in it, and the Temple of Mara knows of no
; wedding. This does what the line would have done, for the one ORomance meant (its
; VanillaSpouseFaction) or for npc. Returns whether it had to.
bool Function RepairWedding(Actor npc = None) Global
	Quest wedding = Game.GetFormFromFile(0x074793, "Skyrim.esm") as Quest ; RelationshipMarriage
	If !wedding || !wedding.IsRunning() || wedding.GetStage() < 10 || wedding.GetStage() >= 20
		Return False
	EndIf
	ReferenceAlias loveInterest = wedding.GetAlias(0) as ReferenceAlias ; LoveInterest
	If !loveInterest || loveInterest.GetReference()
		Return False
	EndIf
	If !npc
		npc = BrideOrGroom()
	EndIf
	If !npc || npc.IsDead() || IsSpouse(npc)
		Return False
	EndIf
	npc.AddToFaction(Game.GetFormFromFile(0x0FF7F3, "Skyrim.esm") as Faction) ; MarriageAskedFaction
	loveInterest.ForceRefTo(npc)
	wedding.SetStage(20)
	COR_Config.Note(npc.GetDisplayName() + " is now the betrothed at the Temple of Mara: talk to Maramal about the wedding")
	Return True
EndFunction

; ORomance Plus marries every further spouse with a wedding of its own at the Temple of Mara
; (RelationshipMarriage_OR, its ceremony relationshipmarriagewedding_OR). The NPC says its
; acceptance line, whose fragment (TIF__ORomanceMarriageAccept) names them the love interest,
; locks further marriages and sets stage 20, Maramal's cue. A follower with a voice of their
; own has no such line, so this does what the fragment would have done. Only right after
; ORomance's Marry chose the further path (the NPC is in PotentialMarriageFaction).
bool Function RepairFurtherWedding(Actor npc) Global
	Quest wedding = Quest.GetQuest("RelationshipMarriage_OR")
	GlobalVariable locked = Game.GetFormFromFile(0x000F62, "ORomancePlus.esp") as GlobalVariable
	If !wedding || !locked || !npc || npc.IsDead() || IsSpouse(npc)
		Return False
	EndIf
	If !npc.IsInFaction(Game.GetFormFromFile(0x019809, "Skyrim.esm") as Faction) ; PotentialMarriageFaction
		Return False
	EndIf
	ReferenceAlias loveInterest = wedding.GetAlias(0) as ReferenceAlias ; LoveInterest
	If !loveInterest || locked.GetValueInt() == 1
		Return False ; the line did it, or another such wedding is waiting
	EndIf
	npc.AddToFaction(Game.GetFormFromFile(0x0FF7F3, "Skyrim.esm") as Faction) ; MarriageAskedFaction
	npc.AddToFaction(Game.GetFormFromFile(0x07431A, "Skyrim.esm") as Faction) ; CourtingFaction
	If wedding.GetStage() == 100 || wedding.GetStageDone(250)
		wedding.Reset()
		wedding.SetStage(10)
		Quest ceremony = Quest.GetQuest("relationshipmarriagewedding_OR")
		If ceremony
			ceremony.Reset()
		EndIf
	EndIf
	loveInterest.ForceRefTo(npc)
	locked.SetValueInt(1)
	Main().setPlayerPartner(npc, True)
	wedding.SetStage(20)
	COR_Config.Note(npc.GetDisplayName() + " is now betrothed at the Temple of Mara: talk to Maramal about the wedding")
	Return True
EndFunction

; who is waiting for ORomance Plus's further wedding, if anyone
Actor Function FurtherBetrothed() Global
	GlobalVariable locked = Game.GetFormFromFile(0x000F62, "ORomancePlus.esp") as GlobalVariable
	Quest wedding = Quest.GetQuest("RelationshipMarriage_OR")
	If !locked || locked.GetValueInt() != 1 || !wedding
		Return None
	EndIf
	ReferenceAlias loveInterest = wedding.GetAlias(0) as ReferenceAlias
	If !loveInterest
		Return None
	EndIf
	Return loveInterest.GetActorReference()
EndFunction

; The wedding itself (vanilla and ORomance Plus's own alike) dismisses the bride or groom
; when they are the player's follower, and the wedding quest then keeps them at the temple
; until the player has left. Whoever was following the player at the proposal is noted here
; and, once married, made a follower again (DialogueFollower's SetFollower, which Nether's
; Follower Framework takes over when installed).
Function NoteFollowingBride(Actor npc) Global
	Faction following = Game.GetFormFromFile(0x05C84E, "Skyrim.esm") as Faction ; CurrentFollowerFaction
	If npc.IsPlayerTeammate() || (following && npc.GetFactionRank(following) >= 0)
		StorageUtil.FormListAdd(None, "COR_FollowingBrides", npc, False)
	EndIf
EndFunction

Function RehireBrides() Global
	int i = StorageUtil.FormListCount(None, "COR_FollowingBrides")
	While i > 0
		i -= 1
		Actor a = StorageUtil.FormListGet(None, "COR_FollowingBrides", i) as Actor
		If !a || a.IsDead()
			StorageUtil.FormListRemoveAt(None, "COR_FollowingBrides", i)
		ElseIf IsSpouse(a)
			StorageUtil.FormListRemoveAt(None, "COR_FollowingBrides", i)
			If !a.IsPlayerTeammate()
				DialogueFollowerScript hire = Game.GetFormFromFile(0x0750BA, "Skyrim.esm") as DialogueFollowerScript
				If hire
					hire.SetFollower(a)
					COR_Config.Note(a.GetDisplayName() + " follows you again after the wedding")
				EndIf
			EndIf
		EndIf
	EndWhile
EndFunction

; the one ORomance Plus marked for the vanilla wedding (VanillaSpouseFaction), near the player
Actor Function BrideOrGroom() Global
	If !Game.IsPluginInstalled("ORomancePlus.esp")
		Return None
	EndIf
	Faction chosen = Game.GetFormFromFile(0x000803, "ORomancePlus.esp") as Faction ; VanillaSpouseFaction
	If !chosen
		Return None
	EndIf
	Actor p = Game.GetPlayer()
	Actor[] around = MiscUtil.ScanCellNPCs(p, 6000.0)
	int i = 0
	While i < around.Length
		If around[i] && around[i] != p && around[i].IsInFaction(chosen) && !IsSpouse(around[i])
			Return around[i]
		EndIf
		i += 1
	EndWhile
	Return None
EndFunction

; ORomance's homemade meal (once a day per spouse)
string Function Meal(Actor npc) Global
	ORomanceScript main = Main()
	string who = npc.GetDisplayName()
	If !main
		Return "cannot: ORomance Plus is not running"
	EndIf
	If !IsSpouse(npc)
		Return "cannot: only a spouse cooks a homemade meal"
	EndIf
	float wait = main.canGiveMeal(npc)
	If wait < 1.0
		Return "cannot: " + who + " already cooked today; the next meal in " + ((1.0 - wait) * 24.0) as int + " hours"
	EndIf
	main.Givemeal(npc)
	Return who + " gives " + Game.GetPlayer().GetDisplayName() + " a homemade meal"
EndFunction
