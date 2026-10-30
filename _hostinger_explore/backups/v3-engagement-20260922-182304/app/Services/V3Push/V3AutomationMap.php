<?php

namespace App\Services\V3Push;

/**
 * V3 automation map — event → push. No admin "click to send".
 * V2 cron / HolderNotify / topic / manual bell stay untouched.
 *
 * Wired now:
 *  - deal.live          → auto on admin deal create (DealsController@store)
 *  - deal.catalog       → admin status toggle + deal edit (Home instant refresh)
 *
 * Already covered for same users via existing V2 HolderNotify → users.fcm_token
 * (Flutter also writes that column). Prefer migrating these onto V3PushGateway later
 * so prefs/caps apply — without deleting V2 sends until V3 Play replaces V2:
 *  - invoice / tracking / OTP / payout / cancel (HolderNotifyService)
 *  - placement Order ID reminders (CronjobController)
 *
 * Next V3-native automations (gateway + outbox):
 *  - deal.viewed_followup_*   (client dwell events)
 *  - deal.accept_abandoned_*  (placement started, no Order ID)
 *  - placement.timer_warning  (5m / 1m)
 *  - order.confirmed / parcel_received / payment_approved
 *  - quiet-hours drain worker
 */
class V3AutomationMap
{
    // Documentation-only marker class for agents / ops.
}
