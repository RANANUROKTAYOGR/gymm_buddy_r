import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:printing/printing.dart';
import '../../services/report_service.dart';
import '../../services/theme_service.dart';

class ReportScreen extends StatefulWidget {
  final int userId;

  const ReportScreen({Key? key, required this.userId}) : super(key: key);

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  final ReportService _reportService = ReportService();
  bool _isLoading = false;

  Future<void> _generateAndPreviewReport() async {
    setState(() => _isLoading = true);

    try {
      final pdf = await _reportService.generatePDF('GymBuddy Kullanıcısı', widget.userId);
      
      if (mounted) {
        await Printing.layoutPdf(
          name: 'GymBuddy_Gelisim_Raporu.pdf',
          onLayout: (_) => pdf.save(),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _shareReport() async {
    setState(() => _isLoading = true);

    try {
      final pdf = await _reportService.generatePDF('GymBuddy Kullanıcısı', widget.userId);
      final bytes = await pdf.save();
      
      await Printing.sharePdf(
        bytes: bytes,
        filename: 'GymBuddy_Gelisim_Raporu.pdf',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDarkMode ? const Color(0xFF0A0E27) : Colors.white;
    final textColor = isDarkMode ? Colors.white : Colors.black;
    final cardBgColor = isDarkMode ? const Color(0xFF1A1F3A) : Colors.grey[100];
    
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: const Text('Aylık Gelişim Raporu'),
        backgroundColor: const Color(0xFF1FD9C1),
        elevation: 0,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: EdgeInsets.all(16.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // İlk Bilgilendirme Kartı
                Container(
                  padding: EdgeInsets.all(16.w),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1FD9C1).withOpacity(isDarkMode ? 0.15 : 0.1),
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(
                      color: const Color(0xFF1FD9C1),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: const Color(0xFF1FD9C1),
                            size: 24.sp,
                          ),
                          SizedBox(width: 12.w),
                          Expanded(
                            child: Text(
                              'Son 30 günün antrenman verilerinden oluşan kapsamlı raporunuz',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: const Color(0xFF1FD9C1),
                                    fontWeight: FontWeight.w500,
                                    fontSize: 14.sp,
                                  ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 24.h),

                // Rapor İçeriği
                Text(
                  'Rapor İçeriği',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: textColor,
                        fontSize: 20.sp,
                      ),
                ),
                SizedBox(height: 12.h),
                _buildReportFeature(
                  context,
                  Icons.insert_chart_outlined,
                  'Antrenman Özeti',
                  'Toplam antrenman sayısı, süresi ve tamamlanan egzersizler',
                  isDarkMode,
                ),
                SizedBox(height: 8.h),
                _buildReportFeature(
                  context,
                  Icons.fitness_center,
                  'Ağırlık Analizi',
                  'Toplam kaldırılan ağırlık ve antrenman detayları',
                  isDarkMode,
                ),
                SizedBox(height: 8.h),
                _buildReportFeature(
                  context,
                  Icons.trending_down,
                  'Kilo Takibi',
                  'Başlangıç ve güncel kilonuz arasındaki değişim',
                  isDarkMode,
                ),
                SizedBox(height: 8.h),
                _buildReportFeature(
                  context,
                  Icons.table_chart,
                  'Detaylı Tablo',
                  'Tarih, süre, egzersiz sayısı ve ağırlık tablosu',
                  isDarkMode,
                ),
                SizedBox(height: 32.h),

                // Buton Alanı
                Text(
                  'Raporunuz',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: textColor,
                        fontSize: 20.sp,
                      ),
                ),
                SizedBox(height: 12.h),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _generateAndPreviewReport,
                    icon: _isLoading
                        ? SizedBox(
                            width: 20.w,
                            height: 20.w,
                            child: const CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.preview),
                    label: Text(_isLoading ? 'Hazırlanıyor...' : 'Raporu Önizle', style: TextStyle(fontSize: 16.sp)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1FD9C1),
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 16.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 12.h),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _isLoading ? null : _shareReport,
                    icon: const Icon(Icons.share),
                    label: Text('Raporu Paylaş', style: TextStyle(fontSize: 16.sp)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF5B9BCC),
                      side: const BorderSide(
                        color: Color(0xFF5B9BCC),
                        width: 2,
                      ),
                      padding: EdgeInsets.symmetric(vertical: 16.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 32.h),
              ],
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1FD9C1)),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildReportFeature(
    BuildContext context,
    IconData icon,
    String title,
    String description,
    bool isDarkMode,
  ) {
    final cardBgColor = isDarkMode ? const Color(0xFF1A1F3A) : Colors.grey[100];
    final textColor = isDarkMode ? Colors.white : Colors.black;
    final descColor = isDarkMode ? Colors.grey[400] : Colors.grey[600];
    
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: cardBgColor,
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: const Color(0xFF5B9BCC),
            size: 24.sp,
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: textColor,
                        fontSize: 16.sp,
                      ),
                ),
                SizedBox(height: 4.h),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: descColor,
                        fontSize: 12.sp,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
