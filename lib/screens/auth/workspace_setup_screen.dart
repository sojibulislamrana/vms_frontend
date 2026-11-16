import 'package:flutter/material.dart';
import '../../services/auth_service.dart';

const _setupGreen = Color(0xFF315E4B);
const _setupInk = Color(0xFF202720);

class WorkspaceSetupScreen extends StatefulWidget {
  const WorkspaceSetupScreen({super.key, required this.authService});
  final AuthService authService;

  @override
  State<WorkspaceSetupScreen> createState() => _WorkspaceSetupScreenState();
}

class _WorkspaceSetupScreenState extends State<WorkspaceSetupScreen> {
  final _nameController = TextEditingController();
  bool _creating = false;

  @override
  void initState() {
    super.initState();
    final user = widget.authService.currentUser;
    _nameController.text = user == null ? '' : '${user.name}’s Fleet';
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    if (_nameController.text.trim().isEmpty) return;
    setState(() => _creating = true);
    await widget.authService.createWorkspace(_nameController.text);
    if (mounted) setState(() => _creating = false);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: const Color(0xFFF6F6F1),
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
            child: ListenableBuilder(
              listenable: widget.authService,
              builder: (context, _) => Container(
                width: 500,
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFE4E6DE))),
                child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Icon(Icons.apartment_outlined, color: _setupGreen, size: 25),
                  const SizedBox(height: 18),
                  const Text('Create your fleet workspace', style: TextStyle(color: _setupInk, fontSize: 25, letterSpacing: -0.7, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  const Text('This will be the private home for your company’s vehicles and operations.', style: TextStyle(color: Color(0xFF737A72), fontSize: 13, height: 1.5)),
                  const SizedBox(height: 24),
                  TextField(controller: _nameController, textCapitalization: TextCapitalization.words, decoration: const InputDecoration(labelText: 'Workspace name', hintText: 'e.g. Northside Logistics', border: OutlineInputBorder())),
                  if (widget.authService.errorMessage != null) ...[
                    const SizedBox(height: 13),
                    Text(widget.authService.errorMessage!, style: const TextStyle(color: Color(0xFF9C4035), fontSize: 12)),
                  ],
                  const SizedBox(height: 21),
                  SizedBox(width: double.infinity, child: FilledButton(onPressed: _creating || widget.authService.isWorkspaceLoading ? null : _create, style: FilledButton.styleFrom(backgroundColor: _setupGreen, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 15)), child: _creating ? const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Create workspace'))),
                  Align(alignment: Alignment.center, child: TextButton(onPressed: widget.authService.logout, style: TextButton.styleFrom(foregroundColor: const Color(0xFF737A72)), child: const Text('Sign out'))),
                ]),
              ),
            ),
          ),
        ),
      );
}
