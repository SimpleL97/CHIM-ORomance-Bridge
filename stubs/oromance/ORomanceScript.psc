Scriptname ORomanceScript extends Quest
{Declaration-only stand-in for ORomance Plus (Nexus 81635), the quest script of
 ORomanceQuest (ORomance.esp 0x000800), for the compiler. Only the functions this mod
 calls. Not compiled into the release and not shipped: in the game ORomance's own
 script runs. Read before the game's sources (see compile_scripts.ps1), because the real
 ORomance sources need the sources of many other mods to compile.}

Function SeedIfNeeded(Actor npc)
EndFunction

float Function getlikeStat(Actor npc)
EndFunction

float Function getloveStat(Actor npc)
EndFunction

float Function getdislikeStat(Actor npc)
EndFunction

Function increaselikestat(Actor npc, float val)
EndFunction

Function increaselovestat(Actor npc, float val)
EndFunction

Function increasedislikestat(Actor npc, float val)
EndFunction

Function setdislikestat(Actor npc, float val)
EndFunction

float Function gethateStat(Actor npc)
EndFunction

Function sethatestat(Actor npc, float val)
EndFunction

bool Function isPlayerPartner(Actor npc)
EndFunction

bool Function setPlayerPartner(Actor npc, bool partner)
EndFunction

bool Function TryAskOut(Actor npc)
EndFunction

bool Function TryPropose(Actor npc)
EndFunction

Function Marry(Actor npc)
EndFunction

bool Function IsMarried(Actor npc)
EndFunction

bool Function IsPlayerSpouse(Actor npc)
EndFunction

bool Function isPlayerVanillaSpouse(Actor npc)
EndFunction

bool Function isVanillaMarriageLocked()
EndFunction

bool Function isORMarriageLocked()
EndFunction

float Function canGiveMeal(Actor npc)
EndFunction

bool Function Givemeal(Actor npc)
EndFunction
