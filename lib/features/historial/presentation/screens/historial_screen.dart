import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/agro_control_app_bar.dart';
import '../widgets/calendar_widget.dart';
import '../widgets/timeline_widget.dart';
import '../../../campanas/presentation/widgets/bottom_nav_bar.dart';

class HistorialScreen extends StatelessWidget {
  const HistorialScreen({super.key});

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
            // Calendar
            const CalendarWidget(),
            const SizedBox(height: 16),

            // Timeline
            const TimelineWidget(),
          ],
        ),
      ),
      bottomNavigationBar: const BottomNavBar(selectedIndex: 3),
    );
  }
}
