import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/brand_theme_provider.dart';
import '../../data/document_repository.dart';

export '../../data/document_repository.dart'
    show DocumentWithClient, DocumentMetrics;

final recentDocumentsProvider = StreamProvider<List<DocumentWithClient>>((ref) {
  final activeBrand = ref.watch(activeBrandProvider);
  final int brandId = (activeBrand?.id) ?? ref.watch(activeBrandIdProvider);
  final repo = ref.watch(documentRepositoryProvider);
  return repo.watchRecentDocuments(brandId);
});

final brandMetricsProvider = StreamProvider<DocumentMetrics>((ref) {
  final activeBrand = ref.watch(activeBrandProvider);
  final int brandId = (activeBrand?.id) ?? ref.watch(activeBrandIdProvider);
  final repo = ref.watch(documentRepositoryProvider);
  return repo.watchBrandMetrics(brandId);
});
