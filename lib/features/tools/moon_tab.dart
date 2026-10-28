import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:eclipseverse/theme/app_theme.dart';

class MoonTab extends StatelessWidget {
  const MoonTab({super.key});

  static const double _synodicMonth = 29.530588853;
  static final DateTime _knownNewMoon = DateTime.utc(2000, 1, 6, 18, 14);

  double _phaseFraction(DateTime date) {
    final days = date.toUtc().difference(_knownNewMoon).inSeconds / 86400;
    return (days / _synodicMonth - (days / _synodicMonth).floorToDouble());
  }

  String _phaseName(double phase) {
    if (phase < 0.035 || phase >= 0.965) return 'Bulan Baru';
    if (phase < 0.22) return 'Sabit Muda';
    if (phase < 0.28) return 'Perbani Awal';
    if (phase < 0.47) return 'Cembung Membesar';
    if (phase < 0.53) return 'Purnama';
    if (phase < 0.72) return 'Cembung Mengecil';
    if (phase < 0.78) return 'Perbani Akhir';
    return 'Sabit Tua';
  }

  String _phaseEmoji(double phase) {
    if (phase < 0.035 || phase >= 0.965) return '🌑';
    if (phase < 0.22) return '🌒';
    if (phase < 0.28) return '🌓';
    if (phase < 0.47) return '🌔';
    if (phase < 0.53) return '🌕';
    if (phase < 0.72) return '🌖';
    if (phase < 0.78) return '🌗';
    return '🌘';
  }

  String _indonesianDate(DateTime date) {
    const weekdays = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'];
    const months = ['Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni', 'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'];
    return '${weekdays[date.weekday - 1]}, ${date.day} ${months[date.month - 1]} ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final phase = _phaseFraction(now);
    final illumination = ((1 - math.cos(2 * math.pi * phase)) / 2 * 100).round();
    final nextNewMoonDays = (1 - phase) * _synodicMonth;
    final nextFullMoonDays = ((0.5 - phase + 1) % 1) * _synodicMonth;
    final nextMoonEvent = nextNewMoonDays < nextFullMoonDays
        ? 'Bulan Baru'
        : 'Purnama';
    final daysUntilMoonEvent = math.min(nextNewMoonDays, nextFullMoonDays).round();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            gradient: AppTheme.cosmicHeroGradient,
            borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
            border: Border.all(color: AppTheme.borderSubtle),
          ),
          child: Stack(
            children: [
              const Positioned(
                right: 0, top: 0,
                child: Icon(Icons.auto_awesome, size: 58, color: Color(0x55FFFFFF)),
              ),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('LUNAR OBSERVATORY', style: TextStyle(color: AppTheme.coolCyan, fontSize: 10, letterSpacing: 1.5, fontWeight: FontWeight.w800)),
                const SizedBox(height: 12),
                Text('Kenali Bulan\ndi langit malam', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontSize: 26, height: 1.15)),
                const SizedBox(height: 8),
                const Text('Pantau fase Bulan dan jadwal gerhana berikutnya dari Eclipse Tools.', style: TextStyle(color: AppTheme.textSecondary, height: 1.5)),
              ]),
            ],
          ),
        ),
        const SizedBox(height: 18),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: AppTheme.cardGradient,
            borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
            border: Border.all(color: AppTheme.eclipseViolet.withValues(alpha: 0.45)),
          ),
          child: Column(children: [
            const Row(children: [
              Icon(Icons.nightlight_round, color: AppTheme.coronaGold),
              SizedBox(width: 8),
              Text('FASE BULAN SAAT INI', style: TextStyle(color: AppTheme.coolCyan, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1)),
            ]),
            const SizedBox(height: 14),
            Text(_phaseEmoji(phase), style: const TextStyle(fontSize: 86)),
            const SizedBox(height: 4),
            Text(_phaseName(phase), style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 6),
            Text(_indonesianDate(now), style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 16),
            Row(children: [
              Expanded(child: _stat(context, 'Penerangan', '$illumination%', Icons.brightness_6_outlined)),
              const SizedBox(width: 10),
              Expanded(child: _stat(context, 'Berikutnya', nextMoonEvent, Icons.event_outlined)),
            ]),
            const SizedBox(height: 10),
            Text('Perkiraan $nextMoonEvent sekitar $daysUntilMoonEvent hari lagi. Fase dihitung secara astronomis sebagai estimasi.', style: Theme.of(context).textTheme.bodySmall?.copyWith(height: 1.5), textAlign: TextAlign.center),
          ]),
        ),
        const SizedBox(height: 22),
        Row(children: [
          const Icon(Icons.brightness_3_rounded, color: AppTheme.coronaGold),
          const SizedBox(width: 8),
          Expanded(child: Text('Jadwal Gerhana Bulan', style: Theme.of(context).textTheme.titleLarge)),
        ]),
        const SizedBox(height: 6),
        const Text('Jadwal berikut disusun dari sumber astronomi; keterlihatan dan jam pengamatan bergantung pada lokasi.', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12, height: 1.5)),
        const SizedBox(height: 12),
        _eclipseCard(
          date: '21 Februari 2027',
          type: 'Gerhana Bulan Penumbra',
          visibility: 'Tercatat terlihat dari sebagian Indonesia. Di beberapa kota, fase gerhana terjadi saat Bulan dekat atau di bawah horizon.',
          icon: Icons.visibility_outlined,
        ),
        _eclipseCard(
          date: '17 Agustus 2027',
          type: 'Gerhana Bulan Penumbra',
          visibility: 'Tercatat terlihat di wilayah timur Indonesia, termasuk Papua; waktu lokal perlu disesuaikan dengan kota.',
          icon: Icons.public_rounded,
        ),
        _eclipseCard(
          date: '6–7 Juli 2028',
          type: 'Gerhana Bulan Sebagian',
          visibility: 'Diperkirakan dapat diamati dari Indonesia. Periksa waktu lokal mendekati tanggal kejadian.',
          icon: Icons.visibility_outlined,
        ),
        _eclipseCard(
          date: '31 Desember 2028 – 1 Januari 2029',
          type: 'Gerhana Bulan Total',
          visibility: 'Termasuk jadwal gerhana total yang dapat terlihat dari kawasan Asia, termasuk Indonesia.',
          icon: Icons.auto_awesome,
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: AppTheme.surfaceGlass, borderRadius: BorderRadius.circular(AppTheme.radius), border: Border.all(color: AppTheme.borderLight)),
          child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Sumber jadwal', style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold)),
            SizedBox(height: 6),
            Text('NASA Eclipse pages dan timeanddate.com untuk keterlihatan di Indonesia. Fase Bulan adalah estimasi perhitungan lokal; bukan pengamatan langsung.', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12, height: 1.5)),
          ]),
        ),
      ],
    );
  }

  Widget _stat(BuildContext context, String label, String value, IconData icon) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(color: AppTheme.surfaceElevated, borderRadius: BorderRadius.circular(AppTheme.radius), border: Border.all(color: AppTheme.borderSubtle)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Icon(icon, color: AppTheme.coronaGold, size: 18),
      const SizedBox(height: 8),
      Text(value, style: Theme.of(context).textTheme.titleMedium, maxLines: 2, overflow: TextOverflow.ellipsis),
      const SizedBox(height: 3),
      Text(label, style: Theme.of(context).textTheme.bodySmall),
    ]),
  );

  Widget _eclipseCard({required String date, required String type, required String visibility, required IconData icon}) => Container(
    margin: const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(color: AppTheme.surfaceElevated, borderRadius: BorderRadius.circular(AppTheme.radius), border: Border.all(color: AppTheme.borderSubtle)),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(width: 42, height: 42, decoration: BoxDecoration(color: AppTheme.eclipseViolet.withValues(alpha: 0.18), borderRadius: BorderRadius.circular(13)), child: Icon(icon, color: AppTheme.coolCyan)),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(date, style: const TextStyle(color: AppTheme.coronaGold, fontSize: 12, fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        Text(type, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 15, fontWeight: FontWeight.bold)),
        const SizedBox(height: 5),
        Text(visibility, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12, height: 1.45)),
      ])),
    ]),
  );
}
