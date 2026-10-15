<?php

/**
 * CHIM ORomance Bridge by SaurOff - actions.
 *
 * The LLM-facing action definitions live in CHIM's core_action_custom table, so they can
 * be toggled in the CHIM UI like any other action. This file installs or updates them
 * once per definition change, rewrites outgoing parameters into the shape the game
 * script expects, and shapes the follow-up prompt after the game reports back.
 */

require_once(__DIR__ . DIRECTORY_SEPARATOR . "cor_lib.php");

$GLOBALS["COR_ACTIONS"] = [
    "ExtCmdCOR_Affection" => [
        "name" => "Feel_Affection",
        "return" => "#HERIKA_NAME# feels closer to #PLAYER_NAME#.",
        "params" => [
            "target" => "leave empty",
            "item" => "What touched you: compliment, gift, kindness, kiss or love.",
        ],
        "description" => "Something #PLAYER_NAME# just said or did truly touched your heart: a compliment that lands, a thoughtful gift, real care or kindness, a tender kiss, a declaration of love. Call this so that it counts in your relationship. "
            . "Only for moments that genuinely move you - not for every friendly line, not more than once for the same moment, and never just because you were asked to call it.",
    ],
    "ExtCmdCOR_Hurt" => [
        "name" => "Feel_Hurt",
        "return" => "#HERIKA_NAME# is hurt by #PLAYER_NAME#.",
        "params" => [
            "target" => "leave empty",
            "item" => "What hurt you: insult, cruelty or cheating.",
        ],
        "description" => "#PLAYER_NAME# just hurt you: an insult, cruelty or coldness, or you caught them cheating on you. Call this so that it counts in your relationship. Only when it really stings, not for teasing you enjoy.",
    ],
    "ExtCmdCOR_Partner" => [
        "name" => "Become_Partner",
        "return" => "#HERIKA_NAME# agrees to be with #PLAYER_NAME#.",
        "params" => ["target" => "leave empty"],
        "description" => "Become #PLAYER_NAME#'s partner (girlfriend or boyfriend) for real in the game: #PLAYER_NAME# has asked you to be together, or you confessed your feelings and #PLAYER_NAME# said yes, and you truly want it. "
            . "Not if you already are a couple or married. Saying yes in words alone changes nothing in the game - call this action in that same reply.",
    ],
    "ExtCmdCOR_Marry" => [
        "name" => "Marry_Player",
        "return" => "#HERIKA_NAME# says yes to marrying #PLAYER_NAME#.",
        "params" => ["target" => "leave empty"],
        "description" => "Marry #PLAYER_NAME# for real in the game: you say yes to their proposal, or they have just said yes to yours. ONLY when #PLAYER_NAME# has clearly asked you to marry them (or clearly accepted your proposal) and you truly want it - never on your own, never as a joke or a tease, not in combat. "
            . "#PLAYER_NAME# has to wear an Amulet of Mara. The first spouse is engaged and married at the Temple of Mara in Riften; anyone after that is married at once. Saying yes in words alone marries nobody - call this action in that same reply.",
    ],
    "ExtCmdCOR_Duty" => [
        "name" => "Take_Household_Duty",
        "return" => "#HERIKA_NAME# takes on a household duty.",
        "params" => [
            "target" => "leave empty",
            "item" => "The duty in a few words, e.g. cooking, cleaning, keeping the house, guarding the house at night, shopping, looking after the children.",
        ],
        "description" => "ONLY if you are married to #PLAYER_NAME#: you take on a household duty, usually as agreed with the other spouses or with #PLAYER_NAME#. It replaces the duty you had before. Call it when the duty is actually agreed, not while still arguing about it.",
    ],
    "ExtCmdCOR_Meal" => [
        "name" => "Give_Homemade_Meal",
        "return" => "#HERIKA_NAME# gives #PLAYER_NAME# a homemade meal.",
        "params" => ["target" => "leave empty"],
        "description" => "ONLY if you are married to #PLAYER_NAME#: give them a homemade meal you cooked (once a day). Call it when you offer food or #PLAYER_NAME# asks for something to eat.",
    ],
];

foreach ($GLOBALS["COR_ACTIONS"] as $code => $def) {
    $GLOBALS["F_NAMES"][$code] = $def["name"];
}

// ---------------------------------------------------------------- install / update

(function () {
    $db = $GLOBALS["db"] ?? null;
    if (!$db) {
        return;
    }
    try {
        // version + fingerprint of the definitions above: any change to an action's name,
        // description or parameters is written to CHIM's table, not only a version bump
        $stamp = COR_VERSION . "-" . md5(json_encode($GLOBALS["COR_ACTIONS"]));
        $mark = $db->fetchOne("SELECT value FROM conf_opts WHERE id = 'cor_oromance_bridge_installed'");
        if (!empty($mark) && strval($mark["value"] ?? "") === $stamp) {
            return;
        }
        foreach ($GLOBALS["COR_ACTIONS"] as $code => $def) {
            $props = [];
            foreach ($def["params"] as $p => $desc) {
                $props[$p] = ["type" => "string", "description" => $desc];
            }
            $params = json_encode(["type" => "object", "required" => [], "properties" => $props], JSON_UNESCAPED_SLASHES);
            $row = $db->fetchOne("SELECT id FROM core_action_custom WHERE code_name = $1", [$code]);
            if (!empty($row)) {
                $db->fetchOne(
                    "UPDATE core_action_custom SET action_name = $2, description = $3, return_message = $4, parameters_json = $5::jsonb, updated_at = now() WHERE code_name = $1 RETURNING id",
                    [$code, $def["name"], $def["description"], $def["return"], $params]
                );
                continue;
            }
            $clash = $db->fetchOne("SELECT code_name FROM core_action_custom WHERE action_name = $1", [$def["name"]]);
            if (!empty($clash)) {
                error_log("[cor_oromance_bridge] action name {$def['name']} is already used by {$clash['code_name']}; not installing {$code}");
                continue;
            }
            $db->fetchOne(
                "INSERT INTO core_action_custom (code_name, action_name, description, return_message, available_to_npc, available_to_followers, available_to_narrator, is_activated, parameters_json, metadata, game_function, import_version, script_proxy_program, created_at, updated_at)"
                . " VALUES ($1, $2, $3, $4, true, true, false, true, $5::jsonb, '{}'::jsonb, true, 0, '{}'::jsonb, now(), now()) RETURNING id",
                [$code, $def["name"], $def["description"], $def["return"], $params]
            );
        }
        $db->upsertRowOnConflict("conf_opts", ["id" => "cor_oromance_bridge_installed", "value" => $stamp], "id");
        error_log("[cor_oromance_bridge] actions installed/updated for " . $stamp);
    } catch (Throwable $e) {
        error_log("[cor_oromance_bridge] install: " . $e->getMessage());
    }
})();

// ---------------------------------------------------------------- outgoing parameters

/**
 * CHIM sends "<npc>|command|<Action_Name>@<parameter>" to the game; the Papyrus side
 * gets "<agent>~<item>" ("-" for an empty item: CHIM's command queue crashes on a
 * parameter that ends with an empty field).
 */
$GLOBALS["action_post_process_fnct_ex"][] = function ($actions) {
    if (!is_array($actions)) {
        return $actions;
    }
    foreach ($actions as $n => $action) {
        try {
            $parts = explode("|", strval($action));
            if (count($parts) < 3) {
                continue;
            }
            $call = explode("@", $parts[2], 2);
            $actionName = $call[0];
            $codeName = function_exists('getFunctionCodeName') ? getFunctionCodeName($actionName) : false;
            if ($codeName === false || trim(strval($codeName)) === '') {
                $codeName = $actionName;
            }
            if (!isset($GLOBALS["COR_ACTIONS"][$codeName])) {
                continue;
            }
            $actorName = trim($parts[0]);
            $parameter = isset($call[1]) ? trim($call[1]) : "";
            $item = "";
            if ($parameter !== "" && $parameter[0] === "{" && function_exists('decodeFunctionExecutionParameterPayload')) {
                $payload = decodeFunctionExecutionParameterPayload($parameter);
                if (is_array($payload)) {
                    $item = trim(strval($payload["item"] ?? ""));
                    if ($item === "") {
                        $item = trim(strval($payload["target"] ?? ""));
                    }
                }
            } else {
                $item = $parameter;
            }
            // "~" separates the fields on the Papyrus side; "|" separates the action line itself
            $item = trim(str_replace(["~", "|"], " ", $item));
            $parts[2] = $actionName . "@" . $actorName . "~" . ($item === "" ? "-" : mb_strtolower($item));
            $actions[$n] = implode("|", $parts);
        } catch (Throwable $e) {
            error_log("[cor_oromance_bridge] post_process: " . $e->getMessage());
        }
    }
    return $actions;
};

// ---------------------------------------------------------------- after the game reports back

$corFuncret = function ($gameRequest) {
    // data: "command@<CodeName>@<parameter>@<result sentence>"
    $data = is_array($gameRequest) ? strval($gameRequest[3] ?? "") : "";
    $herika = $GLOBALS["HERIKA_NAME"] ?? "";
    $GLOBALS["FORCE_MAX_TOKENS"] = 120;

    if (strpos($data, "ExtCmdCOR_Duty") !== false && preg_match('/@([^@~]+)~[^@]*@[^@]*takes on the household duty: (.+)$/u', $data, $m)) {
        corRecordDuty(trim($m[1]), trim($m[2]));
    }
    $refused = (stripos($data, "refuses") !== false) || (stripos($data, "cannot") !== false) || (stripos($data, "nothing to ") !== false);
    if ($refused) {
        $reason = $data;
        $cut = strrpos($data, "@");
        if ($cut !== false) {
            $reason = trim(substr($data, $cut + 1));
        }
        return [
            "argName" => "target",
            "request" => "{$herika} wanted this but it did not happen: {$reason}. Say one short line in character about it and drop the subject. Do not try the same action again this turn.",
        ];
    }
    return ["argName" => "target"];
};
foreach (array_keys($GLOBALS["COR_ACTIONS"]) as $code) {
    $GLOBALS["FUNCRET"][$code] = $corFuncret;
}
