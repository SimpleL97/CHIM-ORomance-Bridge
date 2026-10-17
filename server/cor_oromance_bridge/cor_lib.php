<?php

/**
 * CHIM ORomance Bridge by SaurOff - server side, shared code.
 *
 * Settings come from the game (MCM -> COR_Events.SendConfig -> "cor_state config|{json}")
 * and are kept in conf_opts together with the state: what the game last told about each
 * person (spouse, partner, ORomance like / love / dislike, Fertility Mode state, gender),
 * when each spouse or partner last shared a scene with the player, and the household
 * duties the spouses took on. Times are CHIM gamets (1 game hour = 416666.67 gamets).
 *
 * The other bridges of the family (CHIM OStim Bridge, CHIM Vampire Bridge) are optional:
 * corPeer() says whether one is installed and switched on, and only reads its settings.
 */

const COR_VERSION = "1.0.0";
const COR_PLUGIN = "cor_oromance_bridge";
const COR_CONFIG_KEY = "cor_oromance_bridge_config";
const COR_STATE_KEY = "cor_oromance_bridge_state";
const COR_HOUR = 416666.6667;

// ---------------------------------------------------------------- storage

function corOptGet(string $id)
{
    $db = $GLOBALS["db"] ?? null;
    if (!$db) {
        return null;
    }
    $row = $db->fetchOne("SELECT value FROM conf_opts WHERE id = $1", [$id]);
    $v = !empty($row) ? json_decode(strval($row["value"] ?? ""), true) : null;
    return is_array($v) ? $v : null;
}

function corOptSet(string $id, array $value): void
{
    $db = $GLOBALS["db"] ?? null;
    if ($db) {
        $db->upsertRowOnConflict("conf_opts", ["id" => $id, "value" => json_encode($value, JSON_UNESCAPED_UNICODE)], "id");
    }
}

function corConfig(): array
{
    static $cfg = null;
    if ($cfg === null) {
        $defaults = [
            "enabled" => 1, "log" => 1, "news" => 1, "odds" => 1, "affection" => 1, "feelings" => 1, "spouse_life" => 1,
            "duties" => 1, "duty" => 1, "duty_hours" => 48, "duty_names" => "",
            "children" => 1, "children_names" => "", "fertility" => 0,
        ];
        $cfg = array_merge($defaults, corOptGet(COR_CONFIG_KEY) ?? []);
    }
    return $cfg;
}

function corNames(string $csv): array
{
    return array_values(array_filter(array_map(function ($n) {
        return mb_strtolower(trim($n));
    }, explode(",", $csv))));
}

function corListed(string $csvKey, string $npc): bool
{
    return in_array(mb_strtolower(trim($npc)), corNames(strval(corConfig()[$csvKey] ?? "")), true);
}

function corNow(): float
{
    $req = $GLOBALS["gameRequest"] ?? null;
    return floatval(is_array($req) ? ($req[2] ?? 0) : 0);
}

function corHoursSince($then, float $now): ?float
{
    if ($then === null || $now <= 0) {
        return null;
    }
    return max(0.0, ($now - floatval($then)) / COR_HOUR);
}

// ---------------------------------------------------------------- the other bridges

/**
 * Settings of another bridge of the family ("cob_ostim_bridge", "cov_vampire_bridge"), or
 * null when it is not installed on this server or is switched off in its MCM. Read only:
 * no bridge depends on another one.
 */
function corPeer(string $plugin): ?array
{
    if (!is_dir(dirname(__DIR__) . DIRECTORY_SEPARATOR . $plugin)) {
        return null;
    }
    $cfg = corOptGet($plugin . "_config") ?? [];
    return array_key_exists("enabled", $cfg) && empty($cfg["enabled"]) ? null : $cfg;
}

// ---------------------------------------------------------------- log

/** HerikaServer/log/cor_oromance_bridge.log (MCM: Write a log file); kept under 2 MB */
function corLog(string $msg): void
{
    static $on = null;
    if ($on === null) {
        $on = !empty(corConfig()["log"]);
    }
    if (!$on) {
        return;
    }
    try {
        $file = dirname(__DIR__, 2) . DIRECTORY_SEPARATOR . "log" . DIRECTORY_SEPARATOR . COR_PLUGIN . ".log";
        if (@filesize($file) > 2 * 1024 * 1024) {
            @rename($file, $file . ".1");
        }
        @file_put_contents($file, date("Y-m-d H:i:s") . " " . $msg . "\n", FILE_APPEND);
    } catch (Throwable $e) {
    }
}

/** "Name=24, Other=0" -> hours between marital-duty wishes for that spouse (0 = never), else the default */
function corDutyHours(string $npc): int
{
    $cfg = corConfig();
    foreach (explode(",", strval($cfg["duty_names"] ?? "")) as $pair) {
        $kv = explode("=", $pair, 2);
        if (count($kv) === 2 && mb_strtolower(trim($kv[0])) === mb_strtolower(trim($npc)) && is_numeric(trim($kv[1]))) {
            return max(0, intval(trim($kv[1])));
        }
    }
    return max(0, intval($cfg["duty_hours"] ?? 48));
}

// ---------------------------------------------------------------- state from the game

/** "cor_state" lines from COR_Events: config|{json}, people|{json}, intimate|A,B, married|Name */
function corApplyGameState(string $data, float $now): void
{
    corLog("state " . mb_substr($data, 0, 300));
    if (preg_match('/config\|(\{.*\})/su', $data, $m)) {
        $cfg = json_decode($m[1], true);
        if (is_array($cfg)) {
            corOptSet(COR_CONFIG_KEY, $cfg);
        }
        return;
    }
    $state = corOptGet(COR_STATE_KEY) ?? [];
    if (preg_match('/people\|(\{.*\})/su', $data, $m)) {
        $p = json_decode($m[1], true);
        if (!is_array($p)) {
            return;
        }
        $state["pg"] = intval($p["pg"] ?? 0);
        foreach (($p["p"] ?? []) as $name => $info) {
            if (is_array($info)) {
                $info["seen"] = $now;
                $state["people"][$name] = $info;
            }
        }
    } elseif (preg_match('/(intimate|married)\|([^()\r\n]+)/u', $data, $m)) {
        foreach (array_filter(array_map('trim', explode(",", $m[2]))) as $name) {
            if ($m[1] === "intimate") {
                $state["intimate"][$name] = $now;
            } else {
                $state["married_at"][$name] = $now;
                $state["intimate"][$name] = $state["intimate"][$name] ?? $now;
                $state["people"][$name]["s"] = 1;
            }
        }
    } else {
        return;
    }
    corOptSet(COR_STATE_KEY, $state);
}

function corRecordDuty(string $npc, string $duty): void
{
    $state = corOptGet(COR_STATE_KEY) ?? [];
    $state["duties"][$npc] = mb_substr(trim($duty), 0, 80);
    corOptSet(COR_STATE_KEY, $state);
}

// ---------------------------------------------------------------- prompt text

function corWords(int $g, string $female, string $male): string
{
    return $g === 1 ? $female : $male;
}

function corFeelingText(array $p, string $player): string
{
    $li = intval($p["li"] ?? 0);
    $lo = intval($p["lo"] ?? 0);
    $di = intval($p["di"] ?? 0);
    $parts = [];
    if ($lo >= 20) {
        $parts[] = "you love {$player} deeply";
    } elseif ($lo >= 10) {
        $parts[] = "you are in love with {$player}";
    } elseif ($lo >= 4) {
        $parts[] = "you are falling for {$player}";
    }
    if ($li >= 20) {
        $parts[] = "you like being around {$player} very much";
    } elseif ($li >= 8) {
        $parts[] = "you like {$player}";
    }
    if ($di >= 15) {
        $parts[] = "but right now you are angry and hurt with {$player}";
    } elseif ($di >= 5) {
        $parts[] = "but {$player} has annoyed you lately";
    }
    return $parts ? ucfirst(implode(", ", $parts)) . "." : "";
}

/** Fertility Mode state (rank of _JSW_SUB_TrackedFemFaction) as something she knows about her body */
function corFertilityText(int $fm): string
{
    if ($fm >= 0) {
        if ($fm >= 100) {
            return "You are pregnant and your time is near: the baby can come any day now.";
        }
        if ($fm >= 66) {
            return "You are pregnant, in the last third of it ({$fm}% of the way): heavy, tired, the baby kicks.";
        }
        if ($fm >= 33) {
            return "You are pregnant, in the middle of it ({$fm}% of the way): your belly shows and you feel the baby move.";
        }
        return "You are pregnant, still early ({$fm}% of the way): you may feel sick in the mornings.";
    }
    if ($fm <= -85) {
        return "You gave birth not long ago and your body is still recovering.";
    }
    switch ($fm) {
        case -5:
            return "In your monthly cycle you are in the days before ovulation: your fertile time is coming soon.";
        case -15:
            return "You are ovulating right now: these are your most fertile days, the best time to conceive.";
        case -25:
            return "Your fertile days are over for this month; your period is coming.";
        case -35:
            return "You have your period right now.";
        case -75:
            return "You cannot conceive this month.";
    }
    return "";
}

function corDutyText(?float $h, int $base, string $player, string $spouseWord): string
{
    if ($h === null || $h < $base) {
        return "";
    }
    $hrs = intval(round($h));
    if ($h < 2 * $base) {
        return "It has been {$hrs} hours since {$player} last made love to you. As {$player}'s {$spouseWord} you feel you are owed it: hint at it, remind {$player} of the marital duty, in your own manner.";
    }
    if ($h < 4 * $base) {
        return "It has been {$hrs} hours since {$player} last made love to you, too long for a marriage. Ask for your marital due openly, as {$player}'s {$spouseWord}; how sweetly or how sharply depends on your character.";
    }
    return "It has been {$hrs} hours since {$player} last made love to you. You are fed up with being neglected: demand that {$player} fulfils the marital duty, now, at the first place where it is allowed - in your own way.";
}

/** everything about love, marriage and children for this agent, or "" */
function corPromptFor(string $npc, float $now): string
{
    $cfg = corConfig();
    if (empty($cfg["enabled"]) || $npc === "" || $npc === "The Narrator") {
        return "";
    }
    $state = corOptGet(COR_STATE_KEY) ?? [];
    $player = strval($GLOBALS["PLAYER_NAME"] ?? "the player");
    $pg = intval($state["pg"] ?? 0);
    $people = $state["people"] ?? [];
    $me = null;
    foreach ($people as $name => $info) {
        if (mb_strtolower($name) === mb_strtolower($npc)) {
            $me = $info;
            break;
        }
    }
    $g = intval($me["g"] ?? 1);
    $lines = [];
    $dirty = false;
    $spouse = !empty($me["s"]);
    $partner = !empty($me["pt"]);
    // the OStim bridge starts scenes and may already give this NPC a hunger for sex
    $cob = corPeer("cob_ostim_bridge");
    $cobHere = $cob !== null;
    $inLove = $spouse || $partner || intval($me["lo"] ?? 0) >= 4;

    if ($spouse && !empty($cfg["spouse_life"])) {
        $myWord = corWords($g, "wife", "husband");
        $lines[] = "You are {$player}'s {$myWord}.";
        $others = [];
        foreach ($people as $name => $info) {
            if (!empty($info["s"]) && mb_strtolower($name) !== mb_strtolower($npc)) {
                $others[] = $name;
            }
        }
        if ($others) {
            $lines[] = "{$player} has other spouses too: " . implode(", ", $others) . ". You share " . corWords($pg, "her", "him")
                . " with them and live as one household; how you feel about them (warmth, rivalry, jealousy, sisterhood) follows your own character.";
        }
        if (!empty($cfg["duties"])) {
            $duties = [];
            foreach (($state["duties"] ?? []) as $name => $duty) {
                if (!empty($people[$name]["s"])) {
                    $duties[] = "{$name}: {$duty}";
                }
            }
            if ($duties) {
                $lines[] = "Household duties the spouses have taken on: " . implode("; ", $duties) . ".";
            }
            if ($others) {
                $lines[] = "When the spouses agree on who does what at home and you take a duty on, call Take_Household_Duty with that duty in item.";
            }
        }
        $lines[] = "Once a day you can cook {$player} a homemade meal: Give_Homemade_Meal.";
        $hours = corDutyHours($npc);
        $cobHunger = $cobHere && in_array(mb_strtolower($npc), corNames(strval($cob["sex_names"] ?? "")), true);
        if (!empty($cfg["duty"]) && $hours > 0 && !$cobHunger) {
            if (!isset($state["intimate"][$npc]) && $now > 0) {
                $state["intimate"][$npc] = $now; // first sight as a spouse: start satisfied
                $dirty = true;
            }
            $t = corDutyText(corHoursSince($state["intimate"][$npc] ?? null, $now), $hours, $player, $myWord);
            if ($t !== "") {
                $lines[] = $t . ($cobHere ? " When {$player} agrees, start it with Start_Intimate_Scene." : "");
            }
        }
    } elseif ($partner) {
        $lines[] = "You and {$player} are a couple: you are " . corWords($pg, "her", "his") . " " . corWords($g, "girlfriend", "boyfriend") . ".";
        if (isset($me["mo"]) && empty($me["mo"])) {
            // ORomance's odds (MCM) would turn a proposal down right now
            $lines[] = "You are not ready to marry {$player} yet: it is too soon, your love has to grow and you need more time together. If {$player} proposes, say so in your own way - gently or teasingly - and do NOT call Marry_Player.";
        } else {
            $lines[] = "If {$player} proposes marriage and you want it, say yes and call Marry_Player in that same reply ({$player} has to wear an Amulet of Mara).";
        }
    } elseif ($me !== null) {
        if (isset($me["ao"]) && empty($me["ao"])) {
            $lines[] = "You are not ready to be {$player}'s partner yet - you do not feel that close to " . corWords($pg, "her", "him") . " yet. If {$player} asks you to be a couple or proposes marriage, say not yet in your own way, and do NOT call Become_Partner or Marry_Player.";
        } elseif (isset($me["mo"]) && empty($me["mo"])) {
            $lines[] = "If {$player} asks you to be together as a couple and you truly want it, call Become_Partner in that reply. Marriage would be too soon: you are not even a couple yet - if {$player} proposes, say in your own way that you should be together first, and do NOT call Marry_Player.";
        } else {
            $lines[] = "If {$player} asks you to be together as a couple and you truly want it, call Become_Partner in that reply. If {$player} proposes marriage and you want it, call Marry_Player.";
        }
    }

    if ($me !== null && !empty($cfg["feelings"])) {
        $lines[] = corFeelingText($me, $player);
    }
    // whom the player got engaged to or married lately - for anyone who loves them
    if ($inLove) {
        $recent = [];
        foreach (($state["married_at"] ?? []) as $name => $at) {
            $h = corHoursSince($at, $now);
            if ($h !== null && $h < 7 * 24 && mb_strtolower($name) !== mb_strtolower($npc)) {
                $recent[] = $name;
            }
        }
        if ($recent) {
            $lines[] = ($spouse
                    ? "{$player} has just taken another spouse: " . implode(", ", $recent) . "."
                    : "Lately {$player} got engaged to or married " . implode(", ", $recent) . " - not you.")
                . " How you feel about it (glad, hurt, jealous, resigned) follows your character and your feelings for {$player}.";
        }
    }
    if (!empty($cfg["affection"])) {
        $lines[] = "When something {$player} says or does truly touches you (a compliment that lands, a thoughtful gift, real care, a tender kiss, a declaration of love), call Feel_Affection with item compliment, gift, kindness, kiss or love; when {$player} insults or hurts you, call Feel_Hurt with item insult, cruelty or cheating. Only for moments that really matter, not for every line.";
    }

    if (!empty($cfg["children"])) {
        $wants = corListed("children_names", $npc);
        $fm = isset($me["fm"]) && !empty($cfg["fertility"]) ? intval($me["fm"]) : null;
        if ($wants) {
            $lines[] = "You want a child with {$player}" . ($fm !== null && $fm >= 0 ? " - and now it is coming." : ", and it is on your mind.");
        }
        if ($fm !== null && ($wants || $spouse || $partner || $fm >= 0)) {
            $t = corFertilityText($fm);
            if ($t !== "") {
                $lines[] = $t . " You know this about your body and may mention it when it matters (in bed, when " . $player . " asks, when you talk about children).";
            }
        }
        // the other women of the household who are expecting (Fertility Mode)
        if ($inLove && !empty($cfg["fertility"]) && !empty($cfg["news"])) {
            $expecting = [];
            foreach ($people as $name => $info) {
                $close = !empty($info["s"]) || !empty($info["pt"]) || intval($info["lo"] ?? 0) >= 4;
                if ($close && isset($info["fm"]) && intval($info["fm"]) >= 0 && mb_strtolower($name) !== mb_strtolower($npc)) {
                    $expecting[] = $name;
                }
            }
            if ($expecting) {
                $lines[] = "Expecting a child right now: " . implode(", ", $expecting) . ". You know it, and how you feel about it follows your character.";
            }
        }
    }

    if ($dirty) {
        corOptSet(COR_STATE_KEY, $state);
    }
    $lines = array_values(array_filter($lines, function ($l) {
        return trim($l) !== "";
    }));
    if (!$lines) {
        return "";
    }
    return "LOVE AND MARRIAGE - {$npc} (let it shape what you say and want; do not recite it):\n- " . implode("\n- ", $lines);
}

// ---------------------------------------------------------------- refused actions

/** the LLM-facing names of this bridge's actions, for the refusal event */
const COR_ACTION_NAMES = [
    "ExtCmdCOR_Affection" => "Feel_Affection",
    "ExtCmdCOR_Hurt" => "Feel_Hurt",
    "ExtCmdCOR_Partner" => "Become_Partner",
    "ExtCmdCOR_Marry" => "Marry_Player",
    "ExtCmdCOR_Duty" => "Take_Household_Duty",
    "ExtCmdCOR_Meal" => "Give_Homemade_Meal",
];

/**
 * A refused action of this bridge, as the event "cor_refused" the agent answers at once,
 * or null. The game reports every outcome as "funcret": "command@<CodeName>@<agent>~<parameter>@<result>".
 * Newer CHIM versions no longer call a plugin's FUNCRET handler for it (only an action's
 * follow-up setting, which cannot tell a refusal from a success), so a refusal would only
 * be seen in the next reply; as an event the agent says right away why it did not happen.
 * Successful actions stay a plain funcret: no extra reply.
 */
function corRefusalEvent(string $data): ?string
{
    $parts = explode("@", $data, 4);
    if (count($parts) < 4 || !isset(COR_ACTION_NAMES[$parts[1]])) {
        return null;
    }
    $result = trim($parts[3]);
    if (!preg_match('/^(cannot|refuses|nothing to)\b/i', $result)) {
        return null;
    }
    $agent = trim(explode("~", $parts[2])[0]);
    corLog("refused {$parts[1]} by {$agent}: {$result}");
    return "({$agent} tried " . COR_ACTION_NAMES[$parts[1]] . ", but it did not happen - {$result})";
}
