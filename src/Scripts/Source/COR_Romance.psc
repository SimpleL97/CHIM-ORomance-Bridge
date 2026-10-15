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
; is engaged (vanilla wedding at the Temple of Mara), every later one is married at once.
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
		Return "cannot: ORomance Plus does not allow a marriage right now"
	EndIf
	If COR_Config.B("bOdds:General") && !main.TryPropose(npc)
		Return "cannot: " + who + " is not ready to marry yet - ORomance Plus says there is not enough love between them (love " + Stat(main.getloveStat(npc)) + ")"
	EndIf
	Quest wedding = Game.GetFormFromFile(0x074793, "Skyrim.esm") as Quest ; RelationshipMarriage
	bool first = wedding && !wedding.IsStopped()
	main.Marry(npc)
	string result = who + " is now married to " + you
	If first
		result = who + " and " + you + " are engaged; the wedding will be held at the Temple of Mara in Riften"
	EndIf
	COR_Events ev = Game.GetFormFromFile(0x000801, "CHIMORomanceBridge.esp") as COR_Events
	If ev
		ev.Married(npc, result)
	EndIf
	Return result
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
