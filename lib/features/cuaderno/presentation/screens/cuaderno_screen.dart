import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/agro_control_app_bar.dart';
import '../widgets/activity_form.dart';
import '../widgets/activity_history_list.dart';
import '../../../campanas/presentation/widgets/bottom_nav_bar.dart';

class CuadernoScreen extends StatefulWidget {
  const CuadernoScreen({super.key});

  @override
  State<CuadernoScreen> createState() => _CuadernoScreenState();
}

class _CuadernoScreenState extends State<CuadernoScreen> {
  int _selectedTab = 0;
  final _tabs = ['Actividad', 'Gasto', 'Ingreso'];

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
            Text(
              'Cuaderno de Campo',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 24),

            // Tab chips
            _buildTabChips(),
            const SizedBox(height: 24),

            // Form
            ActivityForm(
              type: _tabs[_selectedTab],
            ),
            const SizedBox(height: 32),

            // History
            const ActivityHistoryList(),
          ],
        ),
      ),
      bottomNavigationBar: const BottomNavBar(selectedIndex: 1),
    );
  }

  Widget _buildTabChips() {
    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _tabs.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final isSelected = _selectedTab == index;
          return GestureDetector(
            onTap: () => setState(() => _selectedTab = index),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 24),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary
                    : AppColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(999),
                border: isSelected
                    ? null
                    : Border.all(color: AppColors.outlineVariant),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.3),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              alignment: Alignment.center,
              child: Text(
                _tabs[index],
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: isSelected
                          ? AppColors.onPrimary
                          : AppColors.onSurfaceVariant,
                    ),
              ),
            ),
          );
        },
      ),
    );
  }
}
