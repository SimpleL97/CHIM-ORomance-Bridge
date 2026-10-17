# Dependencies

What CHIM ORomance Bridge needs, and exactly what each piece is used for.
None of these are bundled: the release ships only this mod's own files.

## To play

| Dependency | Link | Why it is needed |
|---|---|---|
| **Skyrim Special / Anniversary Edition** | - | The game. Tested on 1.6.1170. `Skyrim.esm`: `PlayerMarriedFaction` (0x0C6472, who is married to the player), the `Amulet of Mara` (0x0C891B), the quest `RelationshipMarriage` (0x074793, first spouse or not), and the layout and conditions of its courting dialogue, copied for the proposal line. |
| **SKSE64** | [skse.silverlock.org](https://skse.silverlock.org/) | Script extender: `RegisterForModEvent` (CHIM commands, OStim events), `ModEvent` (the insemination event for Fertility Mode), `GetDisplayName`, `StringUtil`, `Game.IsPluginInstalled`. |
| **Address Library for SKSE Plugins** | [Nexus 32444](https://www.nexusmods.com/skyrimspecialedition/mods/32444) | Not used directly; the SKSE plugins of CHIM, OStim and the others need it. |
| **CHIM** (game plugin **and** server) | [Nexus 126330](https://www.nexusmods.com/skyrimspecialedition/mods/126330) | The AI side. In the game: CHIM's plugin delivers the actions by calling the global `COR.DispatchExternalCommand` (its fallback mod event `CHIM_CommandReceived` is heard too); `AIAgentFunctions` is used for `getAgentByName`, `getClosestAgent`, `logMessageForActor` (each action's result), `requestMessage` (events and silent state) and `isActorTalking` (waits for the agent's line). On the server: the `ext/cor_oromance_bridge` plugin hooks into CHIM's request pipeline (`preprocessing.php`, `functions.php`, `prompts.php`, `context_pre.php` with `chimRegisterPromptInjection`) and keeps its actions, settings and state in CHIM's database (`core_action_custom`, `conf_opts`). CHIM's `ServerPluginSync` installs the bundled `Data/CHIM/server-plugins/cor_oromance_bridge/<version>.dwpkg` at game start. Tested with 3.4.2. |
| **ORomance Plus** (and its requirements: ORomance, iWant Widgets, ConsoleUtil, Papyrus Extender, ...) | [Nexus 81635](https://www.nexusmods.com/skyrimspecialedition/mods/81635) | The relationship system. `COR_Romance` calls its quest script `ORomanceScript` (`ORomance.esp` 0x000800): `SeedIfNeeded`, `increaselikestat` / `increaselovestat` / `increasedislikestat` and their getters, `isPlayerPartner`, `setPlayerPartner`, `TryAskOut` and `TryPropose` (its odds, MCM switch), `Marry`, `IsMarried`, `IsPlayerSpouse`, `isVanillaMarriageLocked`, `isORMarriageLocked`, `canGiveMeal`, `Givemeal`. `COR_Events` reads ORomance's own StorageUtil values without writing anything (`or_k_seeded`, `or_k_part`, `or_k_li` / `or_k_li_last`, `or_k_love`, `or_k_di` / `or_k_di_last`). |
| **OStim Standalone** | [Nexus 98163](https://www.nexusmods.com/skyrimspecialedition/mods/98163) | `ostim_thread_end` (a scene of the player raises the ORomance like and love of everyone in it, unless `OMetadata.HasSceneTag(..., "aggressive")`; with a spouse or partner it also resets the marital-duty wait), `ostim_actor_orgasm` with `OThread` and `OMetadata` (`FindActionForActor`, `GetActionTarget`: who was in vaginal sex with whom), `OJSON.GetActors`. Tested with 7.5.1. |
| **PapyrusUtil SE/AE** | [Nexus 13048](https://www.nexusmods.com/skyrimspecialedition/mods/13048) | `MiscUtil.ScanCellNPCs` (people near the player), `StorageUtil` (ORomance's data, the daily affection limit). |
| **SkyUI** | [Nexus 12604](https://www.nexusmods.com/skyrimspecialedition/mods/12604) | MCM framework: `SKI_ConfigBase`, `SKI_PlayerLoadGameAlias`, and the `Interface/Translations` loader for the 12 menu languages. |
| **MCM Helper** | [Nexus 53000](https://www.nexusmods.com/skyrimspecialedition/mods/53000) | Builds the MCM from `MCM/Config/CHIMORomanceBridge/config.json` and stores the settings (`MCM.GetModSettingBool/Int/String`); `COR_MCM` extends `MCM_ConfigBase`. |

Optional, recommended:

- **CHIM OStim Bridge** - my other mod, made the same way
  ([Nexus 194761](https://www.nexusmods.com/skyrimspecialedition/mods/194761),
  [GitHub](https://github.com/SimpleL97/CHIM-OStim-Bridge)). Not required. It starts
  the OStim scenes (spouses asking for the marital duty start the scene with its
  `Start_Intimate_Scene` action). The server plugin only mentions that action when CHIM
  OStim Bridge's server plugin is loaded, and skips its own marital-duty line for a
  spouse already listed for hunger for sex there.

Optional:

- [Fertility Mode 3](https://www.nexusmods.com/skyrimspecialedition/mods/13068) with
  [Fertility Mode 3 Fixes and Updates](https://www.nexusmods.com/skyrimspecialedition/mods/46820).
  Its state for each tracked woman is read as her rank in its faction
  `_JSW_SUB_TrackedFemFaction` (`Fertility Mode 3 Fixes and Updates.esp` 0x000862, set by
  its `_JSW_BB_Utility.UpdateNPCFactions`): 0..127 = percent of a pregnancy, -5 before
  ovulation, -15 an egg is ready, -25 luteal, -35 menstruation, -75 ovulation blocked,
  -85..-121 recovering after a birth. Vaginal climaxes in OStim Standalone scenes are sent
  as its public mod event `FertilityModeAddSperm` (mother, father's name, father). Without
  the mod nothing of this runs.

## To build

See [BUILDING.md](BUILDING.md) for the steps.

| Tool / file | Used for |
|---|---|
| **Python 3.8+** (standard library only) | `make_esp.py`, `localize.py`, `build.py`, `verify_release.py`. |
| **Windows PowerShell 5.1+** | `compile_scripts.ps1`. |
| **Papyrus compiler** | Compiling `src/Scripts/Source/*.psc`. Either the open-source [papyrus-compiler](https://github.com/russo-2025/papyrus-compiler) (MIT; Linux, macOS, Windows; what the GitHub releases are built with, from commit `b9dc995`) or Bethesda's `PapyrusCompiler.exe` + `TESV_Papyrus_Flags.flg` from the free Creation Kit (Steam), also bundled in Nemesis Unlimited Behavior Engine. |
| **V** 0.5.1 (only to build papyrus-compiler from source) | [github.com/vlang/v](https://github.com/vlang/v/releases/tag/0.5.1). |
| **Base game Papyrus sources** | Types such as `Actor`, `Quest`. Creation Kit: extract `Data\Scripts.zip`. Without it, `stubs/vanilla` has declaration-only stand-ins for the few types otherwise missing. |
| **Papyrus sources of SKSE, OStim Standalone, PapyrusUtil and CHIM** | Type checking only; each of these mods installs its `.psc` files. |
| **SkyUI / MCM Helper / ORomance sources** (optional) | Not needed: `stubs/` and `stubs/oromance` declare the functions this mod calls. |

### About the stubs

`stubs/` holds declaration-only `.psc` files: script names and function signatures, no
code. They exist only so the compiler can type-check calls into SkyUI, MCM Helper,
ORomance Plus and a few base game types. They are never compiled into the release and never
shipped; in the game the real scripts of those mods run. `stubs/oromance` is read before
the game's own sources, because ORomance's real sources need the sources of many other
mods to compile; `stubs` and `stubs/vanilla` come last and only fill gaps. They describe the
public APIs of their owners (Bethesda, the SkyUI team, Exit-9B, the ORomance authors) and
are not covered by this repository's license. `stubs/headers` is generated by
`tools/gen_headers.py` from the installed sources of the base game, SKSE, OStim
Standalone, PapyrusUtil and CHIM - only the types this mod uses - so the mod builds
without the game (GitHub Actions).
