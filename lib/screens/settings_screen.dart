import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final TextEditingController _urlController = TextEditingController();
  bool? _isOnline;
  bool _isTesting = false;

  @override
  void initState() {
    super.initState();
    _loadUrl();
  }

  Future<void> _loadUrl() async {
    final url = await AppConfig.getBaseUrl();
    setState(() {
      _urlController.text = url;
    });
  }

  Future<void> _saveUrl() async {
    await AppConfig.setBaseUrl(_urlController.text.trim());
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Backend URL saved. Restart app to apply.'),
        ),
      );
    }
  }

  Future<void> _testConnection() async {
    setState(() {
      _isTesting = true;
      _isOnline = null;
    });

    try {
      final res = await http
          .get(Uri.parse('${_urlController.text.trim()}/health'))
          .timeout(const Duration(seconds: 60));
      final ok = res.statusCode == 200;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              ok ? '✅ Connected!' : '❌ Got status ${res.statusCode}',
            ),
            backgroundColor: ok ? Colors.green : const Color(0xFFE8002D),
          ),
        );
        setState(() {
          _isOnline = ok;
          _isTesting = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Failed: $e'),
            backgroundColor: const Color(0xFFE8002D),
          ),
        );
        setState(() {
          _isOnline = false;
          _isTesting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'SETTINGS',
          style: AppConfig.displayStyle.copyWith(fontSize: 18),
        ),
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
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: AppConfig.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: AppConfig.accentRed),
              ),
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
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppConfig.accentRed,
                  ),
                  onPressed: _saveUrl,
                  child: const Text(
                    'SAVE URL',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: AppConfig.border),
                  ),
                  onPressed: _isTesting ? null : _testConnection,
                  child: _isTesting
                      ? const SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
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
            subtitle: const Text(
              'Reset locally stored read status and filters',
            ),
            trailing: const Icon(
              Icons.delete_outline,
              color: AppConfig.textSecondary,
            ),
            onTap: () {},
          ),
          const ListTile(
            title: Text('VERSION'),
            trailing: Text(
              '1.0.0',
              style: TextStyle(color: AppConfig.textSecondary),
            ),
          ),
          const SizedBox(height: 32),
          _buildSectionHeader('CREDITS'),
          const ListTile(
            title: Text('DEVELOPER & OWNER'),
            trailing: Text(
              'SOUMIL CHANDRA',
              style: TextStyle(
                color: AppConfig.textSecondary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const ListTile(
            title: Text('TEAM'),
            trailing: Text(
              'PITWALL F1 INTELLIGENCE',
              style: TextStyle(color: AppConfig.textSecondary),
            ),
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
