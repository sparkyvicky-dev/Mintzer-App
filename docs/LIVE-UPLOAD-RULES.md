# Live upload rules — do not drop server-only code

**Written:** 29 Sep 2026  
**Why:** Admin web could not reply to any support ticket. The break was not in the Reply button. A later upload of an older `routes/web.php` deleted the two reply routes.

Agents must follow this before **replacing any file** already on the server, and while fixing any bug. The ticket break was `web.php`. The same overwrite can hit a controller, a JS file, a CSS file, a blade, an image, or a file on the public website.

Two always-on Cursor rules:

| Rule file | Job |
|-----------|-----|
| `.cursor/rules/live-upload-no-regressions.mdc` | Compare every file you replace with the copy already on the server |
| `.cursor/rules/one-bug-no-second-bug.mdc` | The six rules below, so a fix does not break the next thing |

---

## What the owner saw

Tickets page, web admin, 29 Sep 2026:

| Customer | Mobile | Subject | Date | Message |
|----------|--------|---------|------|---------|
| User8715 | 9003718715 | Order Support | 29-09-2026 02:19:33 PM | tamil language call me |

Reply failed on that row and on every other support message. Changing status was a different URL and was not the thing that broke.

---

## What was actually wrong

The list loaded. These pieces on the server already matched the local copy:

| Piece | Path |
|-------|------|
| Tickets page | `newapp/resources/views/admin/customer/tickets.blade.php` |
| Reply button, thread modal, Send | `newapp/public/assets/js/admin/masters/ticket.js` |
| Load thread and save reply | `CustomerController::ticketThread` and `ticketReply` |

The live `routes/web.php` did **not** contain:

```php
Route::get('tickets/{id}/thread', [CustomerController::class, 'ticketThread'])->name('tickets.thread');
Route::post('tickets/{id}/reply', [CustomerController::class, 'ticketReply'])->name('tickets.reply');
```

Clicking Reply requested those URLs. Laravel’s fallback returned a 404. The browser showed that the reply could not be sent. Every ticket failed the same way, because the routes were gone for the whole admin, not for one user.

The list still worked because the older file still had `GET tickets` and `GET tickets-data`.

---

## How the routes disappeared

Ticket reply was added earlier and uploaded with `scripts/upload-ticket-replies-ftp.ps1`, which sends the whole `routes/web.php`.

A later fix uploaded `web.php` again from a copy that did not have the reply lines. That upload replaced the whole file. Routes that existed only in the previous live file were deleted. Routes that existed only in the uploaded copy were added. Nothing in PHP warned about the missing lines.

Same diff, 29 Sep 2026, before the repair:

| Line | Local copy | Live server before repair |
|------|------------|---------------------------|
| `GET tickets/{id}/thread` | present | **missing** |
| `POST tickets/{id}/reply` | present | **missing** |
| `POST bank/plan/{id}/{on}` → `BankController::togglePlan` | present | **missing** (method was already on the live controller) |
| `POST /send-deal-stock-alert` → `DealsController::sendDealStockAlert` | **missing** | present |

Uploading the local `web.php` as-is would have restored reply and would have **deleted** the deal-stock alert route.

`DealsController.php` is the same kind of trap. Live has `sendDealStockAlert` and `pushDealBlast`. Live `sendDealNotification` uses that newer push path. The local controller still has the older topic send and does not have `sendDealStockAlert`. Uploading the local controller would break stock alerts. That file was **not** uploaded in this repair.

There is no `php artisan route:cache` file on live. `bootstrap/cache` only has `packages.php` and `services.php` (19 Sep 2026). Laravel reads `web.php` on each request. `storage/logs/laravel.log` had not grown since 24 Sep 2026, so this 404 was not sitting in that log. The proof was the live `web.php` itself.

The one-shot `public/v3_ticket_replies_migrate_once.php` is no longer in `public/` on the server. That only means the script was removed after it ran. It does not mean the replies table is gone. Reply failed because of routes, not because the table was missing.

---

## What was uploaded on 29 Sep 2026

One file: `newapp/routes/web.php`.

Merge used for the upload:

- Kept the ticket thread and ticket reply routes from local.
- Kept `POST bank/plan/{id}/{on}` from local, because `togglePlan` was already on the live `BankController`.
- Copied `POST /send-deal-stock-alert` from the live file into the local file before upload, so the stock-alert route stayed.

After upload, the same path was downloaded again. These four lines were on the server:

- `GET tickets/{id}/thread`
- `POST tickets/{id}/reply`
- `POST bank/plan/{id}/{on}`
- `POST /send-deal-stock-alert`

No app build. No `DealsController` upload. No Flutter change.

Admin: refresh the Tickets page, open **Reply** on the row, send. The customer sees it in the app thread. Push and bell use the code already in `ticketReply`.

---

## Rules — stop the next one

Do this for **every file you replace** on the server. Not only `web.php`. Not only controllers. PHP, routes, blade, JS, CSS, images, fonts, and files under `public_html` outside `newapp` (the website, `beta`) follow the same steps.

A path that does not exist on the server yet is a new file. Upload it. There is nothing to merge.

A path that already exists is a replace. Compare first, in this session, then upload.

1. **Download the live file first.** Server root is `/domains/mintzer.in/public_html/` (for the app, add `newapp/` and the same relative path as in the repo). Login details are in `mintzer.in/fpt details.txt`. Never print the password. Never upload or commit `.env` or `Sen Info`.
2. **Compare.**
   - Text: diff live against the file you plan to upload. List every block that exists only on the server and every block that exists only locally. Routes, methods, config keys, query strings, CSS rules, and copy all count.
   - Binary (image, font, archive): compare size and hash, and the live file date. If they differ, do not overwrite. A newer live image replaced by an older local one is the same class of bug.
3. **Merge text.** The file you upload must still contain every server-only change. Remove a block only when the owner named that block and asked for it to go. If the two copies cannot be merged safely, stop and say what differs. Do not pick one whole file and hope.
4. **Upload that merged file only.** Scripts in `scripts/upload-*.ps1` send whole files and do not merge. Run the compare for **each path** in the list before the script runs. Do not skip a file because it “should be the same”.
5. **Download the same path again** and confirm both the change you added and the server-only parts you were required to keep.
6. **A screen that still loads is not proof the rest of that file survived.** The Tickets list still worked after reply routes were deleted. After a replace, check the part you did not mean to touch.
7. **Known older local copy:** do not replace live `DealsController.php` until `sendDealStockAlert` and `pushDealBlast` are in the local file and `sendDealNotification` matches the live push path. Treat any other file the same way when the diff shows the server is ahead.
8. **Do not treat a deleted one-shot script as proof a feature was never installed.**
9. **If the owner says a new bug appeared while something else was fixed,** diff the file that was just replaced against what the server had. The missing lines are the bug.

---

## Six rules — do not create a second bug

Cursor rule (always on, every chat): `.cursor/rules/one-bug-no-second-bug.mdc`.

It is separate from compare-before-replace (`.cursor/rules/live-upload-no-regressions.mdc`). One file was holding both jobs. That crosses the one-rule-one-job limit, so they are split. Both stay on even when the open files are Flutter-only or docs-only, because a fix can still upload a server file later in the same chat.

Comparing files stops an overwrite from deleting live code. These six stop the other ways a fix breaks something that already worked. They apply to `newapp`, the website, `beta`, and the Flutter app.

### 1. Start from the live file

Download the file that is on the server. Add only the lines for this bug.

On 29 Sep the repo copy of `web.php` was not the server copy. Uploading the repo copy would have deleted `POST /send-deal-stock-alert`. The repair started from the downloaded live file and added the missing reply routes onto it.

Done when the uploaded file is that downloaded file plus the fix, not an old repo file sent whole.

### 2. One bug, one edit

Leave every other function, route, query, label, and screen as it was. No cleanup, no rename, no restyle in the same change. Locked screens stay locked (`AGENTS.md`).

The reply break was not a bad Reply button. Extra lines in a shared file were replaced. A second edit inside the same file can do that again.

Done when the diff for this fix shows only the lines that make this bug go away.

### 3. Upload only the files that contain that fix

If the bug is in one JS file, send that file. Leave `web.php`, controllers, and the other paths in `scripts/upload-*.ps1` out of this upload.

`scripts/upload-ticket-replies-ftp.ps1` sends `web.php` plus several controllers every time. A later run of a script like that is how an older `web.php` landed on the server and removed reply.

Done when the upload list is the files you actually changed for this bug, and you compared each one that already existed on the server.

### 4. If the server copy is ahead, leave it there

When the diff shows live code the local file does not have, do not upload the local file to fix something else. Edit the downloaded live copy, or fix a different file.

`DealsController.php` is already in this state. Live has `sendDealStockAlert` and `pushDealBlast`. The local `sendDealNotification` is the older topic send. It was not uploaded on 29 Sep.

Done when any file that is ahead on the server is either left untouched or edited from the downloaded copy.

### 5. Use the broken action and the action beside it

A page that loads is not the test. The Tickets list still showed User8715 after Reply was dead, because `GET tickets` was still in the old `web.php` and `GET tickets/{id}/thread` was not.

| You changed | Use this | And the one beside it |
|-------------|----------|------------------------|
| Ticket reply | Tickets → Reply → Send on a real row | Status dropdown on that row still saves |
| A deal | Open that deal in admin and in the app | Stock alert still sends |
| An order | The status or field you changed | Cancel, and the next status, still work |
| App screen | The button or field you fixed | The next screen that reads the same order, deal, or ticket |

Done when you have used both, or you tell the owner which one you could not use and why.

### 6. Do not delete a route, method, column, or button because it looks unused

The reply routes were absent from an older file. They were in use. `ticket-status-update` stayed, so status still looked fine and reply did not.

Remove a route, method, column, or button only when the owner named that one and asked for it to go.

Done when the diff does not drop a symbol you did not mean to remove. After upload, download the file again and check those symbols are still there.

### Before you call it done

Tell the owner, in the same reply: which files were uploaded or changed, and which beside-action from rule 5 you used.

---

## Files that already diverged (29 Sep 2026)

| File | Safe to upload from local as-is? |
|------|-----------------------------------|
| `routes/web.php` | Only after a fresh diff. As of this repair, local and live match on the four routes above. |
| `app/Http/Controllers/Admin/Masters/DealsController.php` | **No.** Live is ahead. See rule 7. |
| `app/Http/Controllers/Admin/Customer/CustomerController.php` | Matched live on 29 Sep 2026. Diff again before the next upload. |
| `public/assets/js/admin/masters/ticket.js` | Matched live on 29 Sep 2026. |
| `resources/views/admin/customer/tickets.blade.php` | Matched live on 29 Sep 2026. |
