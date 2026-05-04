import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = 'https://f1-reporter.onrender.com';

  Future<List<dynamic>> getNews({int page = 1, int pageSize = 20}) async {
    final response = await http.get(Uri.parse('$baseUrl/news?page=$page&pageSize=$pageSize'));
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load news');
    }
  }

  Future<List<dynamic>> getSchedule(int year) async {
    final response = await http.get(Uri.parse('$baseUrl/schedule/$year'));
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load schedule');
    }
  }

  Future<Map<String, dynamic>> getNextRace() async {
    final response = await http.get(Uri.parse('$baseUrl/next_race'));
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load next race');
    }
  }

  Future<List<dynamic>> getDriverStandings(int year) async {
    final response = await http.get(Uri.parse('$baseUrl/standings/drivers/$year'));
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load driver standings');
    }
  }

  Future<List<dynamic>> getConstructorStandings(int year) async {
    final response = await http.get(Uri.parse('$baseUrl/standings/constructors/$year'));
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load constructor standings');
    }
  }

  Future<Map<String, dynamic>> getTelemetry(int year, int round, String session, String driver) async {
    final response = await http.get(Uri.parse('$baseUrl/telemetry/$year/$round/$session/$driver'));
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load telemetry');
    }
  }

  Future<List<dynamic>> getTyreStrategy(int year, int round) async {
    final response = await http.get(Uri.parse('$baseUrl/tyre_strategy/$year/$round'));
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load tyre strategy');
    }
  }
  
  // Add more as needed...
}
