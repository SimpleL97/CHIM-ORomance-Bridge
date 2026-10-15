<?php

/**
 * CHIM ORomance Bridge by SaurOff - how agents react to the events COR_Events sends.
 * Toggles and chances are applied in the game (MCM). Loaded inside a function: use $GLOBALS.
 */

$corNpc  = $GLOBALS["HERIKA_NAME"] ?? "";
$corTail = $GLOBALS["TEMPLATE_DIALOG"] ?? "";

$GLOBALS["PROMPTS"]["cor_married"] = [
    "cue" => ["({$corNpc} reacts in character to the engagement or marriage described above. If it is about them: their joy, nerves or tenderness, what this means to them. If it is about someone else: their honest reaction - happiness, envy, jealousy or teasing. One or two short lines.) {$corTail}"],
];
$GLOBALS["PROMPTS"]["cor_wives"] = [
    "cue" => ["(If {$corNpc} is one of the spouses named above, they turn to another of them, call them by name and talk to them in character: about the husband they share, the household and who takes which duty, the children they want, or about each other - warmth, teasing, rivalry or jealousy, whatever fits their characters. If {$corNpc} is not one of them, a short remark about the spouses. One or two short lines.) {$corTail}"],
];
