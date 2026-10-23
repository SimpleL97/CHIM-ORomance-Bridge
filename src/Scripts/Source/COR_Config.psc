Scriptname COR_Config Hidden
{CHIM ORomance Bridge by SaurOff - reads the MCM Helper settings (MCM/Config/CHIMORomanceBridge).}

string Function ModName() global
	Return "CHIMORomanceBridge"
EndFunction

string Function Version() global
	Return "1.0.0"
EndFunction

bool Function B(string id) global
	Return MCM.GetModSettingBool("CHIMORomanceBridge", id)
EndFunction

int Function I(string id) global
	Return MCM.GetModSettingInt("CHIMORomanceBridge", id)
EndFunction

string Function S(string id) global
	Return MCM.GetModSettingString("CHIMORomanceBridge", id)
EndFunction

; is name one of the comma separated names in the setting (Papyrus == ignores case)
bool Function InList(string id, string name) global
	string[] items = StringUtil.Split(S(id), ",")
	int i = 0
	While i < items.Length
		If Trim(items[i]) == name
			Return True
		EndIf
		i += 1
	EndWhile
	Return False
EndFunction

string Function Trim(string s) global
	While StringUtil.GetLength(s) > 0 && StringUtil.GetNthChar(s, 0) == " "
		s = StringUtil.Substring(s, 1)
	EndWhile
	While StringUtil.GetLength(s) > 0 && StringUtil.GetNthChar(s, StringUtil.GetLength(s) - 1) == " "
		s = StringUtil.Substring(s, 0, StringUtil.GetLength(s) - 1)
	EndWhile
	Return s
EndFunction

; percent chance roll, 0..100
bool Function Roll(int chance) global
	If chance >= 100
		Return True
	EndIf
	If chance <= 0
		Return False
	EndIf
	Return Utility.RandomInt(1, 100) <= chance
EndFunction

; something worth knowing: always in the log file (MCM), on screen when notifications are on
Function Note(string msg) global
	Debug.Trace("[CHIM ORomance Bridge] " + msg)
	Log(msg)
	If B("bNotify:Debug")
		Debug.Notification("COR: " + msg)
	EndIf
EndFunction

; Data/SKSE/Plugins/CHIMORomanceBridge.log - one game launch per file (COR_Events starts it)
Function Log(string msg) global
	If B("bLog:Debug")
		MiscUtil.WriteToFile("Data/SKSE/Plugins/CHIMORomanceBridge.log", msg + "\n", True, True)
	EndIf
EndFunction

Function NewLog() global
	If B("bLog:Debug")
		MiscUtil.WriteToFile("Data/SKSE/Plugins/CHIMORomanceBridge.log", "==== CHIM ORomance Bridge " + Version() + " - game started ====\n", False, True)
	EndIf
EndFunction

; text safe inside the JSON and the "|" / "~" separated lines sent to CHIM
string Function Clean(string s) global
	string out = ""
	int i = 0
	int n = StringUtil.GetLength(s)
	While i < n
		string c = StringUtil.GetNthChar(s, i)
		If c != "\"" && c != "\\" && c != "|" && c != "~"
			out += c
		EndIf
		i += 1
	EndWhile
	Return out
EndFunction

string Function Bit(bool b) global
	If b
		Return "1"
	EndIf
	Return "0"
EndFunction

; Fertility Mode 3 Fixes and Updates keeps every tracked woman's state as her rank in
; this faction (_JSW_BB_Utility.UpdateNPCFactions): 0..127 = percent of a pregnancy,
; -5 before ovulation, -15 an egg is ready, -25 luteal, -35 menstruation,
; -75 ovulation blocked, -85..-121 recovering after a birth. None without the mod.
Faction Function FertilityFaction() global
	If !Game.IsPluginInstalled("Fertility Mode 3 Fixes and Updates.esp")
		Return None
	EndIf
	Return Game.GetFormFromFile(0x000862, "Fertility Mode 3 Fixes and Updates.esp") as Faction ; _JSW_SUB_TrackedFemFaction
EndFunction

; Fertility Mode's storage (on _JSW_BB_HandlerQuest): per tracked woman, the father of her
; last child (LastFatherForm, same index as TrackedActors). None without the mod.
_JSW_BB_Storage Function FMStorage() global
	If !Game.IsPluginInstalled("Fertility Mode.esm")
		Return None
	EndIf
	Return Game.GetFormFromFile(0x000D62, "Fertility Mode.esm") as _JSW_BB_Storage
EndFunction

; ORomance Plus's spouse house tracker (MoveSpouse); None without ORomance Plus
ORomanceSpouseHouseScript Function SpouseHouses() global
	If !Game.IsPluginInstalled("ORomancePlus.esp")
		Return None
	EndIf
	Return Game.GetFormFromFile(0x00082C, "ORomancePlus.esp") as ORomanceSpouseHouseScript
EndFunction

Faction Function PlayerMarriedFaction() global
	Return Game.GetFormFromFile(0x0C6472, "Skyrim.esm") as Faction
EndFunction

Armor Function AmuletOfMara() global
	Return Game.GetFormFromFile(0x0C891B, "Skyrim.esm") as Armor
EndFunction
