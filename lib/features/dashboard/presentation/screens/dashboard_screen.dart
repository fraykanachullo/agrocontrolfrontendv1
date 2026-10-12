import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/app_providers.dart';
import '../widgets/kpi_summary_card.dart';
import '../widgets/campaign_details_card.dart';
import '../widgets/balance_widget.dart';
import '../widgets/quick_actions.dart';

class DashboardScreen extends ConsumerWidget {
  final String campaignId;

  const DashboardScreen({super.key, required this.campaignId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardData = ref.watch(dashboardDataProvider);
    final campana = ref.watch(activeCampanaProvider);
    final campanaId = int.tryParse(campaignId) ?? 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          KpiSummaryCard(data: dashboardData.value),
          const SizedBox(height: 12),
          CampaignDetailsCard(campana: campana),
          const SizedBox(height: 12),
          BalanceWidget(campanaId: campanaId),
          const SizedBox(height: 12),
          const QuickActions(),
        ],
      ),
    );
  }
}
