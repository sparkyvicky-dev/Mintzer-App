# Module: Stores & cards catalog

**Status:** Client-supplied master list — September 2026  
**User app:** display + filter only. **Do not hardcode as the only source** in Flutter — load from API.  
**Admin:** create / edit / hide these entities. Separate product: `D:\dev\Mintzer-admin-app` (live `newapp` already has `ddlStoreID` and `ddlBankCardId`).

Mintzer letter tiles in the HTML demo are **placeholders**, not official bank/store logos.

---

## Plan (locked)

| Layer | What happens | When |
|-------|----------------|------|
| **User app demo** | Letter-tile marks + Home / Orders filters from this list | Now (mock) |
| **User app Flutter** | `GET /stores` · `GET /cards` · deal payload already has `store` + `card` | After design, with mock JSON first |
| **Admin app** | CRUD masters; pick store + card when posting a deal | **Separate repo** — not built inside the user app |
| **Official logos** | Admin uploads `logoUrl` later; app uses contain-in-box | When ops supplies assets |

**User-app v1 does not include an admin UI.** See [COMPLETE-DECISIONS-LOG.md](../COMPLETE-DECISIONS-LOG.md) §14 and [06-admin-operations.md](./06-admin-operations.md).

---

## Cards (payment methods on a deal)

`any` is always available for “Any credit / debit card” deals. Others are bank / co-brand cards.

| id | Label (app) | Tile | Notes |
|----|-------------|------|--------|
| `any` | Any credit / debit card | `cards/any.png` | Purple card glyph (not grey) |
| `onecard` | OneCard | OC | |
| `axis` | Axis Credit Card | AXIS | |
| `hdfc` | HDFC Credit Card | HDFC | |
| `icici` | ICICI Credit Card | ICICI | |
| `pnb` | PNB Credit Card | PNB | |
| `indusind` | IndusInd Credit Card | IND | |
| `rbl` | RBL Credit Card | RBL | |
| `flipkart-axis` | Flipkart Axis Card | F·AX | Co-brand — **card**, not a store |
| `sbi` | SBI Credit Card | SBI | |
| `kotak` | Kotak Credit Card | KOT | |
| `bob` | Bank of Baroda Card | BOB | |
| `idfc` | IDFC First Card | IDFC | |
| `amex` | American Express | AMEX | |
| `yes` | Yes Bank Card | YES | |
| `canara` | Canara Bank Card | CAN | |
| `hsbc` | HSBC Credit Card | HSBC | |
| `federal` | Federal Credit Card | FED | |
| `scapia` | Scapia | SCA | |

Admin may add **named products** later (Millennia, ACE, Regalia) as rows under the same bank `id`, or as child `cardProductId`. v1 deal payload uses one `card.id` from this table.

---

## Stores (where the user places the order)

Mix of marketplaces and brand / electronics sites.

| id | Label | Tile |
|----|-------|------|
| `flipkart` | Flipkart | FK |
| `amazon` | Amazon | AZ |
| `iqoo` | iQOO | IQ |
| `vivo` | vivo | VO |
| `oppo` | OPPO | OP |
| `reliance-digital` | Reliance Digital | RD |
| `jiomart` | JioMart | JM |
| `vijaysales` | Vijay Sales | VS |
| `sangeetha` | Sangeetha | SG |
| `myntra` | Myntra | MY |
| `motorola` | Motorola | MO |
| `shopsy` | Shopsy | SH |
| `instamart` | Instamart | IM |
| `tata-neu` | Tata Neu | TN |
| `apple` | Apple Store | AP |
| `imagine` | Imagine | IG |

---

## API (user app)

| Method | Path | Description |
|--------|------|-------------|
| GET | `/stores` | Active stores (`id`, `name`, `logoUrl`, `tile`) |
| GET | `/cards` | Active cards (`id`, `label`, `logoUrl`, `tile`, `applyUrl?`) |

Deals already embed store + card ([01-deals-and-pricing.md](./01-deals-and-pricing.md)):

```json
"store": { "id": "flipkart", "name": "Flipkart", "logoUrl": "..." },
"card": { "id": "axis", "label": "Axis Credit Card", "logoUrl": "..." }
```

Home filters: `?store=` · `?card=` using these ids.

## API (admin — future in admin app)

| Method | Path | Description |
|--------|------|-------------|
| GET / POST / PATCH | `/admin/stores` | Master list |
| GET / POST / PATCH | `/admin/cards` | Master list |
| PATCH | `/admin/stores/:id` · `/admin/cards/:id` | Hide (`active: false`) without deleting history |

### Adding a new store or bank (logo upload) — required

When ops adds a marketplace or bank card, admin must support **both** name and PNG (not letter-tile only):

| Field | Store | Card / bank |
|-------|--------|-------------|
| `id` | slug e.g. `croma` | slug e.g. `au` |
| `name` / `label` | display name | display label |
| `logoUrl` | **PNG upload** (square, transparent OK) | **PNG upload** (square, transparent OK) |
| `tile` | fallback 1–3 letters if logo missing | same |
| `active` | hide without deleting history | same |

**Upload rules (admin):**
- Accept PNG (preferred) or SVG→raster; max ~256×256; app displays with **contain** inside a circle — never crop/cover.
- After upload, CDN URL becomes `logoUrl` on `GET /stores` · `GET /cards` and on deal embed `store.logoUrl` / `card.logoUrl`.
- Flutter never hardcodes the catalog; new rows appear after sync without an app release.

Live web admin already picks store/card on deal create (`ddlStoreID`, `ddlBankCardId`). This catalog is the **seed list** to load into those dropdowns — extend those screens with **name + logo file** fields.

---

## App display rules

- **Home card:** store tile on image · card tile + label on bank row (marks sized large enough; PNG **contain**, no crop)
- **Deal detail:** LogoRow store + card  
- **Missing `logoUrl`:** Mintzer letter tile (never a broken image)  
- **Do not** ship official trademark SVGs in the demo
- **Urgency (Hot / slots):** stay on the **product photo** (top-right, or bottom-right if GST). Do **not** park chips in the gap above Earn — that gap is breathing room for the CTA; crowding it cheapens the card.
