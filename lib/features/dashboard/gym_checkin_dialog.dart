import 'package:flutter/material.dart';
import '../../services/gym_entry_service.dart';
import '../../data/database/database_helper.dart';

class GymCheckInDialog extends StatefulWidget {
  final GymEntryService gymEntryService;

  const GymCheckInDialog({
    super.key,
    required this.gymEntryService,
  });

  @override
  State<GymCheckInDialog> createState() => _GymCheckInDialogState();
}

class _GymCheckInDialogState extends State<GymCheckInDialog> {
  late Future<List<dynamic>> _gymsFuture;

  @override
  void initState() {
    super.initState();
    _gymsFuture = DatabaseHelper.instance.getAllGymBranches();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: const Color(0xFF1A1F3A),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1FD9C1), Color(0xFF5B9BCC)],
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.qr_code_2, color: Colors.white, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    widget.gymEntryService.isCheckedIn ? 'Çıkış Yap' : 'Giriş Yap',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(Icons.close, color: Colors.white),
                ),
              ],
            ),
          ),
          
          // Content
          Padding(
            padding: const EdgeInsets.all(24),
            child: widget.gymEntryService.isCheckedIn
                ? _buildCheckOutView()
                : _buildCheckInView(),
          ),
        ],
      ),
    );
  }

  Widget _buildCheckInView() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        FutureBuilder<List<dynamic>>(
          future: _gymsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: Color(0xFF1FD9C1)),
              );
            }

            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(
                child: Text(
                  'Salon bulunamadı',
                  style: TextStyle(color: Colors.white70),
                ),
              );
            }

            final gyms = snapshot.data!;

            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: gyms.length,
              itemBuilder: (context, index) {
                final gym = gyms[index];
                final gymName = gym.name ?? 'Salon ${index + 1}';

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.1),
                    ),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    title: Text(
                      gymName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: Text(
                      gym.city ?? 'Şehir bilinmiyor',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.6),
                        fontSize: 13,
                      ),
                    ),
                    trailing: const Icon(
                      Icons.arrow_forward_rounded,
                      color: Color(0xFF1FD9C1),
                    ),
                    onTap: () async {
                      await widget.gymEntryService.checkIn(gymName);
                      if (mounted) {
                        Navigator.pop(context);
                      }
                    },
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildCheckOutView() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF1FD9C1).withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFF1FD9C1).withOpacity(0.3),
            ),
          ),
          child: Column(
            children: [
              const Icon(
                Icons.check_circle,
                color: Color(0xFF1FD9C1),
                size: 48,
              ),
              const SizedBox(height: 12),
              Text(
                widget.gymEntryService.currentGymName ?? 'Salon',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${widget.gymEntryService.checkInTime?.hour}:${widget.gymEntryService.checkInTime?.minute.toString().padLeft(2, '0')} tarihinde giriş yaptınız',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.withOpacity(0.8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () async {
              await widget.gymEntryService.checkOut();
              if (mounted) {
                Navigator.pop(context);
              }
            },
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.logout, color: Colors.white),
                SizedBox(width: 8),
                Text(
                  'Çıkış Yap',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
