CHIM ORomance Bridge 1.0.0 by SaurOff
=====================================

Connects CHIM AI agents with ORomance Plus: love grows from what you say and do,
agents become your partner and marry you when they want to (several spouses), and
spouses live as spouses - they talk to each other, share the household, ask for the
marital duty and, if you like, want children. Everything is configured in the MCM.


REQUIREMENTS
------------
- Skyrim Special / Anniversary Edition with SKSE64 and Address Library
- CHIM (AI agents, Nexus 126330), plugin and server (tested with 3.4.2)
- ORomance Plus (Nexus 81635) with its own requirements (ORomance, iWant Widgets,
  ConsoleUtil, Papyrus Extender, ...)
- OStim Standalone (Nexus 98163, tested with 7.5.1)
- PapyrusUtil SE/AE (Nexus 13048)
- SkyUI (Nexus 12604) and MCM Helper (Nexus 53000)
Recommended: CHIM OStim Bridge (Nexus 194761) - spouses start the scenes they ask for.
Optional: Fertility Mode 3 (Nexus 13068) with Fertility Mode 3 Fixes and Updates
(Nexus 46820) - cycle and pregnancy awareness, pregnancies from OStim scenes.


INSTALLATION
------------
1. Install with Vortex or MO2 and enable CHIMORomanceBridge.esp (ESL flagged, it does
   not use a load order slot). Load order does not matter.
2. Start the CHIM server as usual, then the game. The server side installs itself:
   the mod ships it as Data/CHIM/server-plugins/cor_oromance_bridge/1.0.0.dwpkg, and
   CHIM's game plugin uploads bundled server plugins to its server at startup
   (HerikaServer/ext/cor_oromance_bridge). The six actions are added to CHIM's action
   list on the first request.
3. Load a save. The MCM "CHIM ORomance Bridge" appears after a few seconds.

If your CHIM version does not install bundled server plugins (the CHIM log
SKSE/AIAgent.log has no "[SERVER_PLUGIN_SYNC] Installed cor_oromance_bridge" line),
choose "Manual server install tools" in the installer and run
CHIM ORomance Bridge Server Tools/Install-ServerPlugin.bat once.

Updating: install the new version; CHIM updates the server side on the next start.
Uninstalling: run Uninstall-ServerPlugin.bat from the manual tools (removes the server
folder and the six actions), then remove the mod.

The MCM is translated into English, Russian, Ukrainian, German, French, Spanish,
Italian, Polish, Czech, Portuguese, Japanese and Chinese and follows the game
language; other game languages show it in English.


WHAT IT DOES
------------
Actions the AI can use (they show up in CHIM's action list and can be switched off
there like any other action):
  Feel_Affection       something you said or did truly touched the agent
                       (compliment, gift, kindness, kiss, love): raises ORomance's
                       like, and love for kisses and declarations of love. Limited
                       per day (MCM), so one chatty evening does not win anyone over.
  Feel_Hurt            you insulted or hurt the agent (insult, cruelty, cheating):
                       raises ORomance's dislike.
  Become_Partner       the agent agrees to be your girlfriend or boyfriend.
  Marry_Player         the agent says yes to your proposal (you wear an Amulet of
                       Mara). The first spouse is engaged and married at the Temple
                       of Mara, later ones at once (ORomance Plus polygamy).
  Take_Household_Duty  a spouse takes on a household duty (cooking, cleaning,
                       guarding the house, ...); all spouses remember who does what.
  Give_Homemade_Meal   a spouse gives you a homemade meal (ORomance, once a day).
Every outcome is reported back to CHIM, so a refusal ("not enough love yet", "you
are already engaged") is answered in character instead of failing quietly.

"Use ORomance's odds" (MCM, on by default): becoming a couple and marrying also
need ORomance Plus's own check (love, level, Speech, fame). Off: the agent's yes in
the conversation and the amulet are enough.

The proposal line: ORomance Plus hides the vanilla marriage dialogue. This mod puts
"(Amulet of Mara) Will you marry me?" back into the normal dialogue menu, for anyone
who is at least your friend and not married to you yet, while you wear the amulet.
It marries the same way as Marry_Player.

Feelings: every agent's ORomance like, love and dislike for you are put into words in
their prompt ("you are in love with...", "you are angry with..."), so what they say
fits the game.

Married life (any number of spouses):
  - spouses know they are married to you and who the other spouses are;
  - when two or more are together, now and then one talks to another (about you, the
    household and its duties, the children they want, each other) - MCM chance and
    pause;
  - the marital duty: the longer it has been since you last made love to a spouse,
    the more openly they ask for it, sweetly or sharply as their character is
    (MCM: usual wait, and per spouse "Name=hours", 0 = never). With CHIM OStim Bridge
    they start the scene themselves; a spouse already listed for hunger for sex in
    CHIM OStim Bridge uses that instead.

Children (MCM: names): the people listed want a child with you and show it. With
Fertility Mode 3 and its Fixes and Updates they also know whether they are before
ovulation, ovulating, after it, on their period, pregnant (and how far) or recovering
from a birth - and so do spouses and partners. Fertility Mode's own OStim support
only hears the player's scenes; this mod tells it about vaginal climaxes in every
OStim Standalone scene, so NPC couples and spouses can get pregnant too.


COMPATIBILITY
-------------
- Uses its own plugin, scripts (COR_*) and CHIM action codes (ExtCmdCOR_*).
- Works next to CHIM OStim Bridge (that mod starts the scenes); do not install other
  mods that add actions with the same names to CHIM.
- Reads ORomance Plus's data and calls its own functions; it changes nothing in
  ORomance itself.
- Safe to add to an existing save. To remove: uninstall the server plugin first.


TROUBLESHOOTING
---------------
- Turn on "Show notifications" in the MCM to see every action result in game.
- No proposal line: wear the Amulet of Mara; the NPC must be at least your friend.
- "Not ready yet": with "Use ORomance's odds" on, ORomance decides - raise love, or
  switch the odds off.


CREDITS
-------
CHIM by Dwemer Dynamics, ORomance and ORomance Plus by their authors, OStim Standalone
by the OStim team, Fertility Mode by Narue and its Fixes and Updates by Subhuman0100,
PapyrusUtil by exiledviper and meh321, SkyUI by the SkyUI team, MCM Helper by Exit-9B.
