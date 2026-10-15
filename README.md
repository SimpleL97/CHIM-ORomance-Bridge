# CHIM ORomance Bridge

A Skyrim SE/AE mod by **SaurOff** that connects [CHIM](https://www.nexusmods.com/skyrimspecialedition/mods/126330)
(AI-driven NPCs) with [ORomance Plus](https://www.nexusmods.com/skyrimspecialedition/mods/81635).
Love grows from what you say and do in conversation, CHIM agents become your partner and
marry you when they want to (several spouses), and spouses live as spouses: they talk to
each other, share the household, ask for the marital duty and - if you like - want
children, knowing where they are in their cycle with Fertility Mode.

It is the companion of [CHIM OStim Bridge](https://github.com/SimpleL97/CHIM-OStim-Bridge),
built the same way, and works together with it.

> **Adult content.** This mod deals with sexual content in a video game and is meant
> for adults only.

This repository is the complete source of the mod. Players should download the packaged
release (FOMOD archive) from the Nexus Mods page instead of building it.

- **[BUILDING.md](BUILDING.md)** - how to build the release from these sources, step by
  step, and where every file in the release comes from
- **[DEPENDENCIES.md](DEPENDENCIES.md)** - every requirement and what it is used for
- [docs/README.txt](docs/README.txt) - the player readme shipped in the archive
- [docs/CHANGELOG.txt](docs/CHANGELOG.txt)

## What it does

- **AI actions** added to CHIM's action list, all done through ORomance Plus:
  `Feel_Affection` / `Feel_Hurt` (ORomance like, love, dislike), `Become_Partner`,
  `Marry_Player` (first spouse: engagement and the Temple of Mara wedding; later ones at
  once), `Take_Household_Duty`, `Give_Homemade_Meal`. Every result is reported back to
  the AI, so a refusal ("not enough love yet") is answered in character.
- **ORomance's odds** for partners and marriage can be used or left out (MCM).
- **The proposal line**: ORomance Plus hides the vanilla marriage dialogue; the mod puts
  "(Amulet of Mara) Will you marry me?" back into the normal dialogue menu.
- **Feelings in words**: each agent's ORomance like, love and dislike for the player go
  into their prompt.
- **Married life**: spouses know their marriage and each other, start conversations with
  each other, share household duties, and ask for the marital duty after a wait set per
  spouse in the MCM (scenes start through CHIM OStim Bridge).
- **Children**: the people named in the MCM want a child; with Fertility Mode 3 and its
  Fixes and Updates they know their cycle or pregnancy, and OStim Standalone scenes reach
  Fertility Mode.
- **MCM** through MCM Helper, translated into 12 languages with English fallback.

## How it works

```
          Skyrim (game)                                    CHIM server (WSL, HerikaServer)
 +-------------------------------+                 +------------------------------------------+
 | CHIMORomanceBridge.esp (ESL)  |                 | ext/cor_oromance_bridge/                  |
 |  COR_Bridge  <----------------+-- ExtCmdCOR_*   |  functions.php   actions for the LLM,     |
 |   actions via COR_Romance     |   (via COR)     |                  installed into           |
 |   -> ORomance Plus, reports --+---------------->|                  core_action_custom      |
 |  COR_Events                   |   funcret       |  prompts.php     cues for the events      |
 |   ORomance + Fertility Mode   |                 |  preprocessing   silent state             |
 |   state, OStim events, MCM ---+---------------->|  context_pre     love, marriage, duty,    |
 |  COR_MCM (MCM Helper)         |  cor_* events   |                  cycle -> every prompt    |
 |  COR_DialogueQuest: proposal  |                 |  cor_lib.php     shared code, state in    |
 +-------------------------------+                 |                  conf_opts                |
   Data/CHIM/server-plugins/                       +------------------------------------------+
   cor_oromance_bridge/<ver>.dwpkg ---- installed by CHIM at game start
```

1. The LLM picks one of the actions while replying (`ExtCmdCOR_Marry`, ...). CHIM's game
   plugin hands it to the global function `COR.DispatchExternalCommand`, which forwards
   it to `COR_Bridge` as the mod event `COR_Command`.
2. `COR_Bridge` does it through `COR_Romance`, which calls ORomance Plus's own quest
   script (`ORomanceScript`), and reports the outcome back to CHIM (`funcret`, through
   `AIAgentFunctions.logMessageForActor`).
3. `COR_Events` reads ORomance's stored data and Fertility Mode's state faction for the
   people near the player and sends it as silent state (`cor_state`), tracks scenes of
   the player with spouses, starts spouse conversations (`cor_wives`) and tells
   Fertility Mode about vaginal climaxes in OStim scenes.
4. The server plugin turns that state into a few lines at the end of each agent's prompt.

The server half ships inside the game mod as a `.dwpkg` package, which CHIM's game plugin
uploads to its own server at game start - players never copy server files by hand.

## Repository layout

```
src/Scripts/Source/   Papyrus sources: COR (CHIM entry point), COR_Bridge, COR_Romance,
                      COR_Events, COR_MCM, COR_Config, COR_TIF_Propose (dialogue fragment)
server/
  cor_oromance_bridge/  CHIM server plugin (PHP) - packaged into the .dwpkg
  *.bat, *.ps1          optional manual install / uninstall of the server plugin
mcm/                  MCM Helper menu (config.json, settings.ini) and translations/
fomod/                FOMOD installer (info.xml, ModuleConfig.xml)
docs/                 player README, CHANGELOG, Nexus page texts
stubs/                declaration-only Papyrus files for the compiler (not shipped)
make_esp.py           writes the plugin CHIMORomanceBridge.esp and its .seq file
compile_scripts.ps1   compiles the Papyrus scripts
localize.py           MCM menu, string table and translation file generator
build.py              builds the .dwpkg and the FOMOD release zip
verify_release.py     checks the release zip against the sources
```

## Building

Short version (details in [BUILDING.md](BUILDING.md)):

```
python3 -I make_esp.py
powershell -ExecutionPolicy Bypass -File compile_scripts.ps1 -Compiler "<Papyrus Compiler folder>" -GameData "<Skyrim>\Data"
python3 -I build.py
python3 -I verify_release.py "release/CHIM ORomance Bridge.zip"
```

## Installing (players)

Requirements: SKSE64, Address Library, CHIM (plugin and server), ORomance Plus,
OStim Standalone, PapyrusUtil, SkyUI, MCM Helper; recommended CHIM OStim Bridge; optional
Fertility Mode 3 + Fixes and Updates - see [DEPENDENCIES.md](DEPENDENCIES.md). Install the
release archive with Vortex or MO2, start the CHIM server, then the game.
More in [docs/README.txt](docs/README.txt).

## License

The mod's own code and files are released under the [MIT License](LICENSE).
The files in `stubs/` only declare the public script APIs of Bethesda, SkyUI, MCM Helper
and ORomance Plus for the compiler; they are not covered by this license and are not
shipped. CHIM, ORomance Plus, OStim Standalone, Fertility Mode and the other requirements
belong to their authors and are not included here.

## Credits

Dwemer Dynamics for CHIM, the authors of ORomance and ORomance Plus, the OStim team for
OStim Standalone, Narue for Fertility Mode and Subhuman0100 for its Fixes and Updates,
exiledviper and meh321 for PapyrusUtil, the SkyUI team, Exit-9B for MCM Helper, the SKSE team.
