import 'package:flutter/material.dart';
import '../../services/auth_service.dart';

class PasswordResetScreen extends StatefulWidget {
  const PasswordResetScreen({super.key, required this.authService, required this.onComplete});
  final AuthService authService;
  final VoidCallback onComplete;

  @override
  State<PasswordResetScreen> createState() => _PasswordResetScreenState();
}

class _PasswordResetScreenState extends State<PasswordResetScreen> {
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(_onChanged);
    _confirmController.addListener(_onChanged);
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_passwordController.text.length < 8 || _passwordController.text != _confirmController.text) return;
    if (await widget.authService.updatePassword(_passwordController.text) && mounted) widget.onComplete();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: const Color(0xFFF6F6F1),
        body: Center(
          child: ListenableBuilder(
            listenable: widget.authService,
            builder: (context, _) => Container(
              width: 440,
              margin: const EdgeInsets.all(22),
              padding: const EdgeInsets.all(30),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), border: Border.all(color: const Color(0xFFE4E6DE))),
              child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Choose a new password', style: TextStyle(color: Color(0xFF202720), fontSize: 24, fontWeight: FontWeight.w600)),
                const SizedBox(height: 9),
                const Text('Use at least 8 characters. You can sign in with it straight away.', style: TextStyle(color: Color(0xFF737A72), fontSize: 13)),
                const SizedBox(height: 21),
                TextField(controller: _passwordController, obscureText: true, decoration: const InputDecoration(labelText: 'New password', border: OutlineInputBorder())),
                const SizedBox(height: 13),
                TextField(controller: _confirmController, obscureText: true, decoration: const InputDecoration(labelText: 'Confirm password', border: OutlineInputBorder())),
                if (widget.authService.errorMessage != null) Padding(padding: const EdgeInsets.only(top: 12), child: Text(widget.authService.errorMessage!, style: const TextStyle(color: Color(0xFF9C4035), fontSize: 12))),
                if (_confirmController.text.isNotEmpty && _passwordController.text != _confirmController.text) const Padding(padding: EdgeInsets.only(top: 9), child: Text('The passwords do not match.', style: TextStyle(color: Color(0xFF9C4035), fontSize: 12))),
                const SizedBox(height: 20),
                SizedBox(width: double.infinity, child: FilledButton(onPressed: widget.authService.isLoading ? null : _save, style: FilledButton.styleFrom(backgroundColor: const Color(0xFF315E4B), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14)), child: const Text('Update password'))),
              ]),
            ),
          ),
        ),
      );
}
