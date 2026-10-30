import '../api/banks_api.dart';
import '../config/app_config.dart';
import '../mock/partner_cards.dart';
import '../mock/session.dart';

/// Apply-for-cards catalog — live banks when admin has rows; else designed fallback.
class PartnerCardsRepository {
  PartnerCardsRepository._();
  static final instance = PartnerCardsRepository._();

  Future<void> refreshFromLiveApi() async {
    if (!AppConfig.useLiveDealsApi) {
      MockSession.partnerCards.value = List.from(kPartnerCards);
      return;
    }
    try {
      final live = await BanksApi.instance.fetchBanks();
      if (live.isNotEmpty) {
        MockSession.partnerCards.value = live;
        return;
      }
    } catch (_) {}
    MockSession.partnerCards.value = List.from(kPartnerCards);
  }
}
