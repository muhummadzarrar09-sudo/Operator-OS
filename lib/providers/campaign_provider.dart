import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:operator_os/core/campaign_config.dart';
import 'package:shared_preferences/shared_preferences.dart';

final campaignSeasonStoreProvider = Provider<CampaignSeasonStore>((ref) {
  return CampaignSeasonStore();
});

final activeCampaignProvider = FutureProvider<ActiveCampaign>((ref) async {
  return ref.watch(campaignSeasonStoreProvider).load();
});

class CampaignSeasonStore {
  static const _campaignIdKey = 'active_campaign_id';
  static const _campaignStartedAtKey = 'active_campaign_started_at_ms';

  Future<ActiveCampaign> load() async {
    final prefs = await SharedPreferences.getInstance();
    final campaignId = prefs.getString(_campaignIdKey);
    final startedAtMs = prefs.getInt(_campaignStartedAtKey);
    final season = CampaignPresets.byId(campaignId);

    if (season == null || startedAtMs == null) {
      return const ActiveCampaign();
    }

    return ActiveCampaign(
      season: season,
      startedAt: DateTime.fromMillisecondsSinceEpoch(startedAtMs),
    );
  }

  Future<void> activate(CampaignSeason season) async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final normalized = DateTime(now.year, now.month, now.day);
    await prefs.setString(_campaignIdKey, season.id);
    await prefs.setInt(_campaignStartedAtKey, normalized.millisecondsSinceEpoch);
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_campaignIdKey);
    await prefs.remove(_campaignStartedAtKey);
  }
}
