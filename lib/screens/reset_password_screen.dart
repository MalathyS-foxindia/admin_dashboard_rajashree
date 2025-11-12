import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ResetPasswordScreen extends StatefulWidget {
  final String? email; // <-- added
  const ResetPasswordScreen({super.key, this.email}); // <-- updated

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final TextEditingController _newPwdCtrl = TextEditingController();
  final TextEditingController _confirmPwdCtrl = TextEditingController();
  bool _loading = false;

  // ✅ Added: detect and recover Supabase session from email link
  @override
  void initState() {
    super.initState();
    _checkRecoverySession();
  }

  Future<void> _checkRecoverySession() async {
    try {
      // Listen for recovery email deep link (Supabase automatically triggers this)
      Supabase.instance.client.auth.onAuthStateChange.listen((data) {
        final AuthChangeEvent event = data.event;
        final Session? session = data.session;

        if (event == AuthChangeEvent.passwordRecovery && session != null) {
          // ✅ Session restored, user can now update password
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("🔐 Recovery session active")),
          );
        }
      });
    } catch (e) {
      debugPrint("Error detecting recovery session: $e");
    }
  }

  Future<void> _resetPassword() async {
    final newPwd = _newPwdCtrl.text.trim();
    final confirmPwd = _confirmPwdCtrl.text.trim();

    if (newPwd.isEmpty || confirmPwd.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter both fields.")),
      );
      return;
    }

    if (newPwd != confirmPwd) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Passwords do not match.")));
      return;
    }

    setState(() => _loading = true);

    try {
      final supabase = Supabase.instance.client;

      // ✅ This works only when recovery session is active
      await supabase.auth.updateUser(UserAttributes(password: newPwd));

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ Password reset successful.")),
      );

      // ✅ Clear session after password reset
      await supabase.auth.signOut();

      Navigator.popUntil(context, (r) => r.isFirst);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("❌ Error: $e")));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Card(
          margin: const EdgeInsets.all(24),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text("Reset Password", style: TextStyle(fontSize: 20)),
                const SizedBox(height: 12),
                TextField(
                  controller: _newPwdCtrl,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: "New Password",
                    prefixIcon: Icon(Icons.lock),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _confirmPwdCtrl,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: "Confirm Password",
                    prefixIcon: Icon(Icons.lock_outline),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    icon: _loading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.refresh),
                    label: const Text("Reset Password"),
                    onPressed: _loading ? null : _resetPassword,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
