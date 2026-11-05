import 'package:flutter/material.dart';
import '../core/app_controller.dart';
import '../widgets/ui.dart';

class LoginScreen extends StatefulWidget {
  final AppController controller;
  const LoginScreen({super.key, required this.controller});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final user = TextEditingController();
  final pass = TextEditingController();
  bool obscure = true;

  @override
  void dispose() {
    user.dispose(); pass.dispose(); super.dispose();
  }

  Future<void> signIn() async {
    if (user.text.trim().isEmpty || pass.text.isEmpty) return;
    await widget.controller.login(user.text, pass.text);
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFF0F8FF), Color(0xFFF6F3FF), Color(0xFFEAFBF4)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(22),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 430),
                child: Column(children: [
                  Image.asset('assets/khalid-networks-logo.png', height: 84, fit: BoxFit.contain),
                  const SizedBox(height: 24),
                  AppCard(
                    padding: const EdgeInsets.all(24),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                      const Text('Staff Sign In', style: TextStyle(fontSize: 27, fontWeight: FontWeight.w900, color: navy)),
                      const SizedBox(height: 6),
                      const Text('Use the Staff ID and password provided by your office.', style: TextStyle(color: Color(0xFF71809B), height: 1.4)),
                      const SizedBox(height: 24),
                      TextField(
                        controller: user,
                        textInputAction: TextInputAction.next,
                        decoration: fieldDecoration('Staff ID', hint: 'e.g. farhan', icon: Icons.badge_outlined),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: pass,
                        obscureText: obscure,
                        onSubmitted: (_) => signIn(),
                        decoration: fieldDecoration('Password', icon: Icons.lock_outline).copyWith(
                          suffixIcon: IconButton(icon: Icon(obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined), onPressed: () => setState(() => obscure = !obscure)),
                        ),
                      ),
                      if (widget.controller.error != null) ...[
                        const SizedBox(height: 14),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(color: const Color(0xFFFFF0F0), borderRadius: BorderRadius.circular(14)),
                          child: Text(widget.controller.error!, style: const TextStyle(color: Color(0xFFB42318))),
                        ),
                      ],
                      const SizedBox(height: 20),
                      SizedBox(
                        height: 54,
                        child: FilledButton.icon(
                          onPressed: widget.controller.busy ? null : signIn,
                          icon: widget.controller.busy
                              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : const Icon(Icons.login_rounded),
                          label: Text(widget.controller.busy ? 'Signing in…' : 'Sign In'),
                        ),
                      ),
                    ]),
                  ),
                  const SizedBox(height: 20),
                  const Text('Khalid Networks • Fast • Reliable • Always Connected', textAlign: TextAlign.center, style: TextStyle(color: Color(0xFF71809B), fontSize: 12)),
                ]),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
