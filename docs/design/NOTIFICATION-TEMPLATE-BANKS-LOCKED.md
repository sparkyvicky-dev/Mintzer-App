# Mintzer — Push template banks (100 each) · LOCKED

**Parent:** [NOTIFICATION-TEMPLATES-LOCKED.md](./NOTIFICATION-TEMPLATES-LOCKED.md) (short rules + job map)  
**Easy-read:** NOTIFICATION-TEMPLATE-BANKS.html in Brave.

Rotate **one random row** per send. Tokens: {product} {store} {earn} {spend} {ref} {expiry} {endsAt} {n} {amount} {preview} {card}

## Banks

**Tokens:** {product} {store} {earn} {spend} {ref} {expiry} {endsAt} {n} {amount} {preview} {reason} {card}

**Send rule:** pick **one random row** per fire. Soft/firm both OK inside a bank.


**Rule:** Every operational / deal push type below has **≥ 100** title+body variants with emojis. Rotate randomly per send. Soft/firm pairs included where useful.

**Tokens:** `{product}` `{store}` `{earn}` `{spend}` `{ref}` `{expiry}` `{endsAt}` `{n}` `{amount}` `{preview}` `{reason}` `{card}`

**Tone reminder:** OTP / tracking / invoice / payout = clear + human. Deal funny bank = screenshot-worthy. Never joke on payout failure.

| Type | Count |
|------|-------|
| `otp` | 100 |
| `tracking` | 100 |
| `order_id` | 100 |
| `invoice_needed` | 100 |
| `invoice_reupload` | 100 |
| `invoice_verified` | 100 |
| `payment_verified` | 100 |
| `payout_sent` | 100 |
| `deal_live` | 100 |
| `deal_funny` | 100 |
| `tracking_done` | 100 |
| `ticket_reply` | 100 |
| `timer_5m` | 100 |
| `timer_1m` | 100 |

### 3.1 OTP pending / update (100 variants)

When delivery needs OTP from holder.

| # | Title | Body |
|---|-------|------|
| 1 | `Delivery partner waiting 🚚` | `Share OTP for Order {ref} so delivery can finish.` |
| 2 | `OTP needed now 🔐` | `Rider is at the door for {product}. Update OTP in Mintzer.` |
| 3 | `Almost delivered 📦` | `One OTP away on Order {ref}. Tap and share.` |
| 4 | `Final step: OTP ⚡` | `Order {ref} can’t complete without OTP + mobile.` |
| 5 | `Hey — OTP please 😊` | `Delivery for {product} is waiting on your OTP.` |
| 6 | `Rider says hi 🛵` | `Update OTP for Order {ref} to hand over the parcel.` |
| 7 | `Don’t leave them hanging ⏳` | `OTP pending for Order {ref}. Share it now.` |
| 8 | `Out for delivery needs you 📲` | `Add OTP for {product} · Order {ref}.` |
| 9 | `Quick OTP update 🔑` | `Order {ref} is ready to complete. OTP please.` |
| 10 | `Parcel + OTP = done ✅` | `Share OTP for Order {ref} and we’re finished.` |
| 11 | `Delivery in progress 🏃‍♂️` | `OTP still missing for Order {ref}. Update now.` |
| 12 | `One tap left 👆` | `Enter OTP for {product} so the rider can leave happy.` |
| 13 | `Friendly nudge 🔔` | `OTP pending · Order {ref} · {product}.` |
| 14 | `Almost there! 🎯` | `Just OTP for Order {ref} — then relax.` |
| 15 | `Doorstep moment 🚪` | `Share OTP now for Order {ref}.` |
| 16 | `Mobile + OTP 📱` | `Update both if needed for Order {ref}.` |
| 17 | `Complete delivery 🏁` | `OTP unlocks handover for {product}.` |
| 18 | `Waiting room closed soon 😅` | `Please share OTP for Order {ref} ASAP.` |
| 19 | `Rider clock is ticking ⏱️` | `OTP for Order {ref} — make it quick.` |
| 20 | `Hand it over 🤝` | `OTP needed to finish Order {ref}.` |
| 21 | `Last mile = you 🛣️` | `Share OTP · Order {ref} · {product}.` |
| 22 | `No OTP, no bye-bye 👋` | `Update OTP for Order {ref} to complete delivery.` |
| 23 | `Smooth finish please ✨` | `OTP for {product} is all that’s left.` |
| 24 | `Delivery partner online 🟢` | `They’re waiting on OTP for Order {ref}.` |
| 25 | `Tap → OTP → done 💫` | `Order {ref} needs your OTP now.` |
| 26 | `Don’t ghost the rider 👻` | `Share OTP for Order {ref}.` |
| 27 | `OTP o’clock 🕒` | `Update OTP for {product} · Order {ref}.` |
| 28 | `Handover locked 🔒` | `Unlock with OTP · Order {ref}.` |
| 29 | `We believe in you 💪` | `One OTP for Order {ref} and you’re done.` |
| 100 | `Finish strong 🏅` | `Share OTP for Order {ref} — last step!` |

### 3.2 Tracking ID needed (100 variants)

When shipping/AWB is missing.

| # | Title | Body |
|---|-------|------|
| 1 | `Tracking ID needed 📦` | `{product} · Order {ref} can’t move without tracking.` |
| 2 | `Shipping update pending 🚚` | `Add tracking ID for Order {ref} now.` |
| 3 | `Dispatch waiting ⏳` | `Order {ref} needs tracking to continue delivery.` |
| 4 | `Action needed: tracking ⚡` | `Submit tracking ID for {product} · Order {ref}.` |
| 5 | `Where’s the tracking? 👀` | `Add shipping ID for Order {ref}.` |
| 6 | `Order stuck without AWB 📌` | `Update tracking for Order {ref} to unstick it.` |
| 7 | `Courier ID please 🏷️` | `Tracking missing for {product} · Order {ref}.` |
| 8 | `Move the parcel forward ➡️` | `Add tracking ID for Order {ref}.` |
| 9 | `Shipping details due 📝` | `Order {ref} is waiting on your tracking ID.` |
| 10 | `Quick tracking reminder 🔔` | `Please add tracking for {product}.` |
| 11 | `Accepted ✅ · Tracking ❓` | `Order {ref} needs the shipping ID next.` |
| 12 | `Don’t delay dispatch 🚀` | `Update tracking ID for Order {ref}.` |
| 13 | `AWB unlocks next step 🔓` | `Add tracking for Order {ref}.` |
| 14 | `Courier link missing 🔗` | `Paste tracking ID for {product} · Order {ref}.` |
| 15 | `Delivery flow paused ⏸️` | `Tracking ID required for Order {ref}.` |
| 16 | `Ship it on paper too 📄` | `Enter tracking for Order {ref}.` |
| 17 | `Ops is waiting 🛎️` | `Add tracking ID for Order {ref} when you have it.` |
| 18 | `Tracking = progress 📈` | `Update Order {ref} with shipping ID.` |
| 19 | `One field left ✍️` | `Tracking ID for {product} · Order {ref}.` |
| 20 | `Help the parcel travel ✈️` | `Add tracking for Order {ref}.` |
| 21 | `No tracking, no updates 📡` | `Submit tracking ID for Order {ref}.` |
| 22 | `Store shipped? Tell us 🛍️` | `Add tracking for Order {ref}.` |
| 23 | `Tracking reminder soft 🌤️` | `Whenever ready — Order {ref} needs AWB.` |
| 24 | `Tracking reminder firm 🔥` | `Order {ref} still missing tracking ID. Update now.` |
| 25 | `Keep momentum 🏃‍♂️` | `Add tracking for {product} so we can follow it.` |
| 26 | `Shipping ID alert 🚨` | `Order {ref} · please update tracking.` |
| 27 | `Parcel map needs a pin 📍` | `Tracking ID for Order {ref}.` |
| 28 | `We’re ready when you are 🙌` | `Add tracking for Order {ref}.` |
| 29 | `Close the loop 🔁` | `Tracking ID completes this step · Order {ref}.` |
| 100 | `Next stop: tracking 🏁` | `Update Order {ref} with courier tracking ID.` |

### 3.11 Tracking ID received (ack) (100 variants)

Optional confirm after user adds tracking.

| # | Title | Body |
|---|-------|------|
| 1 | `Tracking added ✅` | `Order {ref} shipping ID saved. We’ll follow it.` |
| 2 | `You’re tracked 📦` | `Tracking live for {product} · Order {ref}.` |
| 3 | `Shipping ID received 🚚` | `Order {ref} updated. Nice.` |
| 4 | `AWB locked in 🔒` | `Tracking for Order {ref} is on file.` |
| 5 | `Parcel is followable now 📍` | `Order {ref} · tracking saved.` |
| 6 | `Dispatch details in ✅` | `Thanks — Order {ref} tracking updated.` |
| 7 | `On the map 🗺️` | `Tracking ID for Order {ref} received.` |
| 8 | `Courier linked 🔗` | `Order {ref} · {product}.` |
| 9 | `Shipping step complete ✔️` | `Order {ref} tracking added.` |
| 10 | `We can see it moving 👀` | `Tracking saved · Order {ref}.` |
| 11 | `Good update 🔔` | `Tracking ID in for Order {ref}.` |
| 12 | `Parcel status unlocked 🔓` | `Order {ref}.` |
| 13 | `Tracking confirmed 👍` | `{product} · Order {ref}.` |
| 14 | `AWB appreciated 🙏` | `Order {ref} updated.` |
| 15 | `Shipping ping saved 📡` | `Order {ref}.` |
| 16 | `Next: keep an eye on delivery 👀` | `Tracking · Order {ref}.` |
| 17 | `Logged ✅` | `Tracking for Order {ref}.` |
| 18 | `Courier ID captured 🏷️` | `Order {ref}.` |
| 19 | `Smooth — tracking in ✨` | `Order {ref}.` |
| 20 | `Step complete 🏁` | `Tracking added · Order {ref}.` |
| 21 | `You’re ahead of the curve 📈` | `Tracking · Order {ref}.` |
| 22 | `Delivery story started 📖` | `Order {ref} tracking live.` |
| 23 | `All set on shipping ID 🟢` | `Order {ref}.` |
| 24 | `Noted by Mintzer 📝` | `Tracking · Order {ref}.` |
| 25 | `Update successful 💫` | `Order {ref} tracking.` |
| 26 | `Parcel breadcrumbs set 🍞` | `Tracking · Order {ref}.` |
| 27 | `Thanks for the AWB 🙌` | `Order {ref}.` |
| 28 | `Shipping checklist ✅` | `Tracking done · Order {ref}.` |
| 29 | `Moved to in-transit watch 👀` | `Order {ref}.` |
| 100 | `Tracking = done for now 🎯` | `Order {ref} · {product}.` |

### 3.3 Store Order ID needed (100 variants)

**Job B — after Accept.** User has an active placement / Place order screen; Store Order ID not submitted yet.

**Tap opens:** `mintzer://accept/:placementId` → **Place order** (timer + paste Order ID). If order row already exists, `mintzer://orders/:orderId`.

**Copy rule:** Title = urgency/hook · Body = `{product}` + paste Order ID + `{expiry}` when known. Never “open the app” with no order context.

| # | Title | Body |
|---|-------|------|
| 1 | `Add Store Order ID 🧾` | `Order {ref} needs Flipkart/Amazon Order ID before {expiry}.` |
| 2 | `Order ID pending ⏳` | `Paste Store Order ID for {product} · deadline {expiry}.` |
| 3 | `Don’t miss the window ⏲️` | `Update Order ID for {ref} before {expiry}.` |
| 4 | `Accepted — now the ID 📌` | `Add Store Order ID for Order {ref}.` |
| 5 | `Checkout done? Prove it ✅` | `Enter Store Order ID for {product}.` |
| 6 | `OID update needed 🔢` | `Order {ref} is waiting for Store Order ID.` |
| 7 | `Quick Order ID reminder 🔔` | `Add it before {expiry} · Order {ref}.` |
| 8 | `Lock the placement 🔐` | `Store Order ID for {product} before {expiry}.` |
| 9 | `Timer hates empty IDs 😱` | `Update Order ID for Order {ref} now.` |
| 10 | `One paste away 📋` | `Store Order ID · Order {ref} · before {expiry}.` |
| 11 | `Finish Accept flow ✨` | `Add Order ID for {product}.` |
| 12 | `Store receipt = OID 🧾` | `Enter Store Order ID for Order {ref}.` |
| 13 | `We can’t track air 🌬️` | `Need Store Order ID for Order {ref}.` |
| 14 | `Before auto-cancel ⚠️` | `Add OID for Order {ref} by {expiry}.` |
| 15 | `Deal accepted — ID next ➡️` | `Store Order ID for {product}.` |
| 16 | `OID o’clock 🕒` | `Update Order {ref} with Store Order ID.` |
| 17 | `Copy from store app 📱` | `Paste Order ID into Mintzer · Order {ref}.` |
| 18 | `Almost placed 💪` | `Only Store Order ID left for Order {ref}.` |
| 19 | `Save this deal 🛟` | `Add OID before {expiry} · Order {ref}.` |
| 20 | `ID or it didn’t happen 📷` | `Enter Store Order ID for {product}.` |
| 21 | `Placement incomplete 🧩` | `Order {ref} needs Store Order ID.` |
| 22 | `Beat the clock 🏁` | `OID for Order {ref} due by {expiry}.` |
| 23 | `Friendly OID nudge 😊` | `Got the Store Order ID for {product}? Add it.` |
| 24 | `Firm OID nudge ⚡` | `Order {ref} still missing Store Order ID — update now.` |
| 25 | `Amazon/FK number please 🛍️` | `Paste Store Order ID · Order {ref}.` |
| 26 | `Don’t let earn expire 💸` | `Add OID to keep ₹{earn} on track · Order {ref}.` |
| 27 | `Last call for OID 📣` | `Before {expiry} · Order {ref}.` |
| 28 | `You’re so close 🎯` | `Store Order ID for {product} · Order {ref}.` |
| 29 | `Submit OID 🚀` | `Order {ref} · add Store Order ID.` |
| 100 | `Order ID = green light 🟢` | `Update Order {ref} now.` |

### 3.4 Invoice upload needed (100 variants)

After parcel / when invoice due.

| # | Title | Body |
|---|-------|------|
| 1 | `Upload invoice 📤` | `Order {ref} needs invoice to start verification.` |
| 2 | `Invoice pending 📄` | `Upload bill for {product} · Order {ref}.` |
| 3 | `Final paperwork 🧾` | `Invoice unlocks payout clock · Order {ref}.` |
| 4 | `Bill please 🙏` | `Upload a clear invoice for Order {ref}.` |
| 5 | `Verification waiting ⏳` | `Invoice missing for Order {ref}.` |
| 6 | `Almost paid territory 💰` | `Upload invoice for {product} next.` |
| 7 | `PDF or photo OK 🖼️` | `Invoice for Order {ref} — clear & readable.` |
| 8 | `Ops can’t verify air 🌫️` | `Add invoice for Order {ref}.` |
| 9 | `Invoice = next gear ⚙️` | `Upload for Order {ref}.` |
| 10 | `Keep the earn moving 📈` | `Invoice due · Order {ref} · {product}.` |
| 11 | `Sharp bill, fast check ✨` | `Upload invoice for Order {ref}.` |
| 12 | `One upload left 📎` | `Invoice for {product} · Order {ref}.` |
| 13 | `Parcel in — invoice next 📦` | `Upload invoice for Order {ref}.` |
| 14 | `Don’t pause payout 🛑` | `Invoice needed for Order {ref}.` |
| 15 | `Friendly invoice nudge 🔔` | `Whenever ready — Order {ref} needs invoice.` |
| 16 | `Firm invoice nudge 🔥` | `Order {ref} still missing invoice. Upload now.` |
| 17 | `GST / tax invoice 🧾` | `Upload for Order {ref} to continue.` |
| 18 | `Camera ready? 📸` | `Snap a clear invoice for Order {ref}.` |
| 19 | `Bill of trust 🤝` | `Upload invoice · Order {ref}.` |
| 20 | `Verification queue opens after this ✅` | `Invoice for Order {ref}.` |
| 21 | `Paper trail please 🗂️` | `Add invoice for {product}.` |
| 22 | `Earn waits on invoice 💸` | `Upload bill · Order {ref}.` |
| 23 | `Clear > blurry 👓` | `Sharp invoice photo for Order {ref}.` |
| 24 | `Last mile paperwork 🏁` | `Invoice for Order {ref}.` |
| 25 | `Upload & relax 😌` | `Invoice for {product} · Order {ref}.` |
| 26 | `We need the bill 🧾` | `Order {ref} invoice pending.` |
| 27 | `Proof of purchase 🛍️` | `Upload invoice for Order {ref}.` |
| 28 | `Start verification 🚦` | `Invoice unlocks it · Order {ref}.` |
| 29 | `Tap to upload ⬆️` | `Invoice for Order {ref}.` |
| 100 | `Finish the loop 🔁` | `Invoice for {product} · Order {ref}.` |

### 3.5 Invoice re-upload (100 variants)

Blurry / incomplete bill.

| # | Title | Body |
|---|-------|------|
| 1 | `Clearer invoice needed 🔁` | `Re-upload a sharp invoice for Order {ref}.` |
| 2 | `Invoice not clear 👀` | `Please upload again · Order {ref}.` |
| 3 | `Re-upload required ⚠️` | `Blurry/cutoff bill — new photo for Order {ref}.` |
| 4 | `Try another shot 📸` | `Clear invoice needed for {product}.` |
| 5 | `Verification bounced back ↩️` | `Re-upload invoice · Order {ref}.` |
| 6 | `Make it readable 🔍` | `Invoice for Order {ref} needs a clearer image.` |
| 7 | `Edges cut off? ✂️` | `Full page invoice photo for Order {ref}.` |
| 8 | `Lighting check 💡` | `Bright, clear invoice for Order {ref}.` |
| 9 | `One more upload 📎` | `Re-upload invoice · Order {ref}.` |
| 10 | `Ops couldn’t read it 😕` | `Clearer invoice for {product} please.` |
| 11 | `Quality check failed ❌` | `Re-upload invoice for Order {ref}.` |
| 12 | `Zoom out a bit 🔎` | `Full invoice in frame · Order {ref}.` |
| 13 | `No glare please ✨` | `Clear invoice photo · Order {ref}.` |
| 14 | `Numbers must be visible 🔢` | `Re-upload for Order {ref}.` |
| 15 | `Almost — just clearer 👍` | `New invoice image · Order {ref}.` |
| 16 | `Second chance upload 🔄` | `Invoice for Order {ref}.` |
| 17 | `Help us verify fast ⚡` | `Sharp invoice · Order {ref}.` |
| 18 | `Bill redo 🧾` | `Re-upload invoice for {product}.` |
| 19 | `Focus on the totals 🎯` | `Clear invoice · Order {ref}.` |
| 20 | `Don’t crop the GSTIN 📄` | `Full invoice for Order {ref}.` |
| 21 | `Fresh photo beats blur 📷` | `Re-upload · Order {ref}.` |
| 22 | `Verification needs clarity 🪞` | `Invoice again · Order {ref}.` |
| 23 | `Upload 2.0 🚀` | `Clearer invoice for Order {ref}.` |
| 24 | `We believe in take two 🎬` | `Re-upload invoice · Order {ref}.` |
| 25 | `Readable = approvable ✅` | `Clear invoice for Order {ref}.` |
| 26 | `Fix the image, keep the earn 💸` | `Re-upload · Order {ref}.` |
| 27 | `Quick re-upload 🔔` | `Invoice for {product} · Order {ref}.` |
| 28 | `Action: new invoice 📌` | `Order {ref} needs a clearer bill.` |
| 29 | `Retake and submit 🎯` | `Invoice · Order {ref}.` |
| 100 | `Clear shot = green light 🟢` | `Re-upload invoice for Order {ref}.` |

### 3.6 Invoice verified (100 variants)

Passed verification.

| # | Title | Body |
|---|-------|------|
| 1 | `Invoice verified ✅` | `Payment step is next for Order {ref}.` |
| 2 | `Invoice approved 👍` | `Order {ref} moved to payment queue.` |
| 3 | `Bill checked — nice ✨` | `{product} invoice verified. Payout track next.` |
| 4 | `Verification complete 🎉` | `Invoice OK for Order {ref}.` |
| 5 | `You’re through paperwork 🧾` | `Order {ref} invoice approved.` |
| 6 | `Green on invoice 🟢` | `Payment processing follows · Order {ref}.` |
| 7 | `Great news ✅` | `Invoice verified for {product}.` |
| 8 | `Check passed ✔️` | `Order {ref} · invoice approved.` |
| 9 | `Ops loved that bill 💙` | `Verified · Order {ref}.` |
| 10 | `Clean invoice win 🏆` | `Payment step next · Order {ref}.` |
| 11 | `Verified & moving ➡️` | `Order {ref} invoice done.` |
| 12 | `All clear on docs 📄` | `Invoice verified · Order {ref}.` |
| 13 | `Payment queue unlocked 🔓` | `Thanks to your invoice · Order {ref}.` |
| 14 | `Nailed the upload 🎯` | `Invoice verified for {product}.` |
| 15 | `Bill of trust kept 🤝` | `Order {ref} verified.` |
| 16 | `Verification = ✅` | `Next: payment · Order {ref}.` |
| 17 | `Looks good to us 👀` | `Invoice approved · Order {ref}.` |
| 18 | `Paperwork done 🏁` | `Order {ref} · payment next.` |
| 19 | `Approved invoice 📌` | `Payout track continues · Order {ref}.` |
| 20 | `Success on verification 🎊` | `Order {ref}.` |
| 21 | `Invoice status: Verified ✅` | `{product} · Order {ref}.` |
| 22 | `You can relax a bit 😌` | `Invoice verified · Order {ref}.` |
| 23 | `Onward to payment 💳` | `Order {ref} invoice OK.` |
| 24 | `Verified faster than expected ⚡` | `Order {ref}.` |
| 25 | `Solid proof of purchase 🛍️` | `Invoice approved · Order {ref}.` |
| 26 | `Docs complete 📚` | `Payment step · Order {ref}.` |
| 27 | `Tick of approval ☑️` | `Invoice verified · Order {ref}.` |
| 28 | `Mintzer checked ✅` | `Order {ref} invoice passed.` |
| 29 | `Good news ping 🔔` | `Invoice verified for Order {ref}.` |
| 100 | `Next stop: payout prep 🚀` | `Invoice verified · Order {ref}.` |

### 3.7 Payment verified (100 variants) — **optional / Pine-only**

**Not the main money push.** This bank is only for rare cases where admin verifies a **payment screenshot** (e.g. Pine Lab) *before* bank payout.

**Default product rule:** holders should get **§3.8 Payout sent** when ₹ actually leaves Mintzer → bank. Prefer **silence** between invoice-verified and payout-sent rather than a confusing “Payment verified.”

**Tap opens (if sent):** Order detail · info only.

Payment proof OK → internal payout track (legacy wording kept for admin tools).

| # | Title | Body |
|---|-------|------|
| 1 | `Payment verified ✅` | `Payout will process (48 working hours) · Order {ref}.` |
| 2 | `Payment confirmed 🎉` | `Screenshot/payment OK · Order {ref}.` |
| 3 | `Money trail cleared 💸` | `Payment verified for {product}.` |
| 4 | `Payment step complete ✔️` | `Order {ref} moving to payout.` |
| 5 | `We’re good on payment 👍` | `Order {ref} verified.` |
| 6 | `Payment check passed 🟢` | `48 working hours clock applies · Order {ref}.` |
| 7 | `Confirmed — thanks 🙏` | `Payment verified · Order {ref}.` |
| 8 | `Payment status: Verified ✅` | `{product} · Order {ref}.` |
| 9 | `All set on payment 💼` | `Payout next · Order {ref}.` |
| 10 | `Nice — payment OK ✨` | `Order {ref}.` |
| 11 | `Verified payment 💳` | `Hold tight for bank payout · Order {ref}.` |
| 12 | `Payment approved 🏆` | `Order {ref} · payout queue.` |
| 13 | `Clear on funds check 🔍` | `Order {ref} payment verified.` |
| 14 | `You’re on the payout track 🛤️` | `Payment verified · Order {ref}.` |
| 15 | `Payment done side ✅` | `We handle payout next · Order {ref}.` |
| 16 | `Confirmed receipt 🧾` | `Payment verified · Order {ref}.` |
| 17 | `Green light payment 🚦` | `Order {ref}.` |
| 18 | `Payment ping 🔔` | `Verified for Order {ref}.` |
| 19 | `Solid — payment OK 💪` | `{product} · Order {ref}.` |
| 20 | `Payment stage cleared 🎯` | `Payout follows · Order {ref}.` |
| 21 | `Verified successfully 🌟` | `Order {ref} payment.` |
| 22 | `No action needed 🙂` | `Payment verified · Order {ref}.` |
| 23 | `We got the payment proof 📎` | `Verified · Order {ref}.` |
| 24 | `Payment complete on our side ✅` | `Order {ref}.` |
| 25 | `Moving to payout prep 🚀` | `Payment verified · Order {ref}.` |
| 26 | `Trust deposit made 🤝` | `Payment OK · Order {ref}.` |
| 27 | `Payment status updated 📌` | `Verified · Order {ref}.` |
| 28 | `Confirmed by Mintzer ✅` | `Order {ref} payment.` |
| 29 | `Payment win 🏅` | `Payout is next · Order {ref}.` |
| 100 | `All clear 💸✅` | `Payment verified · Order {ref}.` |

### 3.8 Payout sent to bank (100 variants) — **primary money push**

**When:** Mintzer **releases** payout to the holder’s bank (real credit).

**Tap opens:** `mintzer://wallet`

**Copy rule:** Title leads with **₹{amount}** · Body = bank + Wallet record. Calm celebrate — no “withdraw.”

₹ credited — calm + celebrate.

| # | Title | Body |
|---|-------|------|
| 1 | `₹{amount} paid to your bank ✅` | `Mintzer payout sent. Wallet shows the record.` |
| 2 | `Payout completed 🎉` | `₹{amount} credited · Order {ref}.` |
| 3 | `Money on the way home 🏠` | `₹{amount} paid · check your bank.` |
| 4 | `Bank transfer done 🏦` | `₹{amount} · Mintzer payout.` |
| 5 | `You earned it 💸` | `₹{amount} paid to your account.` |
| 6 | `Payout success 🚀` | `₹{amount} sent · Wallet has the entry.` |
| 7 | `Credited ✅` | `₹{amount} · Order {ref}.` |
| 8 | `Ka-ching (responsible version) 💰` | `₹{amount} paid to your bank.` |
| 9 | `Payout ping 🔔` | `₹{amount} transferred.` |
| 10 | `48h promise kept ⏱️` | `₹{amount} paid · Order {ref}.` |
| 11 | `Bank SMS incoming 📱` | `₹{amount} Mintzer payout sent.` |
| 12 | `Wallet updated 📒` | `₹{amount} payout recorded + bank sent.` |
| 13 | `Paid. Period. ✅` | `₹{amount} to your bank.` |
| 14 | `Transfer complete ✔️` | `₹{amount} · {product}.` |
| 15 | `Payout cleared 🟢` | `₹{amount} sent.` |
| 16 | `Your earn landed 🎯` | `₹{amount} paid to bank.` |
| 17 | `Mintzer → Bank ➡️` | `₹{amount} payout done.` |
| 18 | `Happy bank balance day 😊` | `₹{amount} credited.` |
| 19 | `Payout delivered 📦` | `Not a parcel — ₹{amount} to bank.` |
| 20 | `Amount sent 📤` | `₹{amount} · check account.` |
| 21 | `Success: payout 🎊` | `₹{amount} · Order {ref}.` |
| 22 | `Funds released 🔓` | `₹{amount} paid.` |
| 23 | `Bank got the love 💙` | `₹{amount} Mintzer payout.` |
| 24 | `Recorded in Wallet 🗂️` | `₹{amount} paid to bank.` |
| 25 | `No withdraw needed 🙂` | `₹{amount} already sent to bank.` |
| 26 | `Payout status: Sent ✅` | `₹{amount}.` |
| 27 | `You’re paid 🏁` | `₹{amount} · Order {ref}.` |
| 28 | `Transfer OK 🌟` | `₹{amount} to your bank.` |
| 29 | `Earn → Bank complete 🔁` | `₹{amount}.` |
| 100 | `Boom — paid 💥` | `₹{amount} Mintzer payout sent.` |

### 3.9 Deal live (pro / warm) (100 variants)

**Job A.** New deal on Home.

**Tap opens:** `mintzer://deals/:dealId` → **Deal detail** (Accept path).

**Connectivity rule (locked):**
- **Title** = `Earn ₹{earn} · {store}` (+ light emoji) — money + store first  
- **Body** = `{product}` + one clear verb (`Tap to accept` / `Open deal`)  
- Optional second beat: spend `{spend}` if useful — never drop product name  

Title hooks · body connects the product to Accept.

| # | Title | Body |
|---|-------|------|
| 1 | `Earn ₹{earn} · {store} 💸` | `{product} is live. Tap to accept.` |
| 2 | `Fresh earn just dropped ✨` | `{product} · Earn ₹{earn}. Open Mintzer.` |
| 3 | `New deal live 🔥` | `Earn ₹{earn} on {product} · {store}.` |
| 4 | `Card deal alert 💳` | `{product} · Earn ₹{earn}. Tap fast.` |
| 5 | `High earn ping 📈` | `₹{earn} · {store} · {product}.` |
| 6 | `Your move 🎯` | `{product} live · Earn ₹{earn}.` |
| 7 | `Accept when ready ✅` | `Earn ₹{earn} · {product}.` |
| 8 | `Live on Home 🏠` | `{product} · Earn ₹{earn} · {store}.` |
| 9 | `Worth a look 👀` | `Earn ₹{earn} on {product}.` |
| 10 | `Deal unlocked 🔓` | `{product} · Earn ₹{earn}.` |
| 11 | `Tap to earn 👆` | `₹{earn} · {store} · {product}.` |
| 12 | `New listing 🆕` | `Earn ₹{earn} · {product}.` |
| 13 | `Earn window open 🪟` | `{product} · ₹{earn} · {store}.` |
| 14 | `Go time ⏱️` | `Accept {product} · Earn ₹{earn}.` |
| 15 | `Fresh drop 🚀` | `{product} live · Earn ₹{earn}.` |
| 16 | `Card users: heads up 🔔` | `{product} · Earn ₹{earn}.` |
| 17 | `Mintzer deal live 💜` | `Earn ₹{earn} · {product}.` |
| 18 | `Don’t scroll past 📜` | `{product} · Earn ₹{earn}.` |
| 19 | `Earn first, flex later 😎` | `₹{earn} on {product}.` |
| 20 | `Live now ⚡` | `{store} · {product} · Earn ₹{earn}.` |
| 21 | `Opportunity knock 🚪` | `Earn ₹{earn} · {product}.` |
| 22 | `Ready when you are 🙌` | `{product} · Earn ₹{earn}.` |
| 23 | `New earn available 💎` | `₹{earn} · {store}.` |
| 24 | `Accept path open ➡️` | `{product} · Earn ₹{earn}.` |
| 25 | `Deal just landed ✈️` | `Earn ₹{earn} on {product}.` |
| 26 | `Hot on Home 🌶️` | `{product} · Earn ₹{earn}.` |
| 27 | `Earn ₹{earn} waiting 💤` | `Wake it up — accept {product}.` |
| 28 | `Store + card + you 🛍️` | `Earn ₹{earn} · {product}.` |
| 29 | `Live deal · {store} 🏷️` | `{product} · Earn ₹{earn}.` |
| 100 | `Start earning 🏁` | `Accept {product} · ₹{earn}.` |

### 3.10 Deal live (screenshot-funny) (100 variants)

Tier-1 discovery only — see §2b rules.

| # | Title | Body |
|---|-------|------|
| 1 | `Your fridge called. It said “buy a phone instead.” 🥶` | `{product} · Earn ₹{earn} on {store}. Tap before you rethink life.` |
| 2 | `Diet starts Monday. This deal starts now. 🥗➡️💳` | `Earn ₹{earn} · {store}. {product} is live.` |
| 3 | `Scroll therapy isn’t paying rent. 📱💸` | `Earn ₹{earn} on {product}. Accept while it’s live.` |
| 4 | `Your credit card wants a hobby. 🎨💳` | `{product} · Spend ₹{spend} · Earn ₹{earn}.` |
| 5 | `Broke-ish but strategic? Same. 🧠` | `High earn live: ₹{earn} · {store}. Tap to accept.` |
| 6 | `We don’t do FOMO. We do ₹{earn}. 😌` | `{product} just dropped. Open Mintzer.` |
| 7 | `Not financial advice. Just a juicy deal. 🍇` | `{product} · Earn ₹{earn}. You’re welcome.` |
| 8 | `Adulting tip #47: get paid to shop. 🛒✅` | `{store} deal live · Earn ₹{earn}.` |
| 9 | `Your future self already accepted this. 🔮` | `{product} · Earn ₹{earn}. Catch up.` |
| 10 | `Stop peeping. Start earning. 👀➡️💰` | `{product} is live. Earn ₹{earn}.` |
| 11 | `Fridge khola… phone mila. Thought so. 😏` | `{product} · Earn ₹{earn}. Ab accept kar.` |
| 12 | `Kal se saving. Aaj ye deal. 📅` | `{store} · Earn ₹{earn}. Tap fast.` |
| 13 | `Salary aayi? Card ready? Deal ready. 💼` | `{product} live · Earn ₹{earn}.` |
| 14 | `Thoda aur scroll? Ya thoda earn? 🤔` | `Earn ₹{earn} · {product}. Choose wisely.` |
| 15 | `Dost bolega “kaise kiya?” 🗣️` | `Answer: Mintzer · Earn ₹{earn} on {store}.` |
| 16 | `FOMO nahi. ₹{earn} hai. 😎` | `{product} abhi live hai. Accept.` |
| 17 | `Wallet history > story highlights. 📒` | `Payout later. Earn ₹{earn} now on {product}.` |
| 18 | `Swipe nahi — Accept. 👉` | `{product} · {store} · Earn ₹{earn}.` |
| 19 | `Main character energy, side quest: earn. 🎬` | `{product} · Earn ₹{earn}.` |
| 20 | `Plot twist: shopping pays you. 🎭` | `Earn ₹{earn} · {store} · {product}.` |
| 21 | `Your cart called. It’s lonely. 🛒😢` | `Fill it via this deal · Earn ₹{earn}.` |
| 22 | `Touch grass? Touch Accept first. 🌱` | `{product} · Earn ₹{earn}.` |
| 23 | `Sirf vibes nahi — ₹{earn} vibes. ✨` | `{product} live on {store}.` |
| 24 | `Brain: save. Card: earn. You: accept. 🧩` | `{product} · Earn ₹{earn}.` |
| 25 | `Notification so good you screenshot it 📸` | `…then accept {product} · Earn ₹{earn}.` |
| 26 | `Exited the app? Rude. 😤` | `Come back · Earn ₹{earn} on {product}.` |
| 27 | `This is your sign. Not astrology. A deal. ♈` | `Earn ₹{earn} · {product}.` |
| 28 | `Quiet luxury = loud earn. 🤫💸` | `₹{earn} on {product} · {store}.` |
| 29 | `Be so for real and accept this. 🫡` | `{product} · Earn ₹{earn}.` |
| 100 | `If you know, you know. If not: ₹{earn}. 😉` | `{product} is live. Tap.` |

### 3.12 Ticket reply (push shell) (100 variants)

Body = staff preview; titles rotate.

| # | Title | Body |
|---|-------|------|
| 1 | `Mintzer replied 💬` | `{preview}` |
| 2 | `Support replied 🎧` | `{preview}` |
| 3 | `New message on your ticket ✉️` | `{preview}` |
| 4 | `We wrote back ✍️` | `{preview}` |
| 5 | `Ticket update 🎫` | `{preview}` |
| 6 | `Reply from Mintzer 💜` | `{preview}` |
| 7 | `Your ticket has news 📰` | `{preview}` |
| 8 | `Ops replied 🛠️` | `{preview}` |
| 9 | `Check this reply 👀` | `{preview}` |
| 10 | `Message waiting 📥` | `{preview}` |
| 11 | `Tap to read reply 👆` | `{preview}` |
| 12 | `Support has an update 🔔` | `{preview}` |
| 13 | `Conversation continued ➡️` | `{preview}` |
| 14 | `Fresh reply ✨` | `{preview}` |
| 15 | `We’re on it — update 📌` | `{preview}` |
| 16 | `Ticket thread ping 🔔` | `{preview}` |
| 17 | `Human reply inside 👤` | `{preview}` |
| 18 | `Mintzer chat update 💭` | `{preview}` |
| 19 | `Response ready ✅` | `{preview}` |
| 20 | `Open ticket for details 📂` | `{preview}` |
| 21 | `You asked — we answered 💡` | `{preview}` |
| 22 | `Reply unlocked 🔓` | `{preview}` |
| 23 | `Support desk update 🛎️` | `{preview}` |
| 24 | `New note on ticket 📝` | `{preview}` |
| 25 | `Please read 📖` | `{preview}` |
| 26 | `Quick reply for you ⚡` | `{preview}` |
| 27 | `Ticket isn’t lonely anymore 😊` | `{preview}` |
| 28 | `Back to you 🔁` | `{preview}` |
| 29 | `Update from the team 👥` | `{preview}` |
| 100 | `Tap to continue chat 💬` | `{preview}` |

### 3.13 Placement timer — 5 minutes (100 variants)

In-funnel urgency.

| # | Title | Body |
|---|-------|------|
| 1 | `5 minutes left ⏱️` | `Finish {product} checkout to lock ₹{earn}.` |
| 2 | `5 min · Earn ₹{earn} 🔥` | `Place order now for {product}.` |
| 3 | `Clock says 5 🕔` | `Lock ₹{earn} on {product} before time’s up.` |
| 4 | `Five minutes — go ⚡` | `Checkout {product} · Earn ₹{earn}.` |
| 5 | `Almost expired ⏳` | `5 min left · {product} · ₹{earn}.` |
| 6 | `Hurry (politely) 🏃‍♂️` | `5 minutes to lock ₹{earn}.` |
| 7 | `Timer yellow 🟡` | `5 min left on {product}.` |
| 8 | `Don’t lose ₹{earn} 💸` | `5 minutes to finish checkout.` |
| 9 | `5:00 on the clock ⏰` | `Accept flow · {product}.` |
| 10 | `Quick — 5 min 🚀` | `Lock earn on {product}.` |
| 11 | `Five left ✋` | `Checkout to keep ₹{earn}.` |
| 12 | `Time check: 5 🧭` | `{product} · Earn ₹{earn}.` |
| 13 | `Wrapping up soon 🎁` | `5 min · finish order.` |
| 14 | `Last stretch 🏁` | `5 minutes · {product}.` |
| 15 | `Earn window closing 🪟` | `5 min · ₹{earn}.` |
| 16 | `Tick tock 5 ⏲️` | `Place order for {product}.` |
| 17 | `Five-minute drill 💪` | `Lock ₹{earn} now.` |
| 18 | `Still time — 5 👍` | `Finish {product} checkout.` |
| 19 | `Amber alert 5 🟠` | `₹{earn} · {product}.` |
| 20 | `5 min remaining 📣` | `Complete order to lock earn.` |
| 21 | `Save this placement 🛟` | `5 minutes left.` |
| 22 | `Checkout sprint 🏃‍♀️` | `5 min · {product}.` |
| 23 | `Don’t walk away 🚪` | `5 minutes · Earn ₹{earn}.` |
| 24 | `Short fuse — 5 🧨` | `Finish for ₹{earn}.` |
| 25 | `Five to glory 🏅` | `Checkout {product}.` |
| 26 | `Timer’s watching 👀` | `5 min left · ₹{earn}.` |
| 27 | `Now-ish ⌛` | `5 minutes to lock {product}.` |
| 28 | `Half a decade of minutes 😄` | `OK it’s 5 — finish checkout.` |
| 29 | `5-minute earn window 💎` | `{product} · ₹{earn}.` |
| 100 | `Act in 5 🎬` | `Lock ₹{earn} on {product}.` |

### 3.14 Placement timer — 1 minute (100 variants)

Clarity > comedy.

| # | Title | Body |
|---|-------|------|
| 1 | `1 minute left ⏱️` | `Last chance to lock ₹{earn} on {product}.` |
| 2 | `60 seconds 🔥` | `Finish checkout · Earn ₹{earn}.` |
| 3 | `ONE minute ⚠️` | `Lock ₹{earn} on {product} now.` |
| 4 | `Final minute 🏁` | `Place order for {product}.` |
| 5 | `Red timer 🔴` | `1 min · Earn ₹{earn}.` |
| 6 | `Last 60 ⏳` | `Checkout {product} immediately.` |
| 7 | `Don’t blink 👀` | `1 minute to lock ₹{earn}.` |
| 8 | `Now or never-ish ⚡` | `1 min left · {product}.` |
| 9 | `Critical: 1 min 🚨` | `Finish order to keep ₹{earn}.` |
| 10 | `Heartbeat minute 💓` | `Lock {product} · ₹{earn}.` |
| 11 | `60… 59… 🕒` | `Checkout now.` |
| 12 | `Ultimate nudge 📣` | `1 minute · Earn ₹{earn}.` |
| 13 | `Edge of expiry 🗡️` | `1 min · {product}.` |
| 14 | `Last call ☎️` | `Lock ₹{earn} in 60 seconds.` |
| 15 | `Go go go 🏃‍♂️` | `1 minute left.` |
| 16 | `Final stretch 🎯` | `Checkout {product}.` |
| 17 | `One minute drill 💪` | `Earn ₹{earn} — finish now.` |
| 18 | `Timer panic (useful) 😱` | `1 min · place order.` |
| 19 | `Clutch time 🎮` | `Lock ₹{earn} on {product}.` |
| 20 | `60-second window 🪟` | `Finish checkout.` |
| 21 | `Almost gone 🌪️` | `1 minute · {product}.` |
| 22 | `Save ₹{earn} 💸` | `1 min left to order.` |
| 23 | `This is it 🎬` | `1 minute · Accept flow.` |
| 24 | `No more reminders after this 🔔` | `1 min · lock earn.` |
| 25 | `Endgame ♟️` | `Checkout {product} · ₹{earn}.` |
| 26 | `Sixty to glory 🏅` | `Place order now.` |
| 27 | `Red zone 🛑` | `1 minute left.` |
| 28 | `Finish line in sight 🏁` | `1 min · {product}.` |
| 29 | `Do the thing 👆` | `1 minute · Earn ₹{earn}.` |
| 100 | `Last chance ✅` | `Lock ₹{earn} on {product} — 60s.` |


---

---
**LOCKED** with parent spec. Edit banks here; keep parent short.


---

## Extra banks — frequent engagement (LOCKED)

### Deal relist / live again (100 variants)

Same deal turned **off → on again**. Always fire. Tokens include `{earn}` `{product}` `{store}`.

| # | Title | Body |
|---|-------|------|
| 1 | `Back live 🔁` | `{product} is live again · Earn ₹{earn}. Tap to accept.` |
| 2 | `It’s back 👀` | `{store} · {product} · Earn ₹{earn}.` |
| 3 | `Relisted · Earn ₹{earn} 💸` | `{product} returned. Tap to accept.` |
| 4 | `Missed it earlier? 👋` | `{product} is live again on {store}.` |
| 5 | `Round two 🥊` | `Earn ₹{earn} · {product} is back.` |
| 6 | `Same deal. Fresh window. 🪟` | `{product} · Earn ₹{earn}.` |
| 7 | `We turned it back on 🔆` | `{product} live again. Accept.` |
| 8 | `Encore 🎬` | `Earn ₹{earn} on {product} · {store}.` |
| 9 | `Returned to Home 🏠` | `{product} · Earn ₹{earn}. Tap.` |
| 10 | `Live again · {store} ⚡` | `{product} · Earn ₹{earn}.` |
| 11 | `Second chance 🎯` | `Accept {product} · Earn ₹{earn}.` |
| 12 | `Don’t blink this time 😉` | `{product} is live again.` |
| 13 | `Relist alert 🔔` | `Earn ₹{earn} · {product}.` |
| 14 | `Back from pause ▶️` | `{product} · {store} · ₹{earn}.` |
| 15 | `Open seat again 💺` | `Earn ₹{earn} on {product}.` |
| 16 | `Fresh slot 🆕` | `{product} live again. Tap to accept.` |
| 17 | `You know this one 🧠` | `{product} · Earn ₹{earn} · back.` |
| 18 | `BOGO? No — back on 🔁` | `Earn ₹{earn} · {product}.` |
| 19 | `Again for real 💪` | `{store} deal live · {product}.` |
| 20 | `Comeback earn 📈` | `₹{earn} · {product} is live again.` |
| 21 | `Door reopened 🚪` | `Accept {product} · Earn ₹{earn}.` |
| 22 | `Same product. New timer. ⏱️` | `{product} · Earn ₹{earn}.` |
| 23 | `Relive the earn 💜` | `{product} on {store} · ₹{earn}.` |
| 24 | `We brought it back 🎁` | `Earn ₹{earn} · tap to accept.` |
| 25 | `Live² 🔥` | `{product} · Earn ₹{earn}.` |
| 26 | `Second drop 💧` | `{product} is live again.` |
| 27 | `Back on the board 📋` | `Earn ₹{earn} · {store}.` |
| 28 | `Replay available 🕹️` | `Accept {product} · ₹{earn}.` |
| 29 | `Not a drill — back live ✅` | `{product} · Earn ₹{earn}.` |
| 100 | `Again? Yes. 🙌` | `{product} live · Earn ₹{earn}.` |
### Viewed follow-up (30–60 min) (100 variants)

User opened deal detail · no Accept · left. Tight engagement. Deep link: deal detail.

| # | Title | Body |
|---|-------|------|
| 1 | `Still thinking? 🤔` | `{product} · Earn ₹{earn}. Tap to accept.` |
| 2 | `You left it open 👀` | `Finish Accept on {product} · ₹{earn}.` |
| 3 | `Quick nudge ⚡` | `{store} · {product} · Earn ₹{earn}.` |
| 4 | `Deal’s waiting ⏳` | `Earn ₹{earn} on {product}. Come back.` |
| 5 | `30–60 min check-in 🕒` | `{product} still live. Accept?` |
| 6 | `Don’t ghost this earn 👻` | `₹{earn} · {product} · {store}.` |
| 7 | `One tap left 👆` | `Accept {product} · Earn ₹{earn}.` |
| 8 | `You peeked. We noticed 🙂` | `{product} · Earn ₹{earn}.` |
| 9 | `Back so soon? Perfect 🎯` | `Lock ₹{earn} on {product}.` |
| 10 | `Earn still warm 🔥` | `{product} · Tap to accept.` |
| 11 | `Forgot already? 😄` | `{product} · Earn ₹{earn} on {store}.` |
| 12 | `Close the loop 🔁` | `Accept {product} · ₹{earn}.` |
| 13 | `Halfway vibe ⚡` | `Open {product} and Accept.` |
| 14 | `Card deal miss? Not yet 💳` | `Earn ₹{earn} · {product}.` |
| 15 | `Ping 🔔` | `{product} waiting · Earn ₹{earn}.` |
| 16 | `Come finish this 🏁` | `Accept · {product} · ₹{earn}.` |
| 17 | `Soft reminder 🌤️` | `{store} · Earn ₹{earn} · {product}.` |
| 18 | `Firm reminder 🔥` | `Accept {product} now · Earn ₹{earn}.` |
| 19 | `Still available ✅` | `{product} · Earn ₹{earn}.` |
| 20 | `Your tab is lonely 📱` | `Return to {product} · Accept.` |
| 21 | `Earn ₹{earn} says hi 👋` | `{product} on {store}.` |
| 22 | `Don’t overthink 🧠` | `Accept {product} · ₹{earn}.` |
| 23 | `Quick win window 🪟` | `{product} · Earn ₹{earn}.` |
| 24 | `We saved your place 📍` | `Tap · Accept {product}.` |
| 25 | `Minute-hour nudge ⏱️` | `Earn ₹{earn} · {product}.` |
| 26 | `Almost counted 🤞` | `Accept to start · {product}.` |
| 27 | `Same deal. Less waiting. 🚀` | `Earn ₹{earn} · Accept.` |
| 28 | `Open → Accept → done ✨` | `{product} · ₹{earn}.` |
| 29 | `This one’s still yours 🫵` | `{product} · Earn ₹{earn}.` |
| 100 | `Check-in #1 📬` | `{product} live · Tap to accept.` |
### Viewed follow-up (~1.5 hours) (100 variants)

Second wave after view (and/or after early follow-up). Deep link: deal detail.

| # | Title | Body |
|---|-------|------|
| 1 | `Still live · Earn ₹{earn} 💸` | `{product} on {store}. Tap to accept.` |
| 2 | `1.5h later ⏰` | `You viewed {product}. Accept when ready.` |
| 3 | `Second nudge 🔔` | `Earn ₹{earn} · {product}.` |
| 4 | `Don’t sleep on this 😴→😎` | `{product} · Accept · ₹{earn}.` |
| 5 | `Follow-up #2 📩` | `{store} · {product} · Earn ₹{earn}.` |
| 6 | `Earn check 📈` | `{product} still available.` |
| 7 | `We meant it 🙂` | `Accept {product} · Earn ₹{earn}.` |
| 8 | `Same product. Still paying. 💰` | `₹{earn} · {store}.` |
| 9 | `Come back for ₹{earn} 🏃` | `{product} · Tap to accept.` |
| 10 | `Hour-and-a-half hug 💜` | `Just kidding — Accept {product}.` |
| 11 | `Reminder with teeth 😬` | `Earn ₹{earn} on {product}.` |
| 12 | `Your future earn called 📞` | `{product} · Accept.` |
| 13 | `Still on Home 🏠` | `Open {product} · Earn ₹{earn}.` |
| 14 | `No accept yet — all good 👍` | `When ready: {product} · ₹{earn}.` |
| 15 | `Gentle shove 👉` | `Accept {product} now.` |
| 16 | `Stronger shove 👉👉` | `Earn ₹{earn} · {product} · Accept.` |
| 17 | `Deal didn’t leave 🚪` | `{product} · {store} · ₹{earn}.` |
| 18 | `Check Mintzer again 📲` | `{product} waiting.` |
| 19 | `Mid follow-up 🎯` | `Earn ₹{earn} · Tap to accept.` |
| 20 | `Holders are moving 🚶‍♂️` | `{product} · don’t miss ₹{earn}.` |
| 21 | `Time since you looked ⌛` | `Accept {product} · Earn ₹{earn}.` |
| 22 | `We’re consistent 💪` | `{product} still live.` |
| 23 | `Earn ₹{earn} unfinished 🧩` | `Complete Accept on {product}.` |
| 24 | `Second chance energy ✨` | `{store} · {product}.` |
| 25 | `Follow-up window 2 🪟` | `Tap · Accept · ₹{earn}.` |
| 26 | `Still the play 🎬` | `{product} · Earn ₹{earn}.` |
| 27 | `Don’t archive this mentally 🗄️` | `Open {product}.` |
| 28 | `Ping again 🔔🔔` | `Earn ₹{earn} · {product}.` |
| 29 | `We want you in-app 😊` | `Accept {product} · ₹{earn}.` |
| 100 | `Check-in #2 📬` | `{product} · Tap to accept.` |
### Still-live (day 2–3 heavy) (100 variants)

Deal stays live across days. `{n}` = day number. Fire morning/evening (or every ~8–12h) while live.

| # | Title | Body |
|---|-------|------|
| 1 | `Still live day {n} 📅` | `{product} · Earn ₹{earn}. Tap to accept.` |
| 2 | `Day {n} · still paying 💸` | `{store} · {product} · ₹{earn}.` |
| 3 | `Good morning earn ☀️` | `{product} is still live · Accept.` |
| 4 | `Evening check 🌙` | `Earn ₹{earn} on {product}.` |
| 5 | `Multi-day deal 🔥` | `{product} hasn’t left. Earn ₹{earn}.` |
| 6 | `Still here. Still ₹{earn}. 👋` | `{product} on {store}.` |
| 7 | `Day {n} reminder 🔔` | `Accept {product} when ready.` |
| 8 | `Ongoing live ⚡` | `{product} · Tap to accept.` |
| 9 | `Not expired yet ⏳` | `Earn ₹{earn} · {product}.` |
| 10 | `Long weekend for this deal? 😎` | `{product} · ₹{earn}.` |
| 11 | `Daily ping 📬` | `{store} · Earn ₹{earn} · {product}.` |
| 12 | `Heavy reminder (on purpose) 🏋️` | `Accept {product} · ₹{earn}.` |
| 13 | `We’re not shy 💜` | `{product} still live.` |
| 14 | `Open Mintzer · still live 📲` | `Earn ₹{earn}.` |
| 15 | `Day {n} drop-in 🚪` | `{product} · Accept.` |
| 16 | `Continuous live 📡` | `{product} · {store} · ₹{earn}.` |
| 17 | `Same deal. New day. 🌅` | `Earn ₹{earn} on {product}.` |
| 18 | `Afternoon nudge 🌤️` | `{product} waiting · ₹{earn}.` |
| 19 | `Night owl earn 🦉` | `Accept {product} · Earn ₹{earn}.` |
| 20 | `Still on the board 📋` | `{product} · Tap.` |
| 21 | `Multi-day money 💰` | `Earn ₹{earn} · {product}.` |
| 22 | `Don’t wait for day 4 😅` | `Accept {product} now.` |
| 23 | `Live streak continues 🔥` | `{product} · ₹{earn}.` |
| 24 | `Check-in while it’s live ✅` | `{store} · {product}.` |
| 25 | `Heavy cadence day {n} 📢` | `Earn ₹{earn} · Accept.` |
| 26 | `We’re loud for a reason 📣` | `{product} still live.` |
| 27 | `Return visit please 🙏` | `Accept {product} · ₹{earn}.` |
| 28 | `Deal marathon 🏃` | `{product} · Earn ₹{earn}.` |
| 29 | `Still accepting ✨` | `{product} on {store}.` |
| 100 | `Day {n} · Tap to accept 👆` | `Earn ₹{earn} · {product}.` |
