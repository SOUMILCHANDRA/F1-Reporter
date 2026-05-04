import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_config.dart';
import '../services/api_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final TextEditingController _urlController = TextEditingController();
  final ApiService _apiService = ApiService();
  bool? _isOnline;
  bool _isTesting = false;

  @override
  void initState() {
    super.initState();
    _loadUrl();
  }

  Future<void> _loadUrl() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _urlController.text = prefs.getString('backend_url') ?? AppConfig.defaultBaseUrl;
    });
  }

  Future<void> _saveUrl() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('backend_url', _urlController.text);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Backend URL saved')),
      );
    }
  }

  Future<void> _testConnection() async {
    setState(() {
      _isTesting = true;
      _isOnline = null;
    });
    
    // Temporarily save to test
    final prefs = await SharedPreferences.getInstance();
    final originalUrl = prefs.getString('backend_url');
    await prefs.setString('backend_url', _urlController.text);
    
    final online = await _apiService.checkHealth();
    
    // Restore if not saving
    if (originalUrl != null) await prefs.setString('backend_url', originalUrl);

    if (mounted) {
      setState(() {
        _isOnline = online;
        _isTesting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('SETTINGS', style: AppConfig.displayStyle.copyWith(fontSize: 18)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSectionHeader('BACKEND CONFIGURATION'),
          const SizedBox(height: 16),
          TextField(
            controller: _urlController,
            decoration: InputDecoration(
              labelText: 'API BASE URL',
              labelStyle: TextStyle(color: AppConfig.textSecondary),
              enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: AppConfig.border)),
              focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: AppConfig.accentRed)),
              filled: true,
              fillColor: AppConfig.surface,
            ),
            style: AppConfig.monoStyle,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: AppConfig.accentRed),
                  onPressed: _saveUrl,
                  child: const Text('SAVE URL', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(side: BorderSide(color: AppConfig.border)),
                  onPressed: _isTesting ? null : _testConnection,
                  child: _isTesting 
                    ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('TEST CONNECTION'),
                ),
              ),
            ],
          ),
          if (_isOnline != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _isOnline! ? Icons.check_circle : Icons.error,
                    color: _isOnline! ? Colors.green : AppConfig.accentRed,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _isOnline! ? 'CONNECTION: ONLINE' : 'CONNECTION: OFFLINE',
                    style: AppConfig.monoStyle.copyWith(
                      color: _isOnline! ? Colors.green : AppConfig.accentRed,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 32),
          _buildSectionHeader('APPLICATION'),
          ListTile(
            title: const Text('CLEAR CACHE'),
            subtitle: const Text('Reset locally stored read status and filters'),
            trailing: const Icon(Icons.delete_outline, color: AppConfig.textSecondary),
            onTap: () {},
          ),
          const ListTile(
            title: Text('VERSION'),
            trailing: Text('1.0.0', style: TextStyle(color: AppConfig.textSecondary)),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: AppConfig.displayStyle.copyWith(
        fontSize: 12,
        color: AppConfig.accentRed,
        letterSpacing: 1.2,
      ),
    );
  }
}
