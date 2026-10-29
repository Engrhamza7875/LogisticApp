import 'package:flutter/material.dart';
import '../../core/colors.dart';
import 'package:animate_do/animate_do.dart';
import '../../services/api_service.dart';
import '../widgets/role_guard.dart';
import 'package:intl/intl.dart';

class BroadcastingScreen extends StatefulWidget {
  const BroadcastingScreen({super.key});

  @override
  State<BroadcastingScreen> createState() => _BroadcastingScreenState();
}

class _BroadcastingScreenState extends State<BroadcastingScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();
  String _targetRole = 'All';
  bool _isSending = false;
  bool _historyLoading = true;
  List<Map<String, dynamic>> _history = [];

  final List<String> _targetRoles = ['All', 'User', 'Admin'];
  final Color _bgDark = const Color(0xFF0F172A);
  final Color _accentColor = AppColors.orange;

  @override
  void initState() {
    super.initState();
    _loadHistory();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      RoleGuardPage.enforce(context, allowedRoles: ['Admin', 'SuperAdmin']);
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _loadHistory() async {
    setState(() => _historyLoading = true);
    try {
      final list = await ApiService.fetchNotifications();
      if (mounted) setState(() { _history = list; _historyLoading = false; });
    } catch (_) {
      if (mounted) setState(() => _historyLoading = false);
    }
  }

  Future<void> _sendNotification() async {
    if (_titleController.text.isEmpty || _messageController.text.isEmpty) {
      _snack('Please fill in both title and message', isError: true);
      return;
    }

    setState(() => _isSending = true);
    try {
      await ApiService.broadcastNotification(
        title: _titleController.text.trim(),
        body: _messageController.text.trim(),
        targetRole: _targetRole,
      );
      if (!mounted) return;
      _snack('Broadcast transmitted successfully!');
      _titleController.clear();
      _messageController.clear();
      await _loadHistory();
    } catch (e) {
      if (!mounted) return;
      _snack('Transmission Error: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  void _snack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: isError ? AppColors.error : AppColors.success, behavior: SnackBarBehavior.floating),
    );
  }

  String _formatDate(dynamic raw) {
    if (raw == null) return '';
    try {
      final dt = DateTime.parse(raw.toString()).toLocal();
      return DateFormat('dd MMM, HH:mm').format(dt);
    } catch (_) { return raw.toString(); }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgDark,
      body: Stack(
        children: [
          Positioned.fill(child: Container(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [_bgDark, _bgDark.withBlue(30)])))),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildAppBar(),
                  const SizedBox(height: 20),
                  FadeInDown(child: _buildHeaderBanner()),
                  const SizedBox(height: 32),
                  FadeInUp(child: _buildComposeSection()),
                  const SizedBox(height: 40),
                  FadeInUp(child: _buildHistorySection()),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return Row(
      children: [
        IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20), onPressed: () => Navigator.pop(context)),
        const SizedBox(width: 8),
        const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Signal Center', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          Text('NETWORK-WIDE BROADCASTING', style: TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1)),
        ]),
        const Spacer(),
        IconButton(onPressed: _loadHistory, icon: const Icon(Icons.refresh_rounded, color: Colors.white38)),
      ],
    );
  }

  Widget _buildHeaderBanner() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(gradient: LinearGradient(colors: [_accentColor, _accentColor.withBlue(200)]), borderRadius: BorderRadius.circular(16)), child: const Icon(Icons.campaign_rounded, color: Colors.white, size: 28)),
          const SizedBox(width: 20),
          const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Mass Communication', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            Text('Deploy instant notifications across the logistics network.', style: TextStyle(color: Colors.white38, fontSize: 12)),
          ])),
        ],
      ),
    );
  }

  Widget _buildComposeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('COMPOSE SIGNAL', style: TextStyle(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1)),
        const SizedBox(height: 20),
        _buildTargetChips(),
        const SizedBox(height: 20),
        _buildTextField(_titleController, 'Signal Title', Icons.title_rounded, maxLines: 1),
        const SizedBox(height: 16),
        _buildTextField(_messageController, 'System Message', Icons.message_rounded, maxLines: 5),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: _isSending ? null : _sendNotification,
            style: ElevatedButton.styleFrom(backgroundColor: _accentColor, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), elevation: 0),
            child: _isSending ? const CircularProgressIndicator(color: Colors.white) : const Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.wifi_tethering_rounded, color: Colors.white), SizedBox(width: 12), Text('TRANSMIT SIGNAL', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1))]),
          ),
        ),
      ],
    );
  }

  Widget _buildTargetChips() {
    return Row(
      children: _targetRoles.map((role) {
        final sel = _targetRole == role;
        return Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _targetRole = role),
            child: Container(
              margin: EdgeInsets.only(right: role != _targetRoles.last ? 8 : 0),
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(color: sel ? _accentColor.withOpacity(0.1) : Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(14), border: Border.all(color: sel ? _accentColor.withOpacity(0.5) : Colors.white.withOpacity(0.05))),
              alignment: Alignment.center,
              child: Text(role, style: TextStyle(color: sel ? _accentColor : Colors.white38, fontWeight: FontWeight.bold, fontSize: 13)),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTextField(TextEditingController ctrl, String hint, IconData icon, {int maxLines = 1}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white.withOpacity(0.05))),
      child: TextField(
        controller: ctrl,
        maxLines: maxLines,
        style: const TextStyle(color: Colors.white, fontSize: 14),
        decoration: InputDecoration(
          hintText: hint, hintStyle: const TextStyle(color: Colors.white24, fontSize: 14), border: InputBorder.none,
          icon: Icon(icon, color: Colors.white38, size: 20),
        ),
      ),
    );
  }

  Widget _buildHistorySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          const Text('SIGNAL LOGS', style: TextStyle(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1)),
          const Spacer(),
          Text('${_history.length} RECORDS', style: const TextStyle(color: Colors.white24, fontSize: 10)),
        ]),
        const SizedBox(height: 20),
        if (_historyLoading) const Center(child: CircularProgressIndicator())
        else if (_history.isEmpty) const Center(child: Text('No signals transmitted', style: TextStyle(color: Colors.white24)))
        else ...List.generate(_history.length, (i) => _buildHistoryItem(_history[i])),
      ],
    );
  }

  Widget _buildHistoryItem(Map<String, dynamic> n) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white.withOpacity(0.05))),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: _accentColor.withOpacity(0.1), borderRadius: BorderRadius.circular(12)), child: Icon(Icons.podcasts_rounded, color: _accentColor, size: 16)),
          const SizedBox(width: 16),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(child: Text(n['title'] ?? '', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14))),
              Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2), decoration: BoxDecoration(color: Colors.white12, borderRadius: BorderRadius.circular(8)), child: Text(n['targetRole'] ?? 'All', style: const TextStyle(color: Colors.white38, fontSize: 8, fontWeight: FontWeight.bold))),
            ]),
            const SizedBox(height: 4),
            Text(n['body'] ?? '', style: const TextStyle(color: Colors.white38, fontSize: 12), maxLines: 2),
            const SizedBox(height: 8),
            Text(_formatDate(n['sentAt']), style: const TextStyle(color: Colors.white24, fontSize: 10)),
          ])),
        ],
      ),
    );
  }
}
