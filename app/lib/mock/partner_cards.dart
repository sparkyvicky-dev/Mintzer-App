import 'package:flutter/material.dart';

/// Partner card for Apply for cards. [applyUrl] opens bank/partner site when set.
class PartnerCardOffer {
  const PartnerCardOffer({
    required this.id,
    required this.bank,
    required this.name,
    this.applyUrl,
    this.imageUrl,
    this.accent = const Color(0xFF7B61FF),
    this.rewardUpto,
    this.loungeAccess = false,
    this.featured = false,
    this.featuredSort,
    this.liveBankId,
  });

  final String id;
  final String bank;
  final String name;
  final String? applyUrl;
  /// Live admin bank logo (HTTPS). Prefer over [logoAsset].
  final String? imageUrl;
  final Color accent;
  /// Admin reward ceiling. Null when the bank has no amount yet.
  final int? rewardUpto;
  final bool loungeAccess;
  /// Admin “On plan” — Show on Apply cards.
  final bool featured;
  final int? featuredSort;
  /// `banks.id` for the click log. Null on the offline sample list.
  final int? liveBankId;

  String? get logoAsset {
    // Packed card art only. Admin logo uploads are not used on this list.
    if (id.isEmpty || id.startsWith('bank_')) return null;
    if (id == 'any') return 'assets/logos/cards/any.png';
    return 'assets/logos/cards/$id.png';
  }

  bool get hasApplyUrl => (applyUrl ?? '').trim().isNotEmpty;
  bool get hasRemoteLogo => (imageUrl ?? '').trim().isNotEmpty;
  bool get hasBundledLogo => logoAsset != null;
}

/// Featured partner cards (live catalog ids match deal `cardId`).
List<PartnerCardOffer> get kPartnerCards => const [
      PartnerCardOffer(
        id: 'hdfc',
        bank: 'HDFC Bank',
        name: 'HDFC Credit Card',
        accent: Color(0xFF0B4F8A),
      ),
      PartnerCardOffer(
        id: 'axis',
        bank: 'Axis Bank',
        name: 'Axis Credit Card',
        accent: Color(0xFF97144D),
      ),
      PartnerCardOffer(
        id: 'amex',
        bank: 'American Express',
        name: 'American Express',
        accent: Color(0xFF006FCF),
      ),
      PartnerCardOffer(
        id: 'icici',
        bank: 'ICICI Bank',
        name: 'ICICI Credit Card',
        accent: Color(0xFFF57C00),
      ),
      PartnerCardOffer(
        id: 'bob',
        bank: 'Bank of Baroda',
        name: 'BoB Credit Card',
        accent: Color(0xFFE65100),
      ),
      PartnerCardOffer(
        id: 'sbi',
        bank: 'State Bank of India',
        name: 'SBI Credit Card',
        accent: Color(0xFF1565C0),
      ),
    ];
