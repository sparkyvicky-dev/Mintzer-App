# -*- coding: utf-8 -*-
"""Append / replace aggressive deal engagement banks (30 each)."""
from pathlib import Path

BANKS_PATH = Path(r"D:\dev\mintzer-app\docs\design\NOTIFICATION-TEMPLATE-BANKS-LOCKED.md")

def bank(title: str, blurb: str, rows: list[tuple[str, str]]) -> str:
    assert len(rows) >= 30, (title, len(rows))
    lines = [
        f"### {title} ({len(rows)} variants)",
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

deal_relist = [
    ("Back live 🔁", "{product} is live again · Earn ₹{earn}. Tap to accept."),
    ("It’s back 👀", "{store} · {product} · Earn ₹{earn}."),
    ("Relisted · Earn ₹{earn} 💸", "{product} returned. Tap to accept."),
    ("Missed it earlier? 👋", "{product} is live again on {store}."),
    ("Round two 🥊", "Earn ₹{earn} · {product} is back."),
    ("Same deal. Fresh window. 🪟", "{product} · Earn ₹{earn}."),
    ("We turned it back on 🔆", "{product} live again. Accept."),
    ("Encore 🎬", "Earn ₹{earn} on {product} · {store}."),
    ("Returned to Home 🏠", "{product} · Earn ₹{earn}. Tap."),
    ("Live again · {store} ⚡", "{product} · Earn ₹{earn}."),
    ("Second chance 🎯", "Accept {product} · Earn ₹{earn}."),
    ("Don’t blink this time 😉", "{product} is live again."),
    ("Relist alert 🔔", "Earn ₹{earn} · {product}."),
    ("Back from pause ▶️", "{product} · {store} · ₹{earn}."),
    ("Open seat again 💺", "Earn ₹{earn} on {product}."),
    ("Fresh slot 🆕", "{product} live again. Tap to accept."),
    ("You know this one 🧠", "{product} · Earn ₹{earn} · back."),
    ("BOGO? No — back on 🔁", "Earn ₹{earn} · {product}."),
    ("Again for real 💪", "{store} deal live · {product}."),
    ("Comeback earn 📈", "₹{earn} · {product} is live again."),
    ("Door reopened 🚪", "Accept {product} · Earn ₹{earn}."),
    ("Same product. New timer. ⏱️", "{product} · Earn ₹{earn}."),
    ("Relive the earn 💜", "{product} on {store} · ₹{earn}."),
    ("We brought it back 🎁", "Earn ₹{earn} · tap to accept."),
    ("Live² 🔥", "{product} · Earn ₹{earn}."),
    ("Second drop 💧", "{product} is live again."),
    ("Back on the board 📋", "Earn ₹{earn} · {store}."),
    ("Replay available 🕹️", "Accept {product} · ₹{earn}."),
    ("Not a drill — back live ✅", "{product} · Earn ₹{earn}."),
    ("Again? Yes. 🙌", "{product} live · Earn ₹{earn}."),
]

follow_early = [  # 30–60 min after view, no accept
    ("Still thinking? 🤔", "{product} · Earn ₹{earn}. Tap to accept."),
    ("You left it open 👀", "Finish Accept on {product} · ₹{earn}."),
    ("Quick nudge ⚡", "{store} · {product} · Earn ₹{earn}."),
    ("Deal’s waiting ⏳", "Earn ₹{earn} on {product}. Come back."),
    ("30–60 min check-in 🕒", "{product} still live. Accept?"),
    ("Don’t ghost this earn 👻", "₹{earn} · {product} · {store}."),
    ("One tap left 👆", "Accept {product} · Earn ₹{earn}."),
    ("You peeked. We noticed 🙂", "{product} · Earn ₹{earn}."),
    ("Back so soon? Perfect 🎯", "Lock ₹{earn} on {product}."),
    ("Earn still warm 🔥", "{product} · Tap to accept."),
    ("Forgot already? 😄", "{product} · Earn ₹{earn} on {store}."),
    ("Close the loop 🔁", "Accept {product} · ₹{earn}."),
    ("Halfway vibe ⚡", "Open {product} and Accept."),
    ("Card deal miss? Not yet 💳", "Earn ₹{earn} · {product}."),
    ("Ping 🔔", "{product} waiting · Earn ₹{earn}."),
    ("Come finish this 🏁", "Accept · {product} · ₹{earn}."),
    ("Soft reminder 🌤️", "{store} · Earn ₹{earn} · {product}."),
    ("Firm reminder 🔥", "Accept {product} now · Earn ₹{earn}."),
    ("Still available ✅", "{product} · Earn ₹{earn}."),
    ("Your tab is lonely 📱", "Return to {product} · Accept."),
    ("Earn ₹{earn} says hi 👋", "{product} on {store}."),
    ("Don’t overthink 🧠", "Accept {product} · ₹{earn}."),
    ("Quick win window 🪟", "{product} · Earn ₹{earn}."),
    ("We saved your place 📍", "Tap · Accept {product}."),
    ("Minute-hour nudge ⏱️", "Earn ₹{earn} · {product}."),
    ("Almost counted 🤞", "Accept to start · {product}."),
    ("Same deal. Less waiting. 🚀", "Earn ₹{earn} · Accept."),
    ("Open → Accept → done ✨", "{product} · ₹{earn}."),
    ("This one’s still yours 🫵", "{product} · Earn ₹{earn}."),
    ("Check-in #1 📬", "{product} live · Tap to accept."),
]

follow_mid = [  # ~1.5h after view / after early
    ("Still live · Earn ₹{earn} 💸", "{product} on {store}. Tap to accept."),
    ("1.5h later ⏰", "You viewed {product}. Accept when ready."),
    ("Second nudge 🔔", "Earn ₹{earn} · {product}."),
    ("Don’t sleep on this 😴→😎", "{product} · Accept · ₹{earn}."),
    ("Follow-up #2 📩", "{store} · {product} · Earn ₹{earn}."),
    ("Earn check 📈", "{product} still available."),
    ("We meant it 🙂", "Accept {product} · Earn ₹{earn}."),
    ("Same product. Still paying. 💰", "₹{earn} · {store}."),
    ("Come back for ₹{earn} 🏃", "{product} · Tap to accept."),
    ("Hour-and-a-half hug 💜", "Just kidding — Accept {product}."),
    ("Reminder with teeth 😬", "Earn ₹{earn} on {product}."),
    ("Your future earn called 📞", "{product} · Accept."),
    ("Still on Home 🏠", "Open {product} · Earn ₹{earn}."),
    ("No accept yet — all good 👍", "When ready: {product} · ₹{earn}."),
    ("Gentle shove 👉", "Accept {product} now."),
    ("Stronger shove 👉👉", "Earn ₹{earn} · {product} · Accept."),
    ("Deal didn’t leave 🚪", "{product} · {store} · ₹{earn}."),
    ("Check Mintzer again 📲", "{product} waiting."),
    ("Mid follow-up 🎯", "Earn ₹{earn} · Tap to accept."),
    ("Holders are moving 🚶‍♂️", "{product} · don’t miss ₹{earn}."),
    ("Time since you looked ⌛", "Accept {product} · Earn ₹{earn}."),
    ("We’re consistent 💪", "{product} still live."),
    ("Earn ₹{earn} unfinished 🧩", "Complete Accept on {product}."),
    ("Second chance energy ✨", "{store} · {product}."),
    ("Follow-up window 2 🪟", "Tap · Accept · ₹{earn}."),
    ("Still the play 🎬", "{product} · Earn ₹{earn}."),
    ("Don’t archive this mentally 🗄️", "Open {product}."),
    ("Ping again 🔔🔔", "Earn ₹{earn} · {product}."),
    ("We want you in-app 😊", "Accept {product} · ₹{earn}."),
    ("Check-in #2 📬", "{product} · Tap to accept."),
]

still_live = [  # day 2–3 while deal continuous live
    ("Still live day {n} 📅", "{product} · Earn ₹{earn}. Tap to accept."),
    ("Day {n} · still paying 💸", "{store} · {product} · ₹{earn}."),
    ("Good morning earn ☀️", "{product} is still live · Accept."),
    ("Evening check 🌙", "Earn ₹{earn} on {product}."),
    ("Multi-day deal 🔥", "{product} hasn’t left. Earn ₹{earn}."),
    ("Still here. Still ₹{earn}. 👋", "{product} on {store}."),
    ("Day {n} reminder 🔔", "Accept {product} when ready."),
    ("Ongoing live ⚡", "{product} · Tap to accept."),
    ("Not expired yet ⏳", "Earn ₹{earn} · {product}."),
    ("Long weekend for this deal? 😎", "{product} · ₹{earn}."),
    ("Daily ping 📬", "{store} · Earn ₹{earn} · {product}."),
    ("Heavy reminder (on purpose) 🏋️", "Accept {product} · ₹{earn}."),
    ("We’re not shy 💜", "{product} still live."),
    ("Open Mintzer · still live 📲", "Earn ₹{earn}."),
    ("Day {n} drop-in 🚪", "{product} · Accept."),
    ("Continuous live 📡", "{product} · {store} · ₹{earn}."),
    ("Same deal. New day. 🌅", "Earn ₹{earn} on {product}."),
    ("Afternoon nudge 🌤️", "{product} waiting · ₹{earn}."),
    ("Night owl earn 🦉", "Accept {product} · Earn ₹{earn}."),
    ("Still on the board 📋", "{product} · Tap."),
    ("Multi-day money 💰", "Earn ₹{earn} · {product}."),
    ("Don’t wait for day 4 😅", "Accept {product} now."),
    ("Live streak continues 🔥", "{product} · ₹{earn}."),
    ("Check-in while it’s live ✅", "{store} · {product}."),
    ("Heavy cadence day {n} 📢", "Earn ₹{earn} · Accept."),
    ("We’re loud for a reason 📣", "{product} still live."),
    ("Return visit please 🙏", "Accept {product} · ₹{earn}."),
    ("Deal marathon 🏃", "{product} · Earn ₹{earn}."),
    ("Still accepting ✨", "{product} on {store}."),
    ("Day {n} · Tap to accept 👆", "Earn ₹{earn} · {product}."),
]

# Also refresh deal_live connectivity row note - keep existing bank; just append new sections

text = BANKS_PATH.read_text(encoding="utf-8")

# Remove old appendix-style duplicate sections if re-run
marker = "\n### deal_relist"
if "### deal_relist" in text or "### Deal relist" in text or "### 3.15" in text:
    # strip from first new section we might have added
    for cut in ["\n### Deal relist / live again", "\n### deal_relist", "\n### Viewed follow-up (30–60", "\n### Viewed follow-up (~1.5", "\n### Still-live (day 2"]:
        if cut in text:
            text = text[: text.index(cut)].rstrip() + "\n"
            break

addon = "\n\n---\n\n## Extra banks — frequent engagement (LOCKED)\n\n"
addon += bank(
    "Deal relist / live again",
    "Same deal turned **off → on again**. Always fire. Tokens include `{earn}` `{product}` `{store}`.",
    deal_relist,
)
addon += bank(
    "Viewed follow-up (30–60 min)",
    "User opened deal detail · no Accept · left. Tight engagement. Deep link: deal detail.",
    follow_early,
)
addon += bank(
    "Viewed follow-up (~1.5 hours)",
    "Second wave after view (and/or after early follow-up). Deep link: deal detail.",
    follow_mid,
)
addon += bank(
    "Still-live (day 2–3 heavy)",
    "Deal stays live across days. `{n}` = day number. Fire morning/evening (or every ~8–12h) while live.",
    still_live,
)

BANKS_PATH.write_text(text.rstrip() + "\n" + addon, encoding="utf-8")
print("Updated banks", BANKS_PATH)
print("relist", len(deal_relist), "early", len(follow_early), "mid", len(follow_mid), "still", len(still_live))
