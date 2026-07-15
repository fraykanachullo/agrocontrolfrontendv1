import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/agro_control_app_bar.dart';
import '../widgets/kpi_summary_card.dart';
import '../widgets/campaign_details_card.dart';
import '../widgets/quick_actions.dart';
import '../../../campanas/presentation/widgets/bottom_nav_bar.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const AgroControlAppBar(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // KPI Summary Card
            const KpiSummaryCard(),
            const SizedBox(height: 12),

            // Campaign Details Card
            const CampaignDetailsCard(),
            const SizedBox(height: 12),

            // Quick Actions
            const QuickActions(),
          ],
        ),
      ),
      bottomNavigationBar: const BottomNavBar(selectedIndex: 0),
    );
  }
}
