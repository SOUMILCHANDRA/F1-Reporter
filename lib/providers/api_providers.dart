import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_service.dart';

final apiServiceProvider = Provider((ref) => ApiService());

final newsProvider = FutureProvider.family<List<dynamic>, int>((ref, page) async {
  final apiService = ref.watch(apiServiceProvider);
  return apiService.getNews(page: page);
});

final driverStandingsProvider = FutureProvider.family<List<dynamic>, int>((ref, year) async {
  final apiService = ref.watch(apiServiceProvider);
  return apiService.getStandings(year, drivers: true);
});

final constructorStandingsProvider = FutureProvider.family<List<dynamic>, int>((ref, year) async {
  final apiService = ref.watch(apiServiceProvider);
  return apiService.getStandings(year, drivers: false);
});

final scheduleProvider = FutureProvider.family<List<dynamic>, int>((ref, year) async {
  final apiService = ref.watch(apiServiceProvider);
  return apiService.getSchedule(year);
});

final resultsProvider = FutureProvider.family<List<dynamic>, (int, int, String)>((ref, params) async {
  final apiService = ref.watch(apiServiceProvider);
  return apiService.getResults(params.$1, params.$2, params.$3);
});

final lapsProvider = FutureProvider.family<List<dynamic>, (int, int, String)>((ref, params) async {
  final apiService = ref.watch(apiServiceProvider);
  return apiService.getLaps(params.$1, params.$2, params.$3);
});

final telemetryProvider = FutureProvider.family<Map<String, dynamic>, (int, int, String, String)>((ref, params) async {
  final apiService = ref.watch(apiServiceProvider);
  return apiService.getTelemetry(params.$1, params.$2, params.$3, params.$4);
});

final tyreStrategyProvider = FutureProvider.family<List<dynamic>, (int, int)>((ref, params) async {
  final apiService = ref.watch(apiServiceProvider);
  return apiService.getTyreStrategy(params.$1, params.$2);
});

final weatherProvider = FutureProvider.family<Map<String, dynamic>, (int, int, String)>((ref, params) async {
  final apiService = ref.watch(apiServiceProvider);
  return apiService.getWeather(params.$1, params.$2, params.$3);
});

final raceControlProvider = FutureProvider.family<List<dynamic>, (int, int)>((ref, params) async {
  final apiService = ref.watch(apiServiceProvider);
  return apiService.getRaceControl(params.$1, params.$2);
});

final driverSeasonProvider = FutureProvider.family<Map<String, dynamic>, (int, String)>((ref, params) async {
  final apiService = ref.watch(apiServiceProvider);
  return apiService.getDriverSeason(params.$1, params.$2);
});

final trackMapProvider = FutureProvider.family<dynamic, String>((ref, raceName) async {
  final apiService = ref.watch(apiServiceProvider);
  return apiService.getTrackMap(raceName);
});
