import 'package:flutter/material.dart';
import '../../services/auth_service.dart';

const _authInk = Color(0xFF202720);
const _authMuted = Color(0xFF737A72);
const _authGreen = Color(0xFF315E4B);
const _authPaper = Color(0xFFF6F6F1);

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, required this.authService, required this.onLoginSuccess, this.startingOnSignUp = false});
  final AuthService authService;
  final VoidCallback onLoginSuccess;
  final bool startingOnSignUp;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  late bool _isRegistering = widget.startingOnSignUp;
  bool _showPassword = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final success = _isRegistering
        ? await widget.authService.register(name: _nameController.text, email: _emailController.text, password: _passwordController.text)
        : await widget.authService.login(email: _emailController.text, password: _passwordController.text);
    if (!mounted) return;
    if (success) widget.onLoginSuccess();
  }

  Future<void> _google() async {
    await widget.authService.signInWithGoogle();
    if (mounted && widget.authService.isAuthenticated) widget.onLoginSuccess();
  }

  Future<void> _resetPassword() async {
    if (_emailController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter your email address first.')));
      return;
    }
    await widget.authService.sendPasswordReset(_emailController.text);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _authPaper,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(22),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1060),
              child: LayoutBuilder(builder: (context, constraints) {
                final wide = constraints.maxWidth > 900;
                return Container(
                  decoration: BoxDecoration(color: Colors.white, border: Border.all(color: const Color(0xFFE4E6DE)), borderRadius: BorderRadius.circular(18), boxShadow: const [BoxShadow(color: Color(0x0D18221A), blurRadius: 35, offset: Offset(0, 15))]),
                  clipBehavior: Clip.antiAlias,
                  child: wide
                      ? IntrinsicHeight(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(flex: 5, child: _welcomePanel()),
                              Expanded(
                                flex: 6,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 46),
                                  child: _formPanel(),
                                ),
                              ),
                            ],
                          ),
                        )
                      : Padding(padding: const EdgeInsets.all(26), child: Column(children: [_welcomePanel(compact: true), const SizedBox(height: 25), _formPanel()])),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }

  Widget _welcomePanel({bool compact = false}) => Container(
        constraints: BoxConstraints(minHeight: compact ? 0 : 570),
        padding: EdgeInsets.all(compact ? 0 : 42),
        decoration: BoxDecoration(color: const Color(0xFFE9EDE5), borderRadius: compact ? BorderRadius.zero : const BorderRadius.horizontal(left: Radius.circular(18))),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: compact ? MainAxisAlignment.start : MainAxisAlignment.spaceBetween, children: [
          Row(children: [Container(width: 35, height: 35, decoration: BoxDecoration(color: _authGreen, borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.route_rounded, color: Colors.white, size: 19)), const SizedBox(width: 10), const Text('stark fleet', style: TextStyle(color: _authInk, fontSize: 18, fontWeight: FontWeight.w700, letterSpacing: -0.5))]),
          if (!compact) ...[
            const SizedBox(height: 70),
            Text(_isRegistering ? 'A better start for your fleet.' : 'Good to have you back.', style: const TextStyle(color: _authInk, fontSize: 33, letterSpacing: -1.2, height: 1.1, fontWeight: FontWeight.w600)),
            const SizedBox(height: 15),
            Text(_isRegistering ? 'Create a workspace for your company, then bring the people and records that keep your fleet moving.' : 'Pick up where your team left off. Your fleet records will be right where you expect them.', style: const TextStyle(color: _authMuted, fontSize: 15, height: 1.65)),
            const SizedBox(height: 40),
            const _WelcomePoint(icon: Icons.inventory_2_outlined, title: 'Fleet records in one place'),
            const _WelcomePoint(icon: Icons.event_available_outlined, title: 'Upcoming work, easier to see'),
            const _WelcomePoint(icon: Icons.people_outline, title: 'A workspace for your team'),
            const SizedBox(height: 30),
            const Text('A calmer way to keep things moving.', style: TextStyle(color: Color(0xFF68766B), fontSize: 12)),
          ],
        ]),
      );

  Widget _formPanel() => ListenableBuilder(
        listenable: widget.authService,
        builder: (context, _) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(_isRegistering ? 'Create your workspace account' : 'Sign in to your workspace', style: const TextStyle(color: _authInk, fontSize: 25, fontWeight: FontWeight.w600, letterSpacing: -0.7)),
          const SizedBox(height: 8),
          Text(_isRegistering ? 'Use your work email. You can invite your team after setup.' : 'Use the email address connected to your Stark Fleet account.', style: const TextStyle(color: _authMuted, fontSize: 13, height: 1.5)),
          const SizedBox(height: 26),
          SizedBox(width: double.infinity, height: 48, child: OutlinedButton.icon(onPressed: widget.authService.isLoading ? null : _google, icon: const _GoogleGlyph(), label: const Text('Continue with Google'), style: OutlinedButton.styleFrom(foregroundColor: _authInk, side: const BorderSide(color: Color(0xFFDDE0D8)), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))))),
          const SizedBox(height: 20),
          const Row(children: [Expanded(child: Divider(color: Color(0xFFE7E8E2))), Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: Text('OR WITH EMAIL', style: TextStyle(color: _authMuted, fontSize: 10, letterSpacing: 1, fontWeight: FontWeight.w600))), Expanded(child: Divider(color: Color(0xFFE7E8E2)))]),
          const SizedBox(height: 19),
          Form(
            key: _formKey,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              if (_isRegistering) ...[
                const _FieldLabel('Your name'),
                TextFormField(controller: _nameController, textCapitalization: TextCapitalization.words, autofillHints: const [AutofillHints.name], decoration: _input('Name your teammates will recognize'), validator: (value) => value == null || value.trim().isEmpty ? 'Add your name.' : null),
                const SizedBox(height: 15),
              ],
              const _FieldLabel('Work email'),
              TextFormField(controller: _emailController, keyboardType: TextInputType.emailAddress, autofillHints: const [AutofillHints.email], decoration: _input('you@company.com'), validator: (value) => value == null || !value.contains('@') || !value.contains('.') ? 'Enter a valid email address.' : null),
              const SizedBox(height: 15),
              const _FieldLabel('Password'),
              TextFormField(controller: _passwordController, obscureText: !_showPassword, autofillHints: _isRegistering ? const [AutofillHints.newPassword] : const [AutofillHints.password], decoration: _input('At least 8 characters').copyWith(suffixIcon: IconButton(onPressed: () => setState(() => _showPassword = !_showPassword), icon: Icon(_showPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 18, color: _authMuted))), validator: (value) => value == null || value.length < 8 ? 'Use at least 8 characters.' : null),
            ]),
          ),
          if (!_isRegistering) Align(alignment: Alignment.centerRight, child: TextButton(onPressed: widget.authService.isLoading ? null : _resetPassword, style: TextButton.styleFrom(foregroundColor: _authGreen, padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 8)), child: const Text('Forgot password?'))),
          if (widget.authService.errorMessage != null) _MessageBox(text: widget.authService.errorMessage!, error: true),
          if (widget.authService.infoMessage != null) _MessageBox(text: widget.authService.infoMessage!, error: false),
          if (!widget.authService.isConfigured) const _MessageBox(text: 'Authentication is not configured for this local build yet. Add your Supabase project URL and publishable key to run configuration.', error: false),
          const SizedBox(height: 10),
          SizedBox(width: double.infinity, height: 48, child: FilledButton(onPressed: widget.authService.isLoading ? null : _submit, style: FilledButton.styleFrom(backgroundColor: _authGreen, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))), child: widget.authService.isLoading ? const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : Text(_isRegistering ? 'Create account' : 'Sign in', style: const TextStyle(fontWeight: FontWeight.w600)))),
          const SizedBox(height: 18),
          Center(child: Wrap(alignment: WrapAlignment.center, children: [Text(_isRegistering ? 'Already have a workspace?' : 'New to Stark Fleet?', style: const TextStyle(color: _authMuted, fontSize: 12)), TextButton(onPressed: () => setState(() { _isRegistering = !_isRegistering; widget.authService.clearMessages(); }), style: TextButton.styleFrom(foregroundColor: _authGreen, padding: const EdgeInsets.only(left: 5)), child: Text(_isRegistering ? 'Sign in' : 'Create an account', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)))])),
          Center(child: TextButton(onPressed: () => Navigator.pop(context), style: TextButton.styleFrom(foregroundColor: _authMuted), child: const Text('Back to Stark Fleet', style: TextStyle(fontSize: 12)))),
        ]),
      );

  InputDecoration _input(String hint) => InputDecoration(hintText: hint, hintStyle: const TextStyle(color: Color(0xFFADB2AA), fontSize: 13), filled: true, fillColor: const Color(0xFFFAFAF8), contentPadding: const EdgeInsets.symmetric(horizontal: 13, vertical: 14), enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFE3E5DE))), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: _authGreen, width: 1.3)), errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFB85448))), focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFB85448))));
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.only(bottom: 7), child: Text(text, style: const TextStyle(color: _authInk, fontWeight: FontWeight.w600, fontSize: 12)));
}

class _MessageBox extends StatelessWidget {
  const _MessageBox({required this.text, required this.error});
  final String text;
  final bool error;
  @override
  Widget build(BuildContext context) => Container(width: double.infinity, margin: const EdgeInsets.only(top: 13), padding: const EdgeInsets.all(11), decoration: BoxDecoration(color: error ? const Color(0xFFFFF1EF) : const Color(0xFFEEF4EC), borderRadius: BorderRadius.circular(8)), child: Text(text, style: TextStyle(color: error ? const Color(0xFF8B352C) : _authGreen, fontSize: 12, height: 1.45)));
}

class _WelcomePoint extends StatelessWidget {
  const _WelcomePoint({required this.icon, required this.title});
  final IconData icon;
  final String title;
  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.only(bottom: 17), child: Row(children: [Icon(icon, color: _authGreen, size: 18), const SizedBox(width: 11), Text(title, style: const TextStyle(color: _authInk, fontSize: 13, fontWeight: FontWeight.w500))]));
}

class _GoogleGlyph extends StatelessWidget {
  const _GoogleGlyph();
  @override
  Widget build(BuildContext context) => const Text('G', style: TextStyle(color: Color(0xFF4285F4), fontSize: 17, fontWeight: FontWeight.w700));
}
