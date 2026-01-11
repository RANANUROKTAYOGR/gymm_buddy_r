import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'widgets/hydration_widget.dart';

class HydrationDetailScreen extends StatelessWidget {
  const HydrationDetailScreen({super.key, required this.userId});

  final int userId;

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Su Takibi'),
        backgroundColor: isDarkMode ? Colors.transparent : Colors.white,
        foregroundColor: isDarkMode ? Colors.white : Colors.black,
        elevation: 0,
        centerTitle: false,
      ),
      extendBodyBehindAppBar: true,
      backgroundColor: isDarkMode ? const Color(0xFF0A0E27) : Colors.white,
      body: Container(
        decoration: isDarkMode
            ? const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF0A0E27), Color(0xFF1A1F3A), Color(0xFF0A0E27)],
                ),
              )
            : const BoxDecoration(color: Colors.white),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(20.w),
            child: HydrationWidget(userId: userId),
          ),
        ),
      ),
    );
  }
}
