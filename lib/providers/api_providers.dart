import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_service.dart';

final apiServiceProvider = Provider((ref) => ApiService());

final newsProvider = FutureProvider.family<List<dynamic>, int>((ref, page) async {
  final apiService = ref.watch(apiServiceProvider);
  return apiService.getNews(page: page);
});

final nextRaceProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final apiService = ref.watch(apiServiceProvider);
  return apiService.getNextRace();
});

final driverStandingsProvider = FutureProvider.family<List<dynamic>, int>((ref, year) async {
  final apiService = ref.watch(apiServiceProvider);
  return apiService.getDriverStandings(year);
});

final constructorStandingsProvider = FutureProvider.family<List<dynamic>, int>((ref, year) async {
  final apiService = ref.watch(apiServiceProvider);
  return apiService.getConstructorStandings(year);
});

final scheduleProvider = FutureProvider.family<List<dynamic>, int>((ref, year) async {
  final apiService = ref.watch(apiServiceProvider);
  return apiService.getSchedule(year);
});

final tyreStrategyProvider = FutureProvider.family<List<dynamic>, List<int>>((ref, params) async {
  final apiService = ref.watch(apiServiceProvider);
  return apiService.getTyreStrategy(params[0], params[1]);
});
