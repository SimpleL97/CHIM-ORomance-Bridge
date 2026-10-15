<?php

/**
 * CHIM ORomance Bridge by SaurOff - text added at the bottom of every prompt: what the
 * agent feels for the player, partner or spouse life (other spouses, household duties,
 * marital duty), wanting children and where she is in her cycle (Fertility Mode), and
 * when to use this mod's actions. Loaded by main.php before the prompt_bottom slot.
 */

require_once(__DIR__ . DIRECTORY_SEPARATOR . "cor_lib.php");

if (function_exists('chimRegisterPromptInjection')) {
    chimRegisterPromptInjection("prompt_bottom", "cor_love", function ($slot, $context) {
        try {
            return corPromptFor(trim(strval($GLOBALS["HERIKA_NAME"] ?? "")), corNow());
        } catch (Throwable $e) {
            error_log("[cor_oromance_bridge] prompt: " . $e->getMessage());
            return "";
        }
    }, 810);
}
