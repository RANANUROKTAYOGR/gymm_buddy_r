import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../data/database/database_helper.dart';
import '../../data/models/equipment.dart';

class EquipmentListScreen extends StatefulWidget {
  const EquipmentListScreen({super.key});

  @override
  State<EquipmentListScreen> createState() => _EquipmentListScreenState();
}

class _EquipmentListScreenState extends State<EquipmentListScreen> {
  late Future<List<Equipment>> _equipmentListFuture;

  @override
  void initState() {
    super.initState();
    _equipmentListFuture = DatabaseHelper.instance.getAllEquipment();
  }

  Future<void> _openVideo(String url) async {
    final Uri uri = Uri.parse(url);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Video açılamadı')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Video açılırken hata oluştu: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1A1F3A), Color(0xFF0A0E27)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(),
              Expanded(
                child: FutureBuilder<List<Equipment>>(
                  future: _equipmentListFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return Center(
                        child: Text(
                          'Hata: ${snapshot.error}',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14.sp,
                          ),
                        ),
                      );
                    }
                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return Center(
                        child: Text(
                          'Kayıtlı ekipman bulunamadı.',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 16.sp,
                          ),
                        ),
                      );
                    }

                    final equipments = snapshot.data!;
                    return ListView.builder(
                      itemCount: equipments.length,
                      padding: EdgeInsets.all(16.w),
                      itemBuilder: (context, index) {
                        return _buildEquipmentCard(equipments[index]);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withAlpha((0.1 * 255).toInt()),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: IconButton(
              icon: Icon(Icons.arrow_back, color: Colors.white, size: 24.sp),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          SizedBox(width: 16.w),
          Text(
            'Ekipman Listesi',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEquipmentCard(Equipment item) {
    final bool hasVideo = item.videoUrl != null && item.videoUrl!.isNotEmpty;

    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha((0.05 * 255).toInt()),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: Colors.white.withAlpha((0.1 * 255).toInt()),
          width: 1,
        ),
      ),
      child: ListTile(
        contentPadding: EdgeInsets.all(16.w),
        leading: Container(
          padding: EdgeInsets.all(12.w),
          decoration: BoxDecoration(
            color: const Color(0xFF00FFA3).withAlpha((0.2 * 255).toInt()),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.fitness_center,
            color: const Color(0xFF00FFA3),
            size: 24.sp,
          ),
        ),
        title: Text(
          item.name,
          style: TextStyle(
            color: Colors.white,
            fontSize: 16.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 4.h),
            Text(
              (item.description != null && item.description!.isNotEmpty)
                  ? item.description!
                  : (item.type ?? 'Genel'),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white70,
                fontSize: 12.sp,
              ),
            ),
            if (item.brand != null) ...[
              SizedBox(height: 4.h),
              Text(
                '${item.brand} ${item.model ?? ''}',
                style: TextStyle(
                  color: const Color(0xFF00FFA3),
                  fontSize: 12.sp,
                ),
              ),
            ],
          ],
        ),
        trailing: hasVideo
            ? IconButton(
                tooltip: 'Kullanım Videosunu İzle',
                icon: Icon(
                  Icons.play_circle_fill,
                  color: Colors.red,
                  size: 32.sp,
                ),
                onPressed: () => _openVideo(item.videoUrl!),
              )
            : null,
      ),
    );
  }
}
