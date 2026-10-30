# Screen: FAQ

**Status:** **LOCKED** (20 Sep 2026 — consumer polish)  
**Flutter:** `app/lib/screens/faq_screen.dart` · `app/lib/mock/faq_data.dart`

## Purpose

Common questions, one tap to expand the answer. Not a ticket. Not a chatbot.

Teaches locked money terms: **Earn** (user profit) · **Bank cashback** (issuer) · **Mintzer payout** (what we pay) · **Wallet** (record/status only).

## Entry

- Profile → Help Center / FAQs
- Help sheet → **Read FAQ**

## UI (LOCKED)

| Element | Rule |
|---------|------|
| Header | Back · large **FAQ** · subtitle **Quick answers about deals, orders and payouts.** |
| Search | **Search FAQs** — filters Q+A live |
| Popular | Star card · 3 common Qs as compact rows · See all → categories |
| Categories | One card per section · colored icon · N questions · expand header → question rows with thin dividers |
| Question row | ~56–64px closed · expanded: soft purple wash + chevron ↑ · concise 2–4 line answers |
| Footer | **Still need help?** → Contact support |

**Categories (keep order):** Getting started · Deals & money · Placing an order · After you order · Payouts & wallet · Account & support

## Copy fixes (vs first Flutter pass)

| Old | New |
|-----|-----|
| How Mintzer works (as page lead) | Subtitle above |
| What is the 7-step order rail? | How do I track my order? |
| Bank cashback vs From Mintzer? | What’s the difference between bank cashback and Mintzer payout? |
| When do I add PAN? | Why do I need to verify my PAN? |

## Must not

- Rotate answers on a timer
- Promise same-day payout
- Show a Wallet withdraw path
- Ask for KYC at login in any answer
- Standalone card per question (too tall)

## 14 Oct 2026

Not part of the delivery-call update. This screen stays as written above.
