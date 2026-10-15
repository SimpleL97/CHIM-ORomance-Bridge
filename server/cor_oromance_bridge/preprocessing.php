<?php

/**
 * CHIM ORomance Bridge by SaurOff - runs before CHIM logs a request or takes its lock.
 *
 *   cor_state   silent bookkeeping from COR_Events (config, people, intimate, married):
 *               stored and answered here, never reaches the history or the LLM.
 */

require_once(__DIR__ . DIRECTORY_SEPARATOR . "cor_lib.php");

if (isset($gameRequest) && is_array($gameRequest) && strval($gameRequest[0] ?? "") === "cor_state") {
    try {
        // CHIM splits every request on "|" (main.php: explode("|", ...)), and the state
        // lines use "|" themselves: glue everything after the third field back
        corApplyGameState(implode("|", array_slice($gameRequest, 3)), corNow());
    } catch (Throwable $e) {
        error_log("[cor_oromance_bridge] preprocessing: " . $e->getMessage());
    }
    terminate();
}
