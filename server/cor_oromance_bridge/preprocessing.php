<?php

/**
 * CHIM ORomance Bridge by SaurOff - runs before CHIM logs a request or takes its lock.
 *
 *   funcret     a refused action of this bridge becomes the event cor_refused, which the
 *               agent answers at once (successful ones stay as they are).
 *   cor_state   silent bookkeeping from COR_Events (config, people, intimate, married):
 *               stored and answered here, never reaches the history or the LLM.
 */

require_once(__DIR__ . DIRECTORY_SEPARATOR . "cor_lib.php");

// a refused action of this bridge: answered at once, as the event cor_refused (cor_lib.php)
if (isset($gameRequest) && is_array($gameRequest) && strval($gameRequest[0] ?? "") === "funcret") {
    try {
        $corRefusal = corRefusalEvent(strval($gameRequest[3] ?? ""));
        if ($corRefusal !== null) {
            $gameRequest[0] = "cor_refused";
            $gameRequest[3] = $corRefusal;
        }
    } catch (Throwable $e) {
        error_log("[cor_oromance_bridge] refusal: " . $e->getMessage());
    }
}

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
