import '../../models/activity_model.dart';

/// Daftar 12 Aktivitas Yaumi sesuai tabel mentoring
///
/// Sistem Evaluasi:
/// - Daily (≥50% hari/bulan): Al-Qur'an, Al-Ma'tsurat, Tahajud, Istighfar, Sholawat, Doa, Shalat berjamaah, Infaq
/// - Monthly Count: Puasa (≥3x/bulan), Pertemuan pekanan (≥2x/bulan)
/// - Weekly: Artikel/video dakwah (≥1x/minggu)
/// - Monthly Binary: MABIT (≥1x/bulan)
class ActivityConstants {
  ActivityConstants._();

  /// Semua aktivitas yaumi
  static final List<ActivityModel> activities = [
    // === EVALUASI HARIAN (≥50% hari/bulan = V) ===
    ActivityModel(
      id: 1,
      name: 'Membaca Al-Qur\'an',
      target: '1 juz/hari',
      jenis: ActivityJenis.individu,
      evaluationPeriod: EvaluationPeriod.daily,
      keterangan: '',
    ),
    ActivityModel(
      id: 2,
      name: 'Membaca Wadzifah Sugro (Al Ma\'tsurat)',
      target: 'Pagi atau Petang',
      jenis: ActivityJenis.individu,
      evaluationPeriod: EvaluationPeriod.daily,
      keterangan: 'Wadzifah sugra setiap hari',
    ),
    ActivityModel(
      id: 3,
      name: 'Tahajud',
      target: 'Setiap hari',
      jenis: ActivityJenis.individu,
      evaluationPeriod: EvaluationPeriod.daily,
      keterangan: '',
    ),
    ActivityModel(
      id: 5,
      name: 'Memperbanyak Istighfar',
      target: 'Setiap hari',
      jenis: ActivityJenis.individu,
      evaluationPeriod: EvaluationPeriod.daily,
      keterangan: '',
    ),
    ActivityModel(
      id: 6,
      name: 'Memperbanyak Sholawat Nabi',
      target: 'Setiap hari',
      jenis: ActivityJenis.individu,
      evaluationPeriod: EvaluationPeriod.daily,
      keterangan: '',
    ),
    ActivityModel(
      id: 7,
      name:
          'Mendoakan kebaikan (anggota mentoring, pemimpin, bangsa, umat Islam)',
      target: 'Setiap hari',
      jenis: ActivityJenis.individu,
      evaluationPeriod: EvaluationPeriod.daily,
      keterangan: '',
    ),
    ActivityModel(
      id: 8,
      name: 'Shalat berjamaah di masjid',
      target: '3 kali/hari',
      jenis: ActivityJenis.individu,
      evaluationPeriod: EvaluationPeriod.daily,
      keterangan: '',
    ),
    ActivityModel(
      id: 10,
      name: 'Infaq mingguan',
      target: 'Setiap anggota',
      jenis: ActivityJenis.individu,
      evaluationPeriod: EvaluationPeriod.daily,
      keterangan: '',
    ),

    // === EVALUASI BULANAN (≥threshold/bulan = V) ===
    ActivityModel(
      id: 4,
      name: 'Puasa Sunnah (Ayyamul Bidh / Senin-Kamis)',
      target: '≥3 hari/bulan',
      jenis: ActivityJenis.individu,
      evaluationPeriod: EvaluationPeriod.monthly,
      threshold: 3, // Minimal 3 kali per bulan
      keterangan: '',
    ),
    ActivityModel(
      id: 9,
      name: 'Meluangkan & mempersiapkan waktu terbaik utk pertemuan pekanan',
      target: '≥2 kali/bulan',
      jenis: ActivityJenis.individu,
      evaluationPeriod: EvaluationPeriod.monthly,
      threshold: 2, // Minimal 2 kali per bulan
      keterangan: '',
    ),
    ActivityModel(
      id: 12,
      name: 'Mengikuti MABIT (Malam Pembinaan Iman & Taqwa)',
      target: '≥1 kali/bulan',
      jenis: ActivityJenis.grupBpc,
      evaluationPeriod: EvaluationPeriod.monthly,
      threshold: 1, // Minimal 1 kali per bulan
      keterangan: 'Kegiatan: buka puasa/sahur bersama, sholat tahajud dll',
    ),

    // === EVALUASI MINGGUAN (≥1x/minggu = V) ===
    ActivityModel(
      id: 11,
      name: 'Membaca artikel / menonton video dakwah',
      target: '≥1 kali/minggu',
      jenis: ActivityJenis.individu,
      evaluationPeriod: EvaluationPeriod.weekly,
      threshold: 1, // Minimal 1 kali per minggu
      keterangan: '',
    ),
  ];

  /// Get activity by ID
  static ActivityModel? getById(int id) {
    try {
      return activities.firstWhere((a) => a.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Aktivitas dengan evaluasi harian (≥50% hari/bulan)
  static List<ActivityModel> get dailyActivities => activities
      .where((a) => a.evaluationPeriod == EvaluationPeriod.daily)
      .toList();

  /// Aktivitas dengan evaluasi mingguan
  static List<ActivityModel> get weeklyActivities => activities
      .where((a) => a.evaluationPeriod == EvaluationPeriod.weekly)
      .toList();

  /// Aktivitas dengan evaluasi bulanan (count threshold)
  static List<ActivityModel> get monthlyActivities => activities
      .where((a) => a.evaluationPeriod == EvaluationPeriod.monthly)
      .toList();

  /// Sorted by ID for display
  static List<ActivityModel> get sortedActivities =>
      List.from(activities)..sort((a, b) => a.id.compareTo(b.id));
}
