;BEGIN FRAGMENT CODE - Do not edit anything between this and the end comment
;NEXT FRAGMENT INDEX 1
Scriptname COR_TIF_Propose Extends TopicInfo Hidden
{CHIM ORomance Bridge by SaurOff - the player's proposal line in the normal dialogue
 menu ("(Amulet of Mara) Will you marry me?"). ORomance Plus hides the vanilla lines;
 this marries through ORomance (COR_Romance.Marry), with or without its odds (MCM).}

;BEGIN FRAGMENT Fragment_0
Function Fragment_0(ObjectReference akSpeakerRef)
Actor akSpeaker = akSpeakerRef as Actor
;BEGIN CODE
string result = COR_Romance.Marry(akSpeaker)
If StringUtil.Find(result, "cannot") == 0 || StringUtil.Find(result, "nothing to do") == 0
	Debug.Notification(StringUtil.Substring(result, StringUtil.Find(result, ":") + 2))
EndIf
;END CODE
EndFunction
;END FRAGMENT

;END FRAGMENT CODE - Do not edit anything between this and the end comment
