import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_config.dart';

class ApiService {
  Future<String> getBaseUrl() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('backend_url') ?? AppConfig.defaultBaseUrl;
  }

  Future<bool> checkHealth() async {
    try {
      final baseUrl = await getBaseUrl();
      final response = await http.get(Uri.parse('$baseUrl/health')).timeout(const Duration(seconds: 5));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<List<dynamic>> getNews({int page = 1, int pageSize = 20}) async {
    final baseUrl = await getBaseUrl();
    final response = await http.get(Uri.parse('$baseUrl/news?page=$page&pageSize=$pageSize'));
    if (response.statusCode == 200) return json.decode(response.body);
    throw Exception('Failed to load news');
  }

  Future<List<dynamic>> getResults(int year, int round, String session) async {
    final baseUrl = await getBaseUrl();
    final response = await http.get(Uri.parse('$baseUrl/results/$year/$round/$session'));
    if (response.statusCode == 200) return json.decode(response.body);
    throw Exception('Failed to load results');
  }

  Future<List<dynamic>> getSchedule(int year) async {
    final baseUrl = await getBaseUrl();
    final response = await http.get(Uri.parse('$baseUrl/schedule/$year'));
    if (response.statusCode == 200) return json.decode(response.body);
    throw Exception('Failed to load schedule');
  }

  Future<Map<String, dynamic>> getTelemetry(int year, int round, String session, String driver) async {
    final baseUrl = await getBaseUrl();
    final response = await http.get(Uri.parse('$baseUrl/telemetry/$year/$round/$session/$driver'));
    if (response.statusCode == 200) return json.decode(response.body);
    throw Exception('Failed to load telemetry');
  }

  Future<List<dynamic>> getTyreStrategy(int year, int round) async {
    final baseUrl = await getBaseUrl();
    final response = await http.get(Uri.parse('$baseUrl/tyre_strategy/$year/$round'));
    if (response.statusCode == 200) return json.decode(response.body);
    throw Exception('Failed to load tyre strategy');
  }

  Future<List<dynamic>> getRaceControl(int year, int round) async {
    final baseUrl = await getBaseUrl();
    final response = await http.get(Uri.parse('$baseUrl/race_control/$year/$round'));
    if (response.statusCode == 200) return json.decode(response.body);
    throw Exception('Failed to load race control messages');
  }

  Future<Map<String, dynamic>> getWeather(int year, int round, String session) async {
    final baseUrl = await getBaseUrl();
    final response = await http.get(Uri.parse('$baseUrl/weather/$year/$round/$session'));
    if (response.statusCode == 200) return json.decode(response.body);
    throw Exception('Failed to load weather data');
  }

  Future<List<dynamic>> getStandings(int year, {bool drivers = true}) async {
    final baseUrl = await getBaseUrl();
    final type = drivers ? 'drivers' : 'constructors';
    final response = await http.get(Uri.parse('$baseUrl/standings/$type/$year'));
    if (response.statusCode == 200) return json.decode(response.body);
    throw Exception('Failed to load standings');
  }

  Future<Map<String, dynamic>> getDriverSeason(int year, String driver) async {
    final baseUrl = await getBaseUrl();
    final response = await http.get(Uri.parse('$baseUrl/driver_season/$year/$driver'));
    if (response.statusCode == 200) return json.decode(response.body);
    throw Exception('Failed to load driver season stats');
  }
}
