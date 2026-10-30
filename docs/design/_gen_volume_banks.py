# -*- coding: utf-8 -*-
"""Generate 30+ emoji template variants per notification type into the locked MD."""
from pathlib import Path

OUT = Path(r"D:\dev\mintzer-app\docs\design\NOTIFICATION-TEMPLATES-LOCKED.md")
text = OUT.read_text(encoding="utf-8")

# ---------------------------------------------------------------------------
# Banks: each list has exactly 30 {title, body} with emojis.
# Tokens: {product} {store} {earn} {spend} {ref} {expiry} {endsAt} {n} {amount} {preview} {reason} {card}
# ---------------------------------------------------------------------------

BANKS = {}

BANKS["otp"] = [
    ("Delivery partner waiting 🚚", "Share OTP for Order {ref} so delivery can finish."),
    ("OTP needed now 🔐", "Rider is at the door for {product}. Update OTP in Mintzer."),
    ("Almost delivered 📦", "One OTP away on Order {ref}. Tap and share."),
    ("Final step: OTP ⚡", "Order {ref} can’t complete without OTP + mobile."),
    ("Hey — OTP please 😊", "Delivery for {product} is waiting on your OTP."),
    ("Rider says hi 🛵", "Update OTP for Order {ref} to hand over the parcel."),
    ("Don’t leave them hanging ⏳", "OTP pending for Order {ref}. Share it now."),
    ("Out for delivery needs you 📲", "Add OTP for {product} · Order {ref}."),
    ("Quick OTP update 🔑", "Order {ref} is ready to complete. OTP please."),
    ("Parcel + OTP = done ✅", "Share OTP for Order {ref} and we’re finished."),
    ("Delivery in progress 🏃‍♂️", "OTP still missing for Order {ref}. Update now."),
    ("One tap left 👆", "Enter OTP for {product} so the rider can leave happy."),
    ("Friendly nudge 🔔", "OTP pending · Order {ref} · {product}."),
    ("Almost there! 🎯", "Just OTP for Order {ref} — then relax."),
    ("Doorstep moment 🚪", "Share OTP now for Order {ref}."),
    ("Mobile + OTP 📱", "Update both if needed for Order {ref}."),
    ("Complete delivery 🏁", "OTP unlocks handover for {product}."),
    ("Waiting room closed soon 😅", "Please share OTP for Order {ref} ASAP."),
    ("Rider clock is ticking ⏱️", "OTP for Order {ref} — make it quick."),
    ("Hand it over 🤝", "OTP needed to finish Order {ref}."),
    ("Last mile = you 🛣️", "Share OTP · Order {ref} · {product}."),
    ("No OTP, no bye-bye 👋", "Update OTP for Order {ref} to complete delivery."),
    ("Smooth finish please ✨", "OTP for {product} is all that’s left."),
    ("Delivery partner online 🟢", "They’re waiting on OTP for Order {ref}."),
    ("Tap → OTP → done 💫", "Order {ref} needs your OTP now."),
    ("Don’t ghost the rider 👻", "Share OTP for Order {ref}."),
    ("OTP o’clock 🕒", "Update OTP for {product} · Order {ref}."),
    ("Handover locked 🔒", "Unlock with OTP · Order {ref}."),
    ("We believe in you 💪", "One OTP for Order {ref} and you’re done."),
    ("Finish strong 🏅", "Share OTP for Order {ref} — last step!"),
]

BANKS["tracking"] = [
    ("Tracking ID needed 📦", "{product} · Order {ref} can’t move without tracking."),
    ("Shipping update pending 🚚", "Add tracking ID for Order {ref} now."),
    ("Dispatch waiting ⏳", "Order {ref} needs tracking to continue delivery."),
    ("Action needed: tracking ⚡", "Submit tracking ID for {product} · Order {ref}."),
    ("Where’s the tracking? 👀", "Add shipping ID for Order {ref}."),
    ("Order stuck without AWB 📌", "Update tracking for Order {ref} to unstick it."),
    ("Courier ID please 🏷️", "Tracking missing for {product} · Order {ref}."),
    ("Move the parcel forward ➡️", "Add tracking ID for Order {ref}."),
    ("Shipping details due 📝", "Order {ref} is waiting on your tracking ID."),
    ("Quick tracking reminder 🔔", "Please add tracking for {product}."),
    ("Accepted ✅ · Tracking ❓", "Order {ref} needs the shipping ID next."),
    ("Don’t delay dispatch 🚀", "Update tracking ID for Order {ref}."),
    ("AWB unlocks next step 🔓", "Add tracking for Order {ref}."),
    ("Courier link missing 🔗", "Paste tracking ID for {product} · Order {ref}."),
    ("Delivery flow paused ⏸️", "Tracking ID required for Order {ref}."),
    ("Ship it on paper too 📄", "Enter tracking for Order {ref}."),
    ("Ops is waiting 🛎️", "Add tracking ID for Order {ref} when you have it."),
    ("Tracking = progress 📈", "Update Order {ref} with shipping ID."),
    ("One field left ✍️", "Tracking ID for {product} · Order {ref}."),
    ("Help the parcel travel ✈️", "Add tracking for Order {ref}."),
    ("No tracking, no updates 📡", "Submit tracking ID for Order {ref}."),
    ("Store shipped? Tell us 🛍️", "Add tracking for Order {ref}."),
    ("Tracking reminder soft 🌤️", "Whenever ready — Order {ref} needs AWB."),
    ("Tracking reminder firm 🔥", "Order {ref} still missing tracking ID. Update now."),
    ("Keep momentum 🏃‍♂️", "Add tracking for {product} so we can follow it."),
    ("Shipping ID alert 🚨", "Order {ref} · please update tracking."),
    ("Parcel map needs a pin 📍", "Tracking ID for Order {ref}."),
    ("We’re ready when you are 🙌", "Add tracking for Order {ref}."),
    ("Close the loop 🔁", "Tracking ID completes this step · Order {ref}."),
    ("Next stop: tracking 🏁", "Update Order {ref} with courier tracking ID."),
]

BANKS["order_id"] = [
    ("Add Store Order ID 🧾", "Order {ref} needs Flipkart/Amazon Order ID before {expiry}."),
    ("Order ID pending ⏳", "Paste Store Order ID for {product} · deadline {expiry}."),
    ("Don’t miss the window ⏲️", "Update Order ID for {ref} before {expiry}."),
    ("Accepted — now the ID 📌", "Add Store Order ID for Order {ref}."),
    ("Checkout done? Prove it ✅", "Enter Store Order ID for {product}."),
    ("OID update needed 🔢", "Order {ref} is waiting for Store Order ID."),
    ("Quick Order ID reminder 🔔", "Add it before {expiry} · Order {ref}."),
    ("Lock the placement 🔐", "Store Order ID for {product} before {expiry}."),
    ("Timer hates empty IDs 😱", "Update Order ID for Order {ref} now."),
    ("One paste away 📋", "Store Order ID · Order {ref} · before {expiry}."),
    ("Finish Accept flow ✨", "Add Order ID for {product}."),
    ("Store receipt = OID 🧾", "Enter Store Order ID for Order {ref}."),
    ("We can’t track air 🌬️", "Need Store Order ID for Order {ref}."),
    ("Before auto-cancel ⚠️", "Add OID for Order {ref} by {expiry}."),
    ("Deal accepted — ID next ➡️", "Store Order ID for {product}."),
    ("OID o’clock 🕒", "Update Order {ref} with Store Order ID."),
    ("Copy from store app 📱", "Paste Order ID into Mintzer · Order {ref}."),
    ("Almost placed 💪", "Only Store Order ID left for Order {ref}."),
    ("Save this deal 🛟", "Add OID before {expiry} · Order {ref}."),
    ("ID or it didn’t happen 📷", "Enter Store Order ID for {product}."),
    ("Placement incomplete 🧩", "Order {ref} needs Store Order ID."),
    ("Beat the clock 🏁", "OID for Order {ref} due by {expiry}."),
    ("Friendly OID nudge 😊", "Got the Store Order ID for {product}? Add it."),
    ("Firm OID nudge ⚡", "Order {ref} still missing Store Order ID — update now."),
    ("Amazon/FK number please 🛍️", "Paste Store Order ID · Order {ref}."),
    ("Don’t let earn expire 💸", "Add OID to keep ₹{earn} on track · Order {ref}."),
    ("Last call for OID 📣", "Before {expiry} · Order {ref}."),
    ("You’re so close 🎯", "Store Order ID for {product} · Order {ref}."),
    ("Submit OID 🚀", "Order {ref} · add Store Order ID."),
    ("Order ID = green light 🟢", "Update Order {ref} now."),
]

BANKS["invoice_needed"] = [
    ("Upload invoice 📤", "Order {ref} needs invoice to start verification."),
    ("Invoice pending 📄", "Upload bill for {product} · Order {ref}."),
    ("Final paperwork 🧾", "Invoice unlocks payout clock · Order {ref}."),
    ("Bill please 🙏", "Upload a clear invoice for Order {ref}."),
    ("Verification waiting ⏳", "Invoice missing for Order {ref}."),
    ("Almost paid territory 💰", "Upload invoice for {product} next."),
    ("PDF or photo OK 🖼️", "Invoice for Order {ref} — clear & readable."),
    ("Ops can’t verify air 🌫️", "Add invoice for Order {ref}."),
    ("Invoice = next gear ⚙️", "Upload for Order {ref}."),
    ("Keep the earn moving 📈", "Invoice due · Order {ref} · {product}."),
    ("Sharp bill, fast check ✨", "Upload invoice for Order {ref}."),
    ("One upload left 📎", "Invoice for {product} · Order {ref}."),
    ("Parcel in — invoice next 📦", "Upload invoice for Order {ref}."),
    ("Don’t pause payout 🛑", "Invoice needed for Order {ref}."),
    ("Friendly invoice nudge 🔔", "Whenever ready — Order {ref} needs invoice."),
    ("Firm invoice nudge 🔥", "Order {ref} still missing invoice. Upload now."),
    ("GST / tax invoice 🧾", "Upload for Order {ref} to continue."),
    ("Camera ready? 📸", "Snap a clear invoice for Order {ref}."),
    ("Bill of trust 🤝", "Upload invoice · Order {ref}."),
    ("Verification queue opens after this ✅", "Invoice for Order {ref}."),
    ("Paper trail please 🗂️", "Add invoice for {product}."),
    ("Earn waits on invoice 💸", "Upload bill · Order {ref}."),
    ("Clear > blurry 👓", "Sharp invoice photo for Order {ref}."),
    ("Last mile paperwork 🏁", "Invoice for Order {ref}."),
    ("Upload & relax 😌", "Invoice for {product} · Order {ref}."),
    ("We need the bill 🧾", "Order {ref} invoice pending."),
    ("Proof of purchase 🛍️", "Upload invoice for Order {ref}."),
    ("Start verification 🚦", "Invoice unlocks it · Order {ref}."),
    ("Tap to upload ⬆️", "Invoice for Order {ref}."),
    ("Finish the loop 🔁", "Invoice for {product} · Order {ref}."),
]

BANKS["invoice_reupload"] = [
    ("Clearer invoice needed 🔁", "Re-upload a sharp invoice for Order {ref}."),
    ("Invoice not clear 👀", "Please upload again · Order {ref}."),
    ("Re-upload required ⚠️", "Blurry/cutoff bill — new photo for Order {ref}."),
    ("Try another shot 📸", "Clear invoice needed for {product}."),
    ("Verification bounced back ↩️", "Re-upload invoice · Order {ref}."),
    ("Make it readable 🔍", "Invoice for Order {ref} needs a clearer image."),
    ("Edges cut off? ✂️", "Full page invoice photo for Order {ref}."),
    ("Lighting check 💡", "Bright, clear invoice for Order {ref}."),
    ("One more upload 📎", "Re-upload invoice · Order {ref}."),
    ("Ops couldn’t read it 😕", "Clearer invoice for {product} please."),
    ("Quality check failed ❌", "Re-upload invoice for Order {ref}."),
    ("Zoom out a bit 🔎", "Full invoice in frame · Order {ref}."),
    ("No glare please ✨", "Clear invoice photo · Order {ref}."),
    ("Numbers must be visible 🔢", "Re-upload for Order {ref}."),
    ("Almost — just clearer 👍", "New invoice image · Order {ref}."),
    ("Second chance upload 🔄", "Invoice for Order {ref}."),
    ("Help us verify fast ⚡", "Sharp invoice · Order {ref}."),
    ("Bill redo 🧾", "Re-upload invoice for {product}."),
    ("Focus on the totals 🎯", "Clear invoice · Order {ref}."),
    ("Don’t crop the GSTIN 📄", "Full invoice for Order {ref}."),
    ("Fresh photo beats blur 📷", "Re-upload · Order {ref}."),
    ("Verification needs clarity 🪞", "Invoice again · Order {ref}."),
    ("Upload 2.0 🚀", "Clearer invoice for Order {ref}."),
    ("We believe in take two 🎬", "Re-upload invoice · Order {ref}."),
    ("Readable = approvable ✅", "Clear invoice for Order {ref}."),
    ("Fix the image, keep the earn 💸", "Re-upload · Order {ref}."),
    ("Quick re-upload 🔔", "Invoice for {product} · Order {ref}."),
    ("Action: new invoice 📌", "Order {ref} needs a clearer bill."),
    ("Retake and submit 🎯", "Invoice · Order {ref}."),
    ("Clear shot = green light 🟢", "Re-upload invoice for Order {ref}."),
]

BANKS["invoice_verified"] = [
    ("Invoice verified ✅", "Payment step is next for Order {ref}."),
    ("Invoice approved 👍", "Order {ref} moved to payment queue."),
    ("Bill checked — nice ✨", "{product} invoice verified. Payout track next."),
    ("Verification complete 🎉", "Invoice OK for Order {ref}."),
    ("You’re through paperwork 🧾", "Order {ref} invoice approved."),
    ("Green on invoice 🟢", "Payment processing follows · Order {ref}."),
    ("Great news ✅", "Invoice verified for {product}."),
    ("Check passed ✔️", "Order {ref} · invoice approved."),
    ("Ops loved that bill 💙", "Verified · Order {ref}."),
    ("Clean invoice win 🏆", "Payment step next · Order {ref}."),
    ("Verified & moving ➡️", "Order {ref} invoice done."),
    ("All clear on docs 📄", "Invoice verified · Order {ref}."),
    ("Payment queue unlocked 🔓", "Thanks to your invoice · Order {ref}."),
    ("Nailed the upload 🎯", "Invoice verified for {product}."),
    ("Bill of trust kept 🤝", "Order {ref} verified."),
    ("Verification = ✅", "Next: payment · Order {ref}."),
    ("Looks good to us 👀", "Invoice approved · Order {ref}."),
    ("Paperwork done 🏁", "Order {ref} · payment next."),
    ("Approved invoice 📌", "Payout track continues · Order {ref}."),
    ("Success on verification 🎊", "Order {ref}."),
    ("Invoice status: Verified ✅", "{product} · Order {ref}."),
    ("You can relax a bit 😌", "Invoice verified · Order {ref}."),
    ("Onward to payment 💳", "Order {ref} invoice OK."),
    ("Verified faster than expected ⚡", "Order {ref}."),
    ("Solid proof of purchase 🛍️", "Invoice approved · Order {ref}."),
    ("Docs complete 📚", "Payment step · Order {ref}."),
    ("Tick of approval ☑️", "Invoice verified · Order {ref}."),
    ("Mintzer checked ✅", "Order {ref} invoice passed."),
    ("Good news ping 🔔", "Invoice verified for Order {ref}."),
    ("Next stop: payout prep 🚀", "Invoice verified · Order {ref}."),
]

BANKS["payment_verified"] = [
    ("Payment verified ✅", "Payout will process (48 working hours) · Order {ref}."),
    ("Payment confirmed 🎉", "Screenshot/payment OK · Order {ref}."),
    ("Money trail cleared 💸", "Payment verified for {product}."),
    ("Payment step complete ✔️", "Order {ref} moving to payout."),
    ("We’re good on payment 👍", "Order {ref} verified."),
    ("Payment check passed 🟢", "48 working hours clock applies · Order {ref}."),
    ("Confirmed — thanks 🙏", "Payment verified · Order {ref}."),
    ("Payment status: Verified ✅", "{product} · Order {ref}."),
    ("All set on payment 💼", "Payout next · Order {ref}."),
    ("Nice — payment OK ✨", "Order {ref}."),
    ("Verified payment 💳", "Hold tight for bank payout · Order {ref}."),
    ("Payment approved 🏆", "Order {ref} · payout queue."),
    ("Clear on funds check 🔍", "Order {ref} payment verified."),
    ("You’re on the payout track 🛤️", "Payment verified · Order {ref}."),
    ("Payment done side ✅", "We handle payout next · Order {ref}."),
    ("Confirmed receipt 🧾", "Payment verified · Order {ref}."),
    ("Green light payment 🚦", "Order {ref}."),
    ("Payment ping 🔔", "Verified for Order {ref}."),
    ("Solid — payment OK 💪", "{product} · Order {ref}."),
    ("Payment stage cleared 🎯", "Payout follows · Order {ref}."),
    ("Verified successfully 🌟", "Order {ref} payment."),
    ("No action needed 🙂", "Payment verified · Order {ref}."),
    ("We got the payment proof 📎", "Verified · Order {ref}."),
    ("Payment complete on our side ✅", "Order {ref}."),
    ("Moving to payout prep 🚀", "Payment verified · Order {ref}."),
    ("Trust deposit made 🤝", "Payment OK · Order {ref}."),
    ("Payment status updated 📌", "Verified · Order {ref}."),
    ("Confirmed by Mintzer ✅", "Order {ref} payment."),
    ("Payment win 🏅", "Payout is next · Order {ref}."),
    ("All clear 💸✅", "Payment verified · Order {ref}."),
]

BANKS["payout_sent"] = [
    ("₹{amount} paid to your bank ✅", "Mintzer payout sent. Wallet shows the record."),
    ("Payout completed 🎉", "₹{amount} credited · Order {ref}."),
    ("Money on the way home 🏠", "₹{amount} paid · check your bank."),
    ("Bank transfer done 🏦", "₹{amount} · Mintzer payout."),
    ("You earned it 💸", "₹{amount} paid to your account."),
    ("Payout success 🚀", "₹{amount} sent · Wallet has the entry."),
    ("Credited ✅", "₹{amount} · Order {ref}."),
    ("Ka-ching (responsible version) 💰", "₹{amount} paid to your bank."),
    ("Payout ping 🔔", "₹{amount} transferred."),
    ("48h promise kept ⏱️", "₹{amount} paid · Order {ref}."),
    ("Bank SMS incoming 📱", "₹{amount} Mintzer payout sent."),
    ("Wallet updated 📒", "₹{amount} payout recorded + bank sent."),
    ("Paid. Period. ✅", "₹{amount} to your bank."),
    ("Transfer complete ✔️", "₹{amount} · {product}."),
    ("Payout cleared 🟢", "₹{amount} sent."),
    ("Your earn landed 🎯", "₹{amount} paid to bank."),
    ("Mintzer → Bank ➡️", "₹{amount} payout done."),
    ("Happy bank balance day 😊", "₹{amount} credited."),
    ("Payout delivered 📦", "Not a parcel — ₹{amount} to bank."),
    ("Amount sent 📤", "₹{amount} · check account."),
    ("Success: payout 🎊", "₹{amount} · Order {ref}."),
    ("Funds released 🔓", "₹{amount} paid."),
    ("Bank got the love 💙", "₹{amount} Mintzer payout."),
    ("Recorded in Wallet 🗂️", "₹{amount} paid to bank."),
    ("No withdraw needed 🙂", "₹{amount} already sent to bank."),
    ("Payout status: Sent ✅", "₹{amount}."),
    ("You’re paid 🏁", "₹{amount} · Order {ref}."),
    ("Transfer OK 🌟", "₹{amount} to your bank."),
    ("Earn → Bank complete 🔁", "₹{amount}."),
    ("Boom — paid 💥", "₹{amount} Mintzer payout sent."),
]

BANKS["deal_live"] = [
    ("Earn ₹{earn} · {store} 💸", "{product} is live. Tap to accept."),
    ("Fresh earn just dropped ✨", "{product} · Earn ₹{earn}. Open Mintzer."),
    ("New deal live 🔥", "Earn ₹{earn} on {product} · {store}."),
    ("Card deal alert 💳", "{product} · Earn ₹{earn}. Tap fast."),
    ("High earn ping 📈", "₹{earn} · {store} · {product}."),
    ("Your move 🎯", "{product} live · Earn ₹{earn}."),
    ("Accept when ready ✅", "Earn ₹{earn} · {product}."),
    ("Live on Home 🏠", "{product} · Earn ₹{earn} · {store}."),
    ("Worth a look 👀", "Earn ₹{earn} on {product}."),
    ("Deal unlocked 🔓", "{product} · Earn ₹{earn}."),
    ("Tap to earn 👆", "₹{earn} · {store} · {product}."),
    ("New listing 🆕", "Earn ₹{earn} · {product}."),
    ("Earn window open 🪟", "{product} · ₹{earn} · {store}."),
    ("Go time ⏱️", "Accept {product} · Earn ₹{earn}."),
    ("Fresh drop 🚀", "{product} live · Earn ₹{earn}."),
    ("Card users: heads up 🔔", "{product} · Earn ₹{earn}."),
    ("Mintzer deal live 💜", "Earn ₹{earn} · {product}."),
    ("Don’t scroll past 📜", "{product} · Earn ₹{earn}."),
    ("Earn first, flex later 😎", "₹{earn} on {product}."),
    ("Live now ⚡", "{store} · {product} · Earn ₹{earn}."),
    ("Opportunity knock 🚪", "Earn ₹{earn} · {product}."),
    ("Ready when you are 🙌", "{product} · Earn ₹{earn}."),
    ("New earn available 💎", "₹{earn} · {store}."),
    ("Accept path open ➡️", "{product} · Earn ₹{earn}."),
    ("Deal just landed ✈️", "Earn ₹{earn} on {product}."),
    ("Hot on Home 🌶️", "{product} · Earn ₹{earn}."),
    ("Earn ₹{earn} waiting 💤", "Wake it up — accept {product}."),
    ("Store + card + you 🛍️", "Earn ₹{earn} · {product}."),
    ("Live deal · {store} 🏷️", "{product} · Earn ₹{earn}."),
    ("Start earning 🏁", "Accept {product} · ₹{earn}."),
]

BANKS["deal_funny"] = [
    ("Your fridge called. It said “buy a phone instead.” 🥶", "{product} · Earn ₹{earn} on {store}. Tap before you rethink life."),
    ("Diet starts Monday. This deal starts now. 🥗➡️💳", "Earn ₹{earn} · {store}. {product} is live."),
    ("Scroll therapy isn’t paying rent. 📱💸", "Earn ₹{earn} on {product}. Accept while it’s live."),
    ("Your credit card wants a hobby. 🎨💳", "{product} · Spend ₹{spend} · Earn ₹{earn}."),
    ("Broke-ish but strategic? Same. 🧠", "High earn live: ₹{earn} · {store}. Tap to accept."),
    ("We don’t do FOMO. We do ₹{earn}. 😌", "{product} just dropped. Open Mintzer."),
    ("Not financial advice. Just a juicy deal. 🍇", "{product} · Earn ₹{earn}. You’re welcome."),
    ("Adulting tip #47: get paid to shop. 🛒✅", "{store} deal live · Earn ₹{earn}."),
    ("Your future self already accepted this. 🔮", "{product} · Earn ₹{earn}. Catch up."),
    ("Stop peeping. Start earning. 👀➡️💰", "{product} is live. Earn ₹{earn}."),
    ("Fridge khola… phone mila. Thought so. 😏", "{product} · Earn ₹{earn}. Ab accept kar."),
    ("Kal se saving. Aaj ye deal. 📅", "{store} · Earn ₹{earn}. Tap fast."),
    ("Salary aayi? Card ready? Deal ready. 💼", "{product} live · Earn ₹{earn}."),
    ("Thoda aur scroll? Ya thoda earn? 🤔", "Earn ₹{earn} · {product}. Choose wisely."),
    ("Dost bolega “kaise kiya?” 🗣️", "Answer: Mintzer · Earn ₹{earn} on {store}."),
    ("FOMO nahi. ₹{earn} hai. 😎", "{product} abhi live hai. Accept."),
    ("Wallet history > story highlights. 📒", "Payout later. Earn ₹{earn} now on {product}."),
    ("Swipe nahi — Accept. 👉", "{product} · {store} · Earn ₹{earn}."),
    ("Main character energy, side quest: earn. 🎬", "{product} · Earn ₹{earn}."),
    ("Plot twist: shopping pays you. 🎭", "Earn ₹{earn} · {store} · {product}."),
    ("Your cart called. It’s lonely. 🛒😢", "Fill it via this deal · Earn ₹{earn}."),
    ("Touch grass? Touch Accept first. 🌱", "{product} · Earn ₹{earn}."),
    ("Sirf vibes nahi — ₹{earn} vibes. ✨", "{product} live on {store}."),
    ("Brain: save. Card: earn. You: accept. 🧩", "{product} · Earn ₹{earn}."),
    ("Notification so good you screenshot it 📸", "…then accept {product} · Earn ₹{earn}."),
    ("Exited the app? Rude. 😤", "Come back · Earn ₹{earn} on {product}."),
    ("This is your sign. Not astrology. A deal. ♈", "Earn ₹{earn} · {product}."),
    ("Quiet luxury = loud earn. 🤫💸", "₹{earn} on {product} · {store}."),
    ("Be so for real and accept this. 🫡", "{product} · Earn ₹{earn}."),
    ("If you know, you know. If not: ₹{earn}. 😉", "{product} is live. Tap."),
]

BANKS["tracking_done"] = [  # optional: user added tracking confirmation style / admin shipped
    ("Tracking added ✅", "Order {ref} shipping ID saved. We’ll follow it."),
    ("You’re tracked 📦", "Tracking live for {product} · Order {ref}."),
    ("Shipping ID received 🚚", "Order {ref} updated. Nice."),
    ("AWB locked in 🔒", "Tracking for Order {ref} is on file."),
    ("Parcel is followable now 📍", "Order {ref} · tracking saved."),
    ("Dispatch details in ✅", "Thanks — Order {ref} tracking updated."),
    ("On the map 🗺️", "Tracking ID for Order {ref} received."),
    ("Courier linked 🔗", "Order {ref} · {product}."),
    ("Shipping step complete ✔️", "Order {ref} tracking added."),
    ("We can see it moving 👀", "Tracking saved · Order {ref}."),
    ("Good update 🔔", "Tracking ID in for Order {ref}."),
    ("Parcel status unlocked 🔓", "Order {ref}."),
    ("Tracking confirmed 👍", "{product} · Order {ref}."),
    ("AWB appreciated 🙏", "Order {ref} updated."),
    ("Shipping ping saved 📡", "Order {ref}."),
    ("Next: keep an eye on delivery 👀", "Tracking · Order {ref}."),
    ("Logged ✅", "Tracking for Order {ref}."),
    ("Courier ID captured 🏷️", "Order {ref}."),
    ("Smooth — tracking in ✨", "Order {ref}."),
    ("Step complete 🏁", "Tracking added · Order {ref}."),
    ("You’re ahead of the curve 📈", "Tracking · Order {ref}."),
    ("Delivery story started 📖", "Order {ref} tracking live."),
    ("All set on shipping ID 🟢", "Order {ref}."),
    ("Noted by Mintzer 📝", "Tracking · Order {ref}."),
    ("Update successful 💫", "Order {ref} tracking."),
    ("Parcel breadcrumbs set 🍞", "Tracking · Order {ref}."),
    ("Thanks for the AWB 🙌", "Order {ref}."),
    ("Shipping checklist ✅", "Tracking done · Order {ref}."),
    ("Moved to in-transit watch 👀", "Order {ref}."),
    ("Tracking = done for now 🎯", "Order {ref} · {product}."),
]

BANKS["ticket_reply"] = [
    ("Mintzer replied 💬", "{preview}"),
    ("Support replied 🎧", "{preview}"),
    ("New message on your ticket ✉️", "{preview}"),
    ("We wrote back ✍️", "{preview}"),
    ("Ticket update 🎫", "{preview}"),
    ("Reply from Mintzer 💜", "{preview}"),
    ("Your ticket has news 📰", "{preview}"),
    ("Ops replied 🛠️", "{preview}"),
    ("Check this reply 👀", "{preview}"),
    ("Message waiting 📥", "{preview}"),
    ("Tap to read reply 👆", "{preview}"),
    ("Support has an update 🔔", "{preview}"),
    ("Conversation continued ➡️", "{preview}"),
    ("Fresh reply ✨", "{preview}"),
    ("We’re on it — update 📌", "{preview}"),
    ("Ticket thread ping 🔔", "{preview}"),
    ("Human reply inside 👤", "{preview}"),
    ("Mintzer chat update 💭", "{preview}"),
    ("Response ready ✅", "{preview}"),
    ("Open ticket for details 📂", "{preview}"),
    ("You asked — we answered 💡", "{preview}"),
    ("Reply unlocked 🔓", "{preview}"),
    ("Support desk update 🛎️", "{preview}"),
    ("New note on ticket 📝", "{preview}"),
    ("Please read 📖", "{preview}"),
    ("Quick reply for you ⚡", "{preview}"),
    ("Ticket isn’t lonely anymore 😊", "{preview}"),
    ("Back to you 🔁", "{preview}"),
    ("Update from the team 👥", "{preview}"),
    ("Tap to continue chat 💬", "{preview}"),
]

BANKS["timer_5m"] = [
    ("5 minutes left ⏱️", "Finish {product} checkout to lock ₹{earn}."),
    ("5 min · Earn ₹{earn} 🔥", "Place order now for {product}."),
    ("Clock says 5 🕔", "Lock ₹{earn} on {product} before time’s up."),
    ("Five minutes — go ⚡", "Checkout {product} · Earn ₹{earn}."),
    ("Almost expired ⏳", "5 min left · {product} · ₹{earn}."),
    ("Hurry (politely) 🏃‍♂️", "5 minutes to lock ₹{earn}."),
    ("Timer yellow 🟡", "5 min left on {product}."),
    ("Don’t lose ₹{earn} 💸", "5 minutes to finish checkout."),
    ("5:00 on the clock ⏰", "Accept flow · {product}."),
    ("Quick — 5 min 🚀", "Lock earn on {product}."),
    ("Five left ✋", "Checkout to keep ₹{earn}."),
    ("Time check: 5 🧭", "{product} · Earn ₹{earn}."),
    ("Wrapping up soon 🎁", "5 min · finish order."),
    ("Last stretch 🏁", "5 minutes · {product}."),
    ("Earn window closing 🪟", "5 min · ₹{earn}."),
    ("Tick tock 5 ⏲️", "Place order for {product}."),
    ("Five-minute drill 💪", "Lock ₹{earn} now."),
    ("Still time — 5 👍", "Finish {product} checkout."),
    ("Amber alert 5 🟠", "₹{earn} · {product}."),
    ("5 min remaining 📣", "Complete order to lock earn."),
    ("Save this placement 🛟", "5 minutes left."),
    ("Checkout sprint 🏃‍♀️", "5 min · {product}."),
    ("Don’t walk away 🚪", "5 minutes · Earn ₹{earn}."),
    ("Short fuse — 5 🧨", "Finish for ₹{earn}."),
    ("Five to glory 🏅", "Checkout {product}."),
    ("Timer’s watching 👀", "5 min left · ₹{earn}."),
    ("Now-ish ⌛", "5 minutes to lock {product}."),
    ("Half a decade of minutes 😄", "OK it’s 5 — finish checkout."),
    ("5-minute earn window 💎", "{product} · ₹{earn}."),
    ("Act in 5 🎬", "Lock ₹{earn} on {product}."),
]

BANKS["timer_1m"] = [
    ("1 minute left ⏱️", "Last chance to lock ₹{earn} on {product}."),
    ("60 seconds 🔥", "Finish checkout · Earn ₹{earn}."),
    ("ONE minute ⚠️", "Lock ₹{earn} on {product} now."),
    ("Final minute 🏁", "Place order for {product}."),
    ("Red timer 🔴", "1 min · Earn ₹{earn}."),
    ("Last 60 ⏳", "Checkout {product} immediately."),
    ("Don’t blink 👀", "1 minute to lock ₹{earn}."),
    ("Now or never-ish ⚡", "1 min left · {product}."),
    ("Critical: 1 min 🚨", "Finish order to keep ₹{earn}."),
    ("Heartbeat minute 💓", "Lock {product} · ₹{earn}."),
    ("60… 59… 🕒", "Checkout now."),
    ("Ultimate nudge 📣", "1 minute · Earn ₹{earn}."),
    ("Edge of expiry 🗡️", "1 min · {product}."),
    ("Last call ☎️", "Lock ₹{earn} in 60 seconds."),
    ("Go go go 🏃‍♂️", "1 minute left."),
    ("Final stretch 🎯", "Checkout {product}."),
    ("One minute drill 💪", "Earn ₹{earn} — finish now."),
    ("Timer panic (useful) 😱", "1 min · place order."),
    ("Clutch time 🎮", "Lock ₹{earn} on {product}."),
    ("60-second window 🪟", "Finish checkout."),
    ("Almost gone 🌪️", "1 minute · {product}."),
    ("Save ₹{earn} 💸", "1 min left to order."),
    ("This is it 🎬", "1 minute · Accept flow."),
    ("No more reminders after this 🔔", "1 min · lock earn."),
    ("Endgame ♟️", "Checkout {product} · ₹{earn}."),
    ("Sixty to glory 🏅", "Place order now."),
    ("Red zone 🛑", "1 minute left."),
    ("Finish line in sight 🏁", "1 min · {product}."),
    ("Do the thing 👆", "1 minute · Earn ₹{earn}."),
    ("Last chance ✅", "Lock ₹{earn} on {product} — 60s."),
]

assert all(len(v) >= 30 for v in BANKS.values()), {k: len(v) for k, v in BANKS.items()}

SECTION = r"""
---

## 7. Volume banks — **30+ emoji variants per type** (LOCKED)

**Rule:** Every operational / deal push type below has **≥ 30** title+body variants with emojis. Rotate randomly per send. Soft/firm pairs included where useful.

**Tokens:** `{product}` `{store}` `{earn}` `{spend}` `{ref}` `{expiry}` `{endsAt}` `{n}` `{amount}` `{preview}` `{reason}` `{card}`

**Tone reminder:** OTP / tracking / invoice / payout = clear + human. Deal funny bank = screenshot-worthy. Never joke on payout failure.

"""

def fmt_bank(key: str, heading: str, blurb: str) -> str:
    rows = BANKS[key]
    lines = [
        f"### 7.{list(BANKS.keys()).index(key)+1} {heading} ({len(rows)} variants)",
        "",
        blurb,
        "",
        "| # | Title | Body |",
        "|---|-------|------|",
    ]
    for i, (t, b) in enumerate(rows, 1):
        lines.append(f"| {i} | `{t}` | `{b}` |")
    lines.append("")
    return "\n".join(lines)


blocks = [
    SECTION.strip(),
    "",
    fmt_bank("otp", "OTP pending / update", "When delivery needs OTP from holder."),
    fmt_bank("tracking", "Tracking ID needed", "When shipping/AWB is missing."),
    fmt_bank("tracking_done", "Tracking ID received (ack)", "Optional confirm after user adds tracking."),
    fmt_bank("order_id", "Store Order ID needed", "After Accept — before expiry."),
    fmt_bank("invoice_needed", "Invoice upload needed", "After parcel / when invoice due."),
    fmt_bank("invoice_reupload", "Invoice re-upload", "Blurry / incomplete bill."),
    fmt_bank("invoice_verified", "Invoice verified", "Passed verification."),
    fmt_bank("payment_verified", "Payment verified", "Payment proof OK → payout track."),
    fmt_bank("payout_sent", "Payout sent to bank", "₹ credited — calm + celebrate."),
    fmt_bank("deal_live", "Deal live (pro / warm)", "Standard deal drop."),
    fmt_bank("deal_funny", "Deal live (screenshot-funny)", "Tier-1 discovery only — see §2b rules."),
    fmt_bank("ticket_reply", "Ticket reply (push shell)", "Body = staff preview; titles rotate."),
    fmt_bank("timer_5m", "Placement timer — 5 minutes", "In-funnel urgency."),
    fmt_bank("timer_1m", "Placement timer — 1 minute", "Clarity > comedy."),
]

# Counts table
counts = "| Type | Count |\n|------|-------|\n" + "\n".join(
    f"| `{k}` | {len(v)} |" for k, v in BANKS.items()
)
blocks.insert(2, counts)
blocks.insert(3, "")

new_section = "\n".join(blocks).rstrip() + "\n"

marker = "\n## 7. Volume banks"
if marker in text:
    # replace from ## 7 to end or next ## 8
    start = text.index(marker)
    text = text[:start].rstrip() + "\n\n" + new_section
else:
    # insert before lock notice section 6 end — append after section 6
    if "## 6. Lock notice" in text:
        text = text.rstrip() + "\n\n" + new_section
    else:
        text = text.rstrip() + "\n\n" + new_section

# Update lock notice to mention volume banks
if "Volume banks" not in text.split("## 6. Lock notice")[-1][:500]:
    text = text.replace(
        "**LOCKED 22 Sep 2026.**",
        "**LOCKED 22 Sep 2026** · volume banks (§7) added same day — **≥30 emoji variants per type**.",
    )

OUT.write_text(text, encoding="utf-8")
print("Updated", OUT)
for k, v in BANKS.items():
    print(f"  {k}: {len(v)}")
