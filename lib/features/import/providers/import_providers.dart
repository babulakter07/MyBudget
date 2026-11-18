import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/providers/core_providers.dart';
import '../../transactions/providers/transaction_providers.dart';
import '../data/csv_file_gateway.dart';
import '../data/csv_import_service.dart';

/// Override in tests to feed CSV text without a platform file picker.
final csvFileGatewayProvider = Provider<CsvFileGateway>(
  (ref) => const FilePickerCsvGateway(),
);

final csvImportServiceProvider = Provider<CsvImportService>(
  (ref) => CsvImportService(
    ref.watch(appDatabaseProvider),
    ref.watch(transactionRepositoryProvider),
  ),
);
