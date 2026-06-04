# Home — ChatGPT → Figma prompt (LOCKED)

**Spec:** [../screens/02-home.md](../screens/02-home.md)  
**HTML reference:** `assets/mockups/home-samples.html`

---

## How to use

1. Paste **BLOCK A** from [FIGMA-CHATGPT-PROMPT-RULES.md](./FIGMA-CHATGPT-PROMPT-RULES.md)
2. Paste **BLOCK B** below (or paste full `02-home.md`)
3. Ask: *Write one Figma AI prompt for Home — List view default frame named "Home — List". Include one sample deal card with all locked elements.*
4. Paste ChatGPT output into Figma AI
5. Duplicate frame → rename **Home — Grid** · toggle grid layout per spec

---

## BLOCK B — Home LOCKED prompt (copy from here)

```
SCREEN: Home — LOCKED June 2026
Reference: assets/mockups/home-samples.html — match exactly

Create ONE mobile frame named "Home — List" (360×800 or 390×844).

APP: Mintzer — Earn with Credit Cards

STYLE: Google Material 3 Light — match Login screen exactly
- NOT purple gradients · NOT dark/orange competitor theme · NOT glassmorphism
- Primary #1A73E8 · Background #F8F9FA · Surface #FFFFFF · Border #E8EAED
- Text #202124 · Secondary #5F6368
- Auto Layout · 16dp padding · 8dp spacing · scrollable content · fixed bottom nav

HEADER (white, ~64dp):
- Left: "Hi, Arun" bold #202124 + "Earn with your card" #5F6368 11sp
- Right: Wallet pill "₹1,240" #1A73E8 · Bell + red dot · WhatsApp green icon #25D366 on #E7F8EE circle

TOOLBAR:
- Search field full width, radius 24dp, placeholder "Search deals..."
- View toggle: List icon ACTIVE #1A73E8 · Grid icon inactive #5F6368

FILTER CHIPS (horizontal):
- "All Deals" selected #E8F0FE border #1A73E8
- "Direct" · "Link" · filter funnel icon

TUTORIAL BANNER (show for "Home — First visit" frame only — omit on default):
- #E8F0FE card · play icon · "New here? Watch how Mintzer works" · dismiss X

LIST META:
- Left: "3 deals live" #5F6368
- Right: "Highest earn ↓" #1A73E8

DEAL CARD — LIST (show 3 cards, vertical scroll):

Each card: white #FFFFFF, border #E8EAED, radius 12dp

CARD ANATOMY (each fact ONCE — never duplicate):

Row 1 — grid 80dp image | text column:
- Image box 80×80dp #F8F9FA, object-fit CONTAIN for product photo
- Store logo badge TOP-LEFT on image only (Flipkart yellow FK tile 24dp)
- NO GST on image

- Title bold: e.g. "Motorola G57 Power 5G"
- Meta row flex: color left "Midnight Blue" #5F6368 · GST pill RIGHT only if gst deal
  GST pill: #FEF7E0 bg #E37400 text 8sp — omit entirely if not GST deal

Full width below:
- Bank row: grey box #F8F9FA · bank/card logo 26dp + label e.g. "HDFC Credit Card"

- SPEND BOX (light blue — NOT plain text):
  bg #E8F0FE · border #D2E3FC · radius 8dp · flex space-between
  Left label "YOU SPEND" #1A73E8 10sp bold uppercase
  Right amount "₹17,519" #202124 15sp bold

- EARN BUTTON (primary CTA — BLUE not green):
  Full width · #1A73E8 · white text · "Earn ₹300" · radius 10dp · min 44dp height

Sample deal 1: Motorola · Midnight Blue · GST · FK · Any card · Spend ₹17,519 · Earn ₹300
Sample deal 2: Samsung M35 · Any color · NO GST badge · Amazon · HDFC · Spend ₹22,999 · Earn ₹450
Sample deal 3: Samsung TV 32" · Black · GST · FK · Axis · Spend ₹12,499 · Earn ₹380

FAB: #1A73E8 circle bottom-right above nav · chat icon white

BOTTOM NAV (fixed 56dp white, border top #E8EAED):
Home ACTIVE #1A73E8 · Orders · Wallet · Profile #5F6368

DEFAULT STATE: No active order strip · no empty state · no loading

FOR "Home — Grid" frame: same chrome · 2-column deal grid · same card fields compact · Earn button bottom-aligned in each card · title 2-line min-height for alignment

DO NOT: duplicate earn/spend · green earn button · "No GST" label · variant · qty · Offers tab

Style: Material light Mintzer v1 — Home LOCKED
```
