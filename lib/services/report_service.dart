import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../data/database/database_helper.dart';

/// Aylık gelişim raporu oluşturan servis
class ReportService {
  final DatabaseHelper _db = DatabaseHelper.instance;

  /// Son 30 günün workout verilerini ve body measurements'ı çeker
  Future<Map<String, dynamic>> getMonthlyData(int userId) async {
    // Workout session'ları getir (son 30 günü al)
    final allSessions = await _db.getLastDaysActivity(userId, 30);

    // Body measurements'ı getir
    final allMeasurements = await _db.getBodyMeasurementsByUser(userId);

    // Workout detaylarını getir (egzersizler ve setler)
    List<Map<String, dynamic>> workoutDetails = [];
    for (var session in allSessions) {
      final exerciseLogs = await _db.getExerciseLogsBySession(session.id!);
      double totalWeight = 0;

      for (var exerciseLog in exerciseLogs) {
        final sets = await _db.getSetDetailsByLog(exerciseLog.id!);
        for (var set in sets) {
          totalWeight += (set.weight ?? 0) * (set.reps ?? 0);
        }
      }

      // Sürü hesapla: end_time - start_time (dakika olarak)
      int duration = 0;
      if (session.endTime != null) {
        duration = session.endTime!.difference(session.startTime).inMinutes;
      }

      workoutDetails.add({
        'date': session.startTime.toString(),
        'duration': duration,
        'exercises': exerciseLogs.length,
        'totalWeight': totalWeight,
      });
    }

    // Başlangıç ve güncel kilo
    double? startWeight;
    double? currentWeight;

    if (allMeasurements.isNotEmpty) {
      final sortedByDate = [...allMeasurements]
        ..sort((a, b) => a.measurementDate.compareTo(b.measurementDate));

      startWeight = sortedByDate.first.weight;
      currentWeight = sortedByDate.last.weight;
    }

    // Toplam antrenman süresi (dakika)
    int totalDuration = 0;
    for (var session in allSessions) {
      if (session.endTime != null) {
        totalDuration += session.endTime!.difference(session.startTime).inMinutes.toInt();
      }
    }

    double totalWeight = workoutDetails.fold(0, (sum, w) => sum + (w['totalWeight'] as double));

    return {
      'workoutDetails': workoutDetails,
      'allMeasurements': allMeasurements,
      'totalDuration': totalDuration,
      'totalWeight': totalWeight,
      'startWeight': startWeight,
      'currentWeight': currentWeight,
      'totalWorkouts': allSessions.length,
    };
  }

  /// PDF belgesi oluştur
  Future<pw.Document> generatePDF(String userName, int userId) async {
    final data = await getMonthlyData(userId);
    final pdf = pw.Document();

    // Turkish characters need Unicode-capable fonts
    final baseFont = pw.Font.helvetica();
    final boldFont = pw.Font.helveticaBold();

    final tealColor = PdfColor.fromInt(0xFF1FD9C1);
    final blueColor = PdfColor.fromInt(0xFF5B9BCC);

    pdf.addPage(
      pw.Page(
        pageTheme: pw.PageTheme(
          theme: pw.ThemeData(
            defaultTextStyle: pw.TextStyle(font: baseFont),
          ),
        ),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Başlık
              pw.Container(
                padding: const pw.EdgeInsets.all(20),
                decoration: pw.BoxDecoration(
                  color: tealColor,
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(10)),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'GymBuddy Gelişim Raporu',
                      style: pw.TextStyle(
                        font: boldFont,
                        fontSize: 28,
                        color: PdfColors.white,
                      ),
                    ),
                    pw.SizedBox(height: 5),
                    pw.Text(
                      'Kullanıcı: $userName',
                      style: pw.TextStyle(
                        fontSize: 14,
                        color: PdfColors.white,
                      ),
                    ),
                    pw.SizedBox(height: 5),
                    pw.Text(
                      'Rapor Tarihi: ${DateTime.now().toString().split('.')[0]}',
                      style: pw.TextStyle(
                        fontSize: 12,
                        color: PdfColors.white,
                      ),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 20),

              // Özet Kartlar
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
                children: [
                  _buildSummaryCard(
                    'Toplam Antrenman',
                    '${data['totalWorkouts']}',
                    tealColor,
                  ),
                  _buildSummaryCard(
                    'Toplam Süre',
                    '${(data['totalDuration'] as int).toString()} dk',
                    blueColor,
                  ),
                  _buildSummaryCard(
                    'Toplam Ağırlık',
                    '${(data['totalWeight'] as double).toStringAsFixed(0)} kg',
                    tealColor,
                  ),
                ],
              ),
              pw.SizedBox(height: 20),

              // Antrenman Tablosu
              pw.Text(
                'Antrenman Detayları',
                style: pw.TextStyle(
                  font: boldFont,
                  fontSize: 16,
                ),
              ),
              pw.SizedBox(height: 10),
              _buildWorkoutTable(data['workoutDetails'] as List<Map<String, dynamic>>),
              pw.SizedBox(height: 20),

              // Kilo Değişimi
              if (data['startWeight'] != null && data['currentWeight'] != null)
                pw.Container(
                  padding: const pw.EdgeInsets.all(15),
                  decoration: pw.BoxDecoration(
                    color: blueColor,
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'Kilo Değişimi',
                        style: pw.TextStyle(
                          font: boldFont,
                          fontSize: 14,
                          color: PdfColors.white,
                        ),
                      ),
                      pw.SizedBox(height: 10),
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text(
                                'Başlangıç Kilosu',
                                style: pw.TextStyle(
                                  fontSize: 12,
                                  color: PdfColors.grey,
                                ),
                              ),
                              pw.Text(
                                '${(data['startWeight'] as double).toStringAsFixed(1)} kg',
                                style: pw.TextStyle(
                                  fontSize: 16,
                                  fontWeight: pw.FontWeight.bold,
                                  color: PdfColors.white,
                                ),
                              ),
                            ],
                          ),
                          pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text(
                                'Güncel Kilosu',
                                style: pw.TextStyle(
                                  fontSize: 12,
                                  color: PdfColors.grey,
                                ),
                              ),
                              pw.Text(
                                '${(data['currentWeight'] as double).toStringAsFixed(1)} kg',
                                style: pw.TextStyle(
                                  fontSize: 16,
                                  fontWeight: pw.FontWeight.bold,
                                  color: PdfColors.white,
                                ),
                              ),
                            ],
                          ),
                          pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text(
                                'Değişim',
                                style: pw.TextStyle(
                                  fontSize: 12,
                                  color: PdfColors.grey,
                                ),
                              ),
                              pw.Text(
                                '${((data['startWeight'] as double) - (data['currentWeight'] as double)).toStringAsFixed(1)} kg',
                                style: pw.TextStyle(
                                  fontSize: 16,
                                  fontWeight: pw.FontWeight.bold,
                                  color: ((data['startWeight'] as double) > (data['currentWeight'] as double))
                                      ? PdfColor.fromInt(0xFF00FF00)
                                      : PdfColor.fromInt(0xFFFF0000),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              pw.SizedBox(height: 20),

              // Footer
              pw.Divider(),
              pw.SizedBox(height: 10),
              pw.Text(
                'Bu rapor GymBuddy uygulaması tarafından otomatik olarak oluşturulmuştur.',
                style: pw.TextStyle(
                  fontSize: 10,
                  color: PdfColors.grey700,
                ),
              ),
            ],
          );
        },
      ),
    );

    return pdf;
  }

  pw.Widget _buildSummaryCard(String title, String value, PdfColor color) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: color,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
      ),
      child: pw.Column(
        children: [
          pw.Text(
            title,
            style: pw.TextStyle(
              fontSize: 10,
              color: PdfColors.white,
            ),
          ),
          pw.SizedBox(height: 5),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.white,
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildWorkoutTable(List<Map<String, dynamic>> workouts) {
    if (workouts.isEmpty) {
      return pw.Text('Bu ay veri bulunamadı.');
    }

    return pw.Table(
      border: pw.TableBorder.all(
        color: PdfColors.grey,
        width: 0.5,
      ),
      children: [
        // Header
        pw.TableRow(
          decoration: pw.BoxDecoration(
            color: PdfColor.fromInt(0xFF1FD9C1),
          ),
          children: [
            _buildTableCell('Tarih', true),
            _buildTableCell('Süre (dk)', true),
            _buildTableCell('Egzersiz', true),
            _buildTableCell('Toplam Ağırlık', true),
          ],
        ),
        // Data rows
        ...workouts.take(10).map((w) {
          return pw.TableRow(
            children: [
              _buildTableCell(w['date'].toString().split(' ')[0], false),
              _buildTableCell('${w['duration']}', false),
              _buildTableCell('${w['exercises']}', false),
              _buildTableCell('${(w['totalWeight'] as double).toStringAsFixed(0)} kg', false),
            ],
          );
        }).toList(),
      ],
    );
  }

  pw.Widget _buildTableCell(String text, bool isHeader) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: isHeader ? 11 : 10,
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
          color: isHeader ? PdfColors.white : PdfColors.black,
        ),
      ),
    );
  }
}
