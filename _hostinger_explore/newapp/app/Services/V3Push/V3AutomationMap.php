<?php

namespace App\Services\V3Push;

/**
 * V3 automation map — event → push. No admin "click to send".
 * V2 cron / HolderNotify / topic / manual bell stay untouched.
 *
 * Wired:
 *  - deal.live              → admin deal create (template bank)
 *  - deal.relist            → admin status OFF→ON
 *  - deal.catalog           → edit / status OFF (Home refresh)
 *  - deal.viewed_followup_* → POST /v3/push/deal-view (dwell ≥15s)
 *  - deal.still_live        → cron tick (day 2–3+)
 *  - outbox drain           → cron tick (scheduled + quiet)
 *
 * Templates: resources/v3_push/templates.json OR v3_push_templates table
 * → change copy without APK.
 */
class V3AutomationMap
{
    // Documentation-only marker class for agents / ops.
}
