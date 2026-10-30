# V3 push — deploy notes (engagement engine)

## Templates without APK

Yes. Copy lives on the **server**:

1. **Default:** `newapp/resources/v3_push/templates.json` (540 variants from locked banks)
2. **Override without FTP of JSON:** insert rows into `v3_push_templates` (`bank`, `title`, `body`, `active=1`). DB wins when that bank has active rows.

Flutter only shows title/body from FCM — never embeds commercial banks.

Re-export JSON from docs:

```
python docs/design/_export_banks_json.py
```

Then upload `templates.json` via FTP.

## SQL

Run additive SQL: `docs/backend- for developer reference/v3_push_engine.sql`  
(new: `v3_push_deal_views`, `v3_push_templates`)

## Files to upload (FTP)

- `app/Services/V3Push/*` (all)
- `app/Http/Controllers/API/Push/V3PushController.php`
- `app/Http/Controllers/Admin/Masters/DealsController.php` (relist)
- `app/Http/Controllers/API/Order/OrderController.php` (cancel follow-ups on Accept)
- `app/Http/Controllers/CronjobController.php` (drain + still-live tick)
- `routes/api.php`
- `resources/v3_push/templates.json`

## Cron

Existing `cron-jobs` now also drains outbox + still-live.  
Or hit: `GET https://app.mintzer.in/api/v3/push/tick?key=mintzer-v3-tick` every 5–15 min.  
Prefer env `MINTZER_V3_CRON_SECRET` + header `X-Mintzer-V3-Cron`.

## Behavior

| Event | Push |
|-------|------|
| Deal create | `deal.live` (bank random live/funny) |
| Status OFF→ON | `deal.relist` |
| Status ON→OFF / edit | `deal.catalog` (refresh) |
| View ≥15s · leave | schedule early 30–60m + mid ~1.5h |
| Accept | cancel pending view follow-ups |
| Deal live ≥24h | still-live every ~8h (day 2–5) |

Caps: ~12 commercial/day · 25 min gap · live/relist skip quiet hours.
