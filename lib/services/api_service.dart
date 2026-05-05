import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';

class ApiService {
  static Future<String> _base() => AppConfig.getBaseUrl();

  static Future<dynamic> _get(String path) async {
    final base = await _base();
    final uri = Uri.parse('$base$path');
    try {
      final response = await http.get(uri).timeout(const Duration(seconds: 60));
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.body}');
      }
    } on TimeoutException {
      throw Exception('Request timed out. Is the backend running?');
    } on SocketException {
      throw Exception('No connection to backend. Check Settings.');
    }
  }

  Future<bool> checkHealth() async {
    try {
      final base = await _base();
      final response = await http.get(Uri.parse('$base/health')).timeout(const Duration(seconds: 60));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<List<dynamic>> getNews({int page = 1, int pageSize = 20}) async {
    return await _get('/news?page=$page&pageSize=$pageSize');
  }

  Future<List<dynamic>> getResults(int year, int round, String session) async {
    return await _get('/results/$year/$round/$session');
  }

  Future<List<dynamic>> getLaps(int year, int round, String session) async {
    return await _get('/laps/$year/$round/$session');
  }

  Future<List<dynamic>> getSchedule(int year) async {
    return await _get('/schedule/$year');
  }

  Future<Map<String, dynamic>> getTelemetry(int year, int round, String session, String driver) async {
    return await _get('/telemetry/$year/$round/$session/$driver');
  }

  Future<List<dynamic>> getTyreStrategy(int year, int round) async {
    return await _get('/tyre_strategy/$year/$round');
  }

  Future<List<dynamic>> getRaceControl(int year, int round) async {
    return await _get('/race_control/$year/$round');
  }

  Future<Map<String, dynamic>> getWeather(int year, int round, String session) async {
    return await _get('/weather/$year/$round/$session');
  }

  Future<List<dynamic>> getStandings(int year, {bool drivers = true}) async {
    final type = drivers ? 'drivers' : 'constructors';
    return await _get('/standings/$type/$year');
  }

  Future<Map<String, dynamic>> getDriverSeason(int year, String driverCode) async {
    return await _get('/stats/driver/$year/$driverCode');
  }

  Future<dynamic> getTrackMap(String raceName) async {
    return await _get('/map/$raceName');
  }
}
