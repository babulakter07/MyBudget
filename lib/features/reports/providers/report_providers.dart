import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_exception.dart';
import '../../../shared/providers/core_providers.dart';
import '../data/report_file_service.dart';
import '../data/reports_repository.dart';
import '../domain/report_models.dart';

final reportsRepositoryProvider = Provider<ReportsRepository>(
  (ref) => ReportsRepository(ref.watch(appDatabaseProvider)),
);

final reportFileServiceProvider = Provider<ReportFileService>(
  (ref) => ReportFileService(),
);

int _requireProfile(Ref ref) {
  final id = ref.watch(activeProfileIdProvider);
  if (id == null) throw AppException('No profile selected.');
  return id;
}

/// Key: (year, month).
final monthlyReportProvider = FutureProvider.autoDispose
    .family<MonthlyReport, (int, int)>((ref, key) {
      final profileId = _requireProfile(ref);
      return ref
          .watch(reportsRepositoryProvider)
          .monthly(profileId, key.$1, key.$2);
    });

final yearlyReportProvider = FutureProvider.autoDispose
    .family<YearlyReport, int>((ref, year) {
      final profileId = _requireProfile(ref);
      return ref.watch(reportsRepositoryProvider).yearly(profileId, year);
    });

/// Key: (from, to) as 'yyyy-MM-dd'.
final rangeReportProvider = FutureProvider.autoDispose
    .family<RangeReport, (String, String)>((ref, key) {
      final profileId = _requireProfile(ref);
      return ref
          .watch(reportsRepositoryProvider)
          .range(profileId, key.$1, key.$2);
    });
