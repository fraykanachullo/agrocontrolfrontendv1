import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/agro_control_app_bar.dart';
import '../widgets/dispatch_form.dart';
import '../widgets/pending_shipment_card.dart';
import '../../../campanas/presentation/widgets/bottom_nav_bar.dart';

class CosechasScreen extends StatefulWidget {
  const CosechasScreen({super.key});

  @override
  State<CosechasScreen> createState() => _CosechasScreenState();
}

class _CosechasScreenState extends State<CosechasScreen> {
  int _selectedTab = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: const AgroControlAppBar(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            Text(
              'Cosechas y Despachos',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 16),

            // Tabs
            _buildTabs(),
            const SizedBox(height: 24),

            if (_selectedTab == 0) ...[
              // Dispatch Form
              const DispatchForm(),
              const SizedBox(height: 32),

              // Pending Shipments
              const PendingShipmentCard(),
            ] else ...[
              // History placeholder
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Text(
                    'Historial de despachos',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: AppColors.onSurfaceVariant,
                        ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
      bottomNavigationBar: const BottomNavBar(selectedIndex: 2),
    );
  }

  Widget _buildTabs() {
    return Container(
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppColors.outlineVariant),
        ),
      ),
      child: Row(
        children: [
          _buildTab(0, 'Despachos'),
          _buildTab(1, 'Historial'),
        ],
      ),
    );
  }

  Widget _buildTab(int index, String label) {
    final isSelected = _selectedTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTab = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isSelected ? AppColors.primary : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: isSelected
                      ? AppColors.primary
                      : AppColors.onSurfaceVariant,
                  fontWeight:
                      isSelected ? FontWeight.w600 : FontWeight.w400,
                ),
          ),
        ),
      ),
    );
  }
}
