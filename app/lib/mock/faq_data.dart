import 'package:flutter/material.dart';

/// FAQ EN from locked mintzer-faq.js (36 Qs). Teaches Earn · Bank cashback · Mintzer payout · Wallet.
class FaqItem {
  const FaqItem({required this.cat, required this.q, required this.a, this.popular = false});
  final String cat;
  final String q;
  final String a;
  final bool popular;
}

class FaqCatMeta {
  const FaqCatMeta({required this.id, required this.title, required this.icon, required this.color});
  final String id;
  final String title;
  final IconData icon;
  final Color color;
}

const kFaqCats = <FaqCatMeta>[
  FaqCatMeta(id: 'start', title: 'Getting started', icon: Icons.menu_book_rounded, color: Color(0xFF7B61FF)),
  FaqCatMeta(id: 'deals', title: 'Deals & money', icon: Icons.payments_outlined, color: Color(0xFF188038)),
  FaqCatMeta(id: 'order', title: 'Placing an order', icon: Icons.shopping_cart_outlined, color: Color(0xFF1A73E8)),
  FaqCatMeta(id: 'after', title: 'After you order', icon: Icons.inventory_2_outlined, color: Color(0xFFE37400)),
  FaqCatMeta(id: 'pay', title: 'Payouts & wallet', icon: Icons.account_balance_wallet_outlined, color: Color(0xFF7B61FF)),
  FaqCatMeta(id: 'account', title: 'Account & support', icon: Icons.person_outline_rounded, color: Color(0xFFC2185B)),
];

const kFaqItems = <FaqItem>[
  FaqItem(
    cat: 'start',
    q: 'What is Mintzer?',
    a: 'Mintzer lists Flipkart, Amazon and other store deals that work with specific cards. You accept a deal, place the order to our address, submit proof in the app, and we pay your earn to your bank.',
  ),
  FaqItem(
    cat: 'start',
    q: 'How do I earn?',
    popular: true,
    a: 'You pay the store checkout with the card on the deal. After delivery and invoice, Mintzer pays your earn (commission) to the bank account from KYC. Card cashback, if any, comes from your bank — not from us.',
  ),
  FaqItem(
    cat: 'start',
    q: 'Do I need a credit card?',
    a: 'Most deals need the card printed on the deal (often a credit card). Some say any credit or debit card. If you do not have that card, use Apply for cards from Profile, then come back to Home.',
  ),
  FaqItem(
    cat: 'start',
    q: 'Is Mintzer a bank?',
    a: 'No. We are not a bank and we do not hold a spendable wallet balance. Wallet in the app is your earn history. Payouts go to the bank account you added after PAN.',
  ),
  FaqItem(
    cat: 'start',
    q: 'Why do I ship to Mintzer\'s address?',
    a: 'The deal is completed only when the parcel comes to us and we can verify the invoice. Copy each address line into the store checkout. Do not send it to your home.',
  ),
  FaqItem(
    cat: 'start',
    q: 'Is this legal and safe?',
    a: 'You place a real order on the store, with a real card, to a real warehouse address. We verify what you ordered and then pay your earn. Use only the address and GST we show. Never share OTP or card PIN with anyone, including Mintzer support.',
  ),
  FaqItem(
    cat: 'deals',
    q: 'What does You spend mean?',
    a: 'You spend is what you pay at store checkout for that deal — order value, plus platform and card fees, minus any listed discount. It stays on one line next to the amount, even for ₹1,00,000-class totals.',
  ),
  FaqItem(
    cat: 'deals',
    q: 'What does Earn mean?',
    a: 'Earn is Mintzer commission paid to your bank after the order is verified. It is not the bank cashback. Cashback, if the card has it, is extra and follows your bank\'s rules.',
  ),
  FaqItem(
    cat: 'deals',
    q: 'Direct vs Link deals?',
    a: 'Direct deals open the store product (Flipkart / Amazon). Link deals open a payment page we list — finish with the same card shown on the deal, then place like a normal deal. Instant link deals pay within 24 working hours after you finish.',
  ),
  FaqItem(
    cat: 'deals',
    q: 'What does the GST tag mean?',
    a: 'GST deals need the company name and GST number from the address block on the store checkout. After delivery you must upload the matching GST invoice. Wrong GST can delay or cut payout.',
  ),
  FaqItem(
    cat: 'deals',
    q: 'Why platform fee and card fee?',
    a: 'They are part of You spend when the deal has them. The money card on Deal detail shows order value, fees, discount, checkout total, bank cashback, Mintzer payout, and You earn. Read that before you Accept.',
  ),
  FaqItem(
    cat: 'deals',
    q: 'What\'s the difference between bank cashback and Mintzer payout?',
    a: 'Bank cashback is from your card issuer, on their billing cycle. Mintzer payout is our payout after verification. Earn on a deal is Mintzer payout only.',
  ),
  FaqItem(
    cat: 'deals',
    q: 'I don\'t have the card on the deal',
    a: 'Do not Accept until you can pay with that card. Open Apply for cards, apply via the partner link, then use that card on matching Home deals.',
  ),
  FaqItem(
    cat: 'order',
    q: 'When do I Accept a deal?',
    a: 'Only when you can finish checkout with the right card, product, colour and qty before the timer ends. First Accept also asks for PAN (verified name) and payout bank details.',
  ),
  FaqItem(
    cat: 'order',
    q: 'Why is there a timer?',
    a: 'Each accepted deal holds a slot. The timer is how long you have to place the store order and paste the Order ID. If it runs out, that placement is released.',
  ),
  FaqItem(
    cat: 'order',
    q: 'Can I accept two deals at once?',
    a: 'No. Finish or cancel the current order first. Home shows a strip if a timer is still running. Deal detail blocks Accept until that one is done.',
  ),
  FaqItem(
    cat: 'order',
    q: 'Store app vs inside Mintzer?',
    a: 'Default is: open Flipkart/Amazon yourself, copy our address, come back and paste Order ID. You can switch to in-app browser. Remember this as default, or tap Change on Place order.',
  ),
  FaqItem(
    cat: 'order',
    q: 'How do I copy the address?',
    a: 'Copy each line (name, phone, address, pin, and company/GST when shown) into the matching field on the store. Do not type from memory. Generate new address only if we tell you the old one is burned.',
  ),
  FaqItem(
    cat: 'order',
    q: 'Wrong Order ID pasted',
    a: 'If you have not submitted yet, paste the correct ID and submit. If you already submitted, open Order detail → Report issue or Help, and tell us. Do not place a second order for the same deal.',
  ),
  FaqItem(
    cat: 'order',
    q: 'Timer expired. What now?',
    a: 'That slot is gone. Do not complete a store order for it. Go to Home and accept a live deal if you still want to earn.',
  ),
  FaqItem(
    cat: 'after',
    q: 'Where do I paste tracking?',
    a: 'My Orders → the order → Tracking step. Paste the tracking ID. Courier starts empty — we fill Ekart / Blue Dart / Xpressbees when the ID matches; tap to change if wrong.',
  ),
  FaqItem(
    cat: 'after',
    q: 'Delivery OTP and last 4 digits',
    a: 'When the parcel is out for delivery, enter the last 4 digits of the delivery phone and the 6+ digit OTP from the courier SMS. That is how we confirm the drop to our address.',
  ),
  FaqItem(
    cat: 'after',
    q: 'Why upload invoice?',
    popular: true,
    a: 'We match what you paid on the store with the deal. GST deals need the GST invoice. Upload opens after delivery is confirmed. Instant (link) deals follow the on-screen payment-page note instead of GST.',
  ),
  FaqItem(
    cat: 'after',
    q: 'Store canceled my order',
    a: 'Open Order detail → Report issue → Product canceled, or Cancel this order and pick Store canceled. Do not wait for payout on a canceled store order.',
  ),
  FaqItem(
    cat: 'after',
    q: 'Can I cancel after Accept?',
    a: 'Yes, from Place order or Order detail, with a reason. If the store order is already placed, cancel on the store too when you can, and tell us.',
  ),
  FaqItem(
    cat: 'pay',
    q: 'When do I get paid?',
    popular: true,
    a: 'After verification, Direct deals pay in 48 working hours. Instant (link) deals pay within 24 working hours after you finish. We do not pay on RBI / bank holidays. If the window ends on a holiday, it moves to the next working day.',
  ),
  FaqItem(
    cat: 'pay',
    q: 'Can I withdraw from Wallet?',
    a: 'No withdraw button in v1. Wallet shows Total earned (already paid to your bank) and Pending (still in the 48 working-hour queue). Money never sits as cash you pull from the app.',
  ),
  FaqItem(
    cat: 'pay',
    q: 'Where is payout sent?',
    a: 'To the bank account (and optional UPI) you saved after PAN. Account name must match the verified PAN name. Edit from Profile → Payout details.',
  ),
  FaqItem(
    cat: 'pay',
    q: 'Is there TDS?',
    a: 'If TDS applies on your earn, it is shown on the money breakdown for that order. The bank credit is after that deduction.',
  ),
  FaqItem(
    cat: 'account',
    q: 'What KYC do you need?',
    a: 'PAN only, on first Accept — not at login. You type PAN. Name is fetched from verification; you do not type the name. Then add bank / UPI for payout.',
  ),
  FaqItem(
    cat: 'account',
    q: 'Languages?',
    a: 'English, Hindi, Kannada, Malayalam. Change from the 5 EN bar on Login or Profile. It applies to the whole app immediately.',
  ),
  FaqItem(
    cat: 'account',
    q: 'Refer & earn?',
    a: 'Share your code from Profile. When a friend completes their first order, you both get ₹200 in Wallet history (paid out like other earn, not a withdrawable cash pot).',
  ),
  FaqItem(
    cat: 'account',
    q: 'How do I get help?',
    a: 'This FAQ, the Help chip on Home (ticket: topic → one question → short note), Order detail → Report issue, or My tickets. WhatsApp community is for deal drops, not private support.',
  ),
  FaqItem(
    cat: 'account',
    q: 'Delete account?',
    a: 'Profile → Delete account. Blocked if any order is still in progress (including payout wait). After delete you can sign up again with a new number.',
  ),
  FaqItem(
    cat: 'account',
    q: 'Account suspended?',
    a: 'A suspended number cannot use Home. Contact support from that screen. Do not try another phone to skip a suspension.',
  ),
  FaqItem(
    cat: 'account',
    q: 'Notifications and photo?',
    a: 'Profile controls deal alerts, order updates, and payout alerts. Tap the avatar to use a photo or switch back to your letter. Appearance is Light / Dark.',
  ),
];

List<FaqItem> get kPopularFaqItems => kFaqItems.where((i) => i.popular).toList();
