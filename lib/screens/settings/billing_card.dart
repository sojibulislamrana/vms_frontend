import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

import '../../core/constants/api_constants.dart';
import '../../services/auth_service.dart';

class BillingCard extends StatefulWidget {
  const BillingCard({super.key, required this.authService});
  final AuthService authService;

  @override
  State<BillingCard> createState() => _BillingCardState();
}

class _BillingCardState extends State<BillingCard> {
  bool _isLoading = false;
  String? _error;
  final http.Client _client = http.Client();

  @override
  void dispose() {
    _client.close();
    super.dispose();
  }

  Future<void> _openCheckout() async {
    final token = widget.authService.token;
    final workspaceId = widget.authService.workspaceId;
    if (token == null || workspaceId == null) {
      setState(() => _error = 'Sign in to your workspace before changing its plan.');
      return;
    }
    setState(() { _isLoading = true; _error = null; });
    try {
      final response = await _client.post(
        Uri.parse('${ApiConstants.baseUrl}/api/v1/billing/checkout'),
        headers: {
          'Authorization': 'Bearer $token',
          'X-Workspace-ID': workspaceId,
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 20));
      final payload = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode != 200) {
        throw Exception(payload['detail'] ?? payload['message'] ?? 'Checkout is not available yet.');
      }
      final url = Uri.parse(payload['url'].toString());
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        throw Exception('Could not open Stripe Checkout in this browser.');
      }
    } catch (error) {
      if (mounted) setState(() => _error = error.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: widget.authService,
        builder: (context, _) {
          final paid = widget.authService.subscriptionStatus == 'active' || widget.authService.subscriptionStatus == 'trialing';
          return Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFFE4E6DE))),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                const Icon(Icons.receipt_long_outlined, color: Color(0xFF315E4B), size: 21),
                const SizedBox(width: 10),
                const Expanded(child: Text('Plan & billing', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16))),
                Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5), decoration: BoxDecoration(color: const Color(0xFFE9EDE5), borderRadius: BorderRadius.circular(20)), child: Text(paid ? 'OPERATIONS' : 'STARTER', style: const TextStyle(color: Color(0xFF315E4B), fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.7))),
              ]),
              const SizedBox(height: 10),
              Text(paid ? 'Your workspace has an active subscription.' : 'Start with the basics, then move up when your team needs more room.', style: const TextStyle(color: Color(0xFF737A72), fontSize: 13, height: 1.5)),
              if (paid)
                TextButton.icon(onPressed: widget.authService.loadWorkspace, icon: const Icon(Icons.refresh, size: 15), label: const Text('Refresh subscription status'), style: TextButton.styleFrom(foregroundColor: const Color(0xFF315E4B)))
              else ...[
                const SizedBox(height: 17),
                FilledButton.icon(
                  onPressed: _isLoading ? null : _openCheckout,
                  icon: _isLoading ? const SizedBox.square(dimension: 15, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.open_in_new, size: 16),
                  label: const Text('Try Operations checkout'),
                  style: FilledButton.styleFrom(backgroundColor: const Color(0xFF315E4B), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13)),
                ),
                const SizedBox(height: 7),
                const Text('Stripe test mode · Use a Stripe test card to complete checkout.', style: TextStyle(color: Color(0xFF858B82), fontSize: 11)),
                TextButton.icon(onPressed: widget.authService.loadWorkspace, icon: const Icon(Icons.refresh, size: 15), label: const Text('Refresh plan status'), style: TextButton.styleFrom(foregroundColor: const Color(0xFF315E4B), padding: const EdgeInsets.symmetric(horizontal: 0))),
              ],
              if (_error != null) Padding(padding: const EdgeInsets.only(top: 11), child: Text(_error!, style: const TextStyle(color: Color(0xFF9C4035), fontSize: 12))),
            ]),
          );
        },
      );
}
