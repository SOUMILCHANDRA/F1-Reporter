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

final resultsProvider = FutureProvider.family<List<dynamic>, List<dynamic>>((ref, params) async {
  final apiService = ref.watch(apiServiceProvider);
  return apiService.getResults(params[0], params[1], params[2]);
});

final telemetryProvider = FutureProvider.family<Map<String, dynamic>, List<dynamic>>((ref, params) async {
  final apiService = ref.watch(apiServiceProvider);
  return apiService.getTelemetry(params[0], params[1], params[2], params[3]);
});

final tyreStrategyProvider = FutureProvider.family<List<dynamic>, List<int>>((ref, params) async {
  final apiService = ref.watch(apiServiceProvider);
  return apiService.getTyreStrategy(params[0], params[1]);
});

final weatherProvider = FutureProvider.family<Map<String, dynamic>, List<dynamic>>((ref, params) async {
  final apiService = ref.watch(apiServiceProvider);
  return apiService.getWeather(params[0], params[1], params[2]);
});

final raceControlProvider = FutureProvider.family<List<dynamic>, List<int>>((ref, params) async {
  final apiService = ref.watch(apiServiceProvider);
  return apiService.getRaceControl(params[0], params[1]);
});

final driverSeasonProvider = FutureProvider.family<Map<String, dynamic>, List<dynamic>>((ref, params) async {
  final apiService = ref.watch(apiServiceProvider);
  return apiService.getDriverSeason(params[0], params[1]);
});
