import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../services/api_service.dart';

class DevSettingsScreen extends StatefulWidget {
  const DevSettingsScreen({super.key});

  @override
  State<DevSettingsScreen> createState() => _DevSettingsScreenState();
}

class _DevSettingsScreenState extends State<DevSettingsScreen> {
  late TextEditingController _ctrl;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: ApiService.baseUrl);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    await ApiService.setOverrideBaseUrl(_ctrl.text.trim());
    setState(() => _saving = false);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Override saved (restart may be required)')),
    );
  }

  Future<void> _clear() async {
    setState(() => _saving = true);
    await ApiService.setOverrideBaseUrl(null);
    setState(() => _saving = false);
    _ctrl.text = ApiService.baseUrl;
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Override cleared')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Developer Settings')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Backend Base URL',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _ctrl,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'e.g. http://192.168.1.100:5000/api',
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                ElevatedButton(
                  onPressed: _saving ? null : _save,
                  child: _saving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Save Override'),
                ),
                const SizedBox(width: 12),
                OutlinedButton(
                  onPressed: _saving ? null : _clear,
                  child: const Text('Clear Override'),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Text('Notes', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text(
              '• If empty, app will auto-detect common local addresses.',
            ),
            const Text('• Use full URL including scheme and /api suffix.'),
            if (kDebugMode) ...[
              const SizedBox(height: 16),
              Text('Detected: ${ApiService.baseUrl}'),
            ],
          ],
        ),
      ),
    );
  }
}
