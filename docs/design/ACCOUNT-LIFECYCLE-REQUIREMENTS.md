# Account lifecycle — suspended & delete (LOCKED v1)

**Status:** LOCKED v1 — 2026-06-03  
**Flow mockup:** `assets/mockups/mintzer-full-flow.html`

---

## Account suspended (terminated / banned)

When ops marks a user **suspended** (terminated), the app must block normal use.

### When shown

| Trigger | Behavior |
|---------|----------|
| OTP verify success but user `status = suspended` | Navigate to **Account suspended** — do not enter Home |
| Active session; API returns `403 ACCOUNT_SUSPENDED` | Replace stack with **Account suspended** |
| Login phone step | Optional early message after phone lookup if backend supports it |

### Screen copy (simple)

**Title:** Account suspended  

**Body:**  
Your account is not active right now. Please contact support if you want to restore access.

**Primary button:** Contact support → WhatsApp or email from `GET /config/support`  

**Secondary:** Log out / Back to login  

Do **not** use harsh words (“banned”, “terminated”) in UI — use **suspended** + **contact support**.

---

## Delete account (Profile)

### Where

**Profile → Settings** — row **Delete account** (destructive style, below Privacy Policy).

Not on Login. Not on Wallet.

### Rules (LOCKED)

| Rule | Detail |
|------|--------|
| Block delete if | **Any active placement** (Place order timer running) **or** any order **in progress** (not completed / not cancelled) |
| Allow delete if | No ongoing order and no active placement |
| After delete | Log out · show **Account deleted** screen · clear local session |
| Data | Backend soft-delete or anonymize per policy — app only shows success UI |

### Blocked copy

**Title:** Can’t delete account yet  

**Body:**  
You have an order in progress. Please finish or cancel it before deleting your account.

**Button:** OK → dismiss (optional **Go to My Orders**)

### Confirm copy

**Title:** Delete account?  

**Body:**  
This permanently removes your Mintzer account. You won’t be able to log in again with this number.

**Actions:** Cancel · **Delete account** (destructive confirm)

Optional v1: checkbox “I understand this cannot be undone”.

### Account deleted screen

**Title:** Account deleted  

**Body:**  
Your account has been removed. Contact support if you need help.

**Button:** Back to login  

---

## Backend (summary)

| Endpoint | Purpose |
|----------|---------|
| `GET /user/profile` | includes `status`: `active` \| `suspended` |
| `POST /user/account/delete` | delete if allowed; returns `409` if orders in progress |
| `GET /config/support` | support links for suspended + deleted screens |

---

## Decision log

| Topic | Decision |
|-------|----------|
| Suspended UI wording | “Account suspended” + contact support |
| Delete location | Profile → Settings |
| Delete block | Active placement or in-progress order |
| Post-delete UI | Dedicated screen → Login |
| HTML flow | `mintzer-full-flow.html` |
