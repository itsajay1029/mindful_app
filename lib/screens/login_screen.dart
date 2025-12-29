import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import 'auth_gate.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  static const _logoPath = 'assets/branding/logo.png';

  final _formKey = GlobalKey<FormState>();

  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  AuthService get _authService => AuthService();
  FirestoreService get _firestoreService => FirestoreService();

  bool _isLoading = false;
  bool _useEmailPassword = false;
  bool _isSignUp = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  String? _error;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _setError(String? value) => setState(() => _error = value);

  String? _validateName(String? value, {required String fieldLabel}) {
    final v = (value ?? '').trim();
    if (v.isEmpty) return '$fieldLabel is required.';
    if (v.length < 2) return 'Enter a valid $fieldLabel.';
    return null;
  }

  String? _validateEmail(String? value) {
    final trimmed = (value ?? '').trim();
    if (trimmed.isEmpty) return 'Email is required.';
    // basic email pattern (kept simple; good enough for UI-level validation)
    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!emailRegex.hasMatch(trimmed)) return 'Enter a valid email.';
    return null;
  }

  String? _validatePassword(String? value) {
    final password = value ?? '';
    if (password.isEmpty) return 'Password is required.';
    if (password.length < 6) return 'Password must be at least 6 characters.';
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    final confirm = value ?? '';
    if (confirm.isEmpty) return 'Confirm password is required.';
    if (confirm != _passwordController.text) return 'Passwords do not match.';
    return null;
  }

  Future<void> _run(Future<void> Function() action) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await action();

      if (!mounted) return;
      // Hand control back to AuthGate; it will route to Onboarding/Dashboard.
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const AuthGate()),
      );
    } on FirebaseAuthException catch (e) {
      _setError(e.message ?? e.code);
    } catch (e) {
      _setError(e.toString());
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _signInWithGoogle() async {
    await _run(() async {
      await _authService.signInWithGoogle();
    });
  }

  Future<void> _submitEmailPassword() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) return;

    final email = _emailController.text.trim();
    final password = _passwordController.text;

    await _run(() async {
      if (_isSignUp) {
        final cred = await _authService.signUpWithEmail(
          email: email,
          password: password,
        );

        final user = cred.user;
        if (user != null) {
          await _firestoreService.upsertUserProfile(
            uid: user.uid,
            email: email,
            firstName: _firstNameController.text.trim(),
            lastName: _lastNameController.text.trim(),
          );
        }
      } else {
        await _authService.signInWithEmail(
          email: email,
          password: password,
        );
      }
    });
  }

  void _toggleAuthMode() {
    setState(() {
      _isSignUp = !_isSignUp;
      _useEmailPassword = true; // show form immediately in either mode
      _error = null;
    });

    // reset some form state
    _formKey.currentState?.reset();
    _passwordController.clear();
    _confirmPasswordController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Top curved background
          Align(
            alignment: Alignment.topCenter,
            child: Container(
              height: 240,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    cs.primary.withValues(alpha: 0.95),
                    cs.secondary.withValues(alpha: 0.95),
                  ],
                ),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(32),
                  bottomRight: Radius.circular(32),
                ),
              ),
            ),
          ),

          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 20),
                    Text(
                      _isSignUp ? 'Create account,' : 'Welcome Back,',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Colors.white,
                          ),
                    ),
                    Text(
                      _isSignUp ? 'Sign Up!' : 'Log In!',
                      style: Theme.of(context).textTheme.displaySmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 18),

                    // Card
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            blurRadius: 24,
                            color: Colors.black.withValues(alpha: 0.12),
                            offset: const Offset(0, 12),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Image.asset(
                            _logoPath,
                            height: 72,
                            errorBuilder: (context, error, stack) => Icon(
                              Icons.image,
                              size: 56,
                              color: cs.primary,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'AboveTheGrind',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _isSignUp ? 'Create your account' : 'Sign in to continue',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 16),

                          if (_error != null) ...[
                            Text(
                              _error!,
                              style: TextStyle(color: cs.error),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 10),
                          ],

                          // Google sign-in
                          if (!_isSignUp) ...[
                            SizedBox(
                              width: double.infinity,
                              child: FilledButton(
                                onPressed: _isLoading ? null : _signInWithGoogle,
                                style: FilledButton.styleFrom(
                                  backgroundColor: cs.primary,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                child: _isLoading
                                    ? const SizedBox(
                                        height: 18,
                                        width: 18,
                                        child: CircularProgressIndicator(strokeWidth: 2),
                                      )
                                    : const Text('Continue with Google'),
                              ),
                            ),

                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(child: Divider(color: Colors.grey.shade300)),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 10),
                                  child: Text(
                                    'or',
                                    style: Theme.of(context).textTheme.bodySmall,
                                  ),
                                ),
                                Expanded(child: Divider(color: Colors.grey.shade300)),
                              ],
                            ),
                          ],

                          const SizedBox(height: 8),
                          TextButton(
                            onPressed: _isLoading
                                ? null
                                : () => setState(() => _useEmailPassword = !_useEmailPassword),
                            child: Text(
                              _useEmailPassword
                                  ? 'Hide email/password'
                                  : (_isSignUp
                                      ? 'Use email/password to sign up'
                                      : 'Use email/password instead'),
                            ),
                          ),

                          if (_useEmailPassword) ...[
                            const SizedBox(height: 8),
                            Form(
                              key: _formKey,
                              child: Column(
                                children: [
                                  if (_isSignUp) ...[
                                    TextFormField(
                                      controller: _firstNameController,
                                      textInputAction: TextInputAction.next,
                                      decoration: InputDecoration(
                                        labelText: 'First name',
                                        prefixIcon: const Icon(Icons.person_outline),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(14),
                                        ),
                                      ),
                                      validator: (v) => _validateName(v, fieldLabel: 'First name'),
                                    ),
                                    const SizedBox(height: 12),
                                    TextFormField(
                                      controller: _lastNameController,
                                      textInputAction: TextInputAction.next,
                                      decoration: InputDecoration(
                                        labelText: 'Last name',
                                        prefixIcon: const Icon(Icons.person_outline),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(14),
                                        ),
                                      ),
                                      validator: (v) => _validateName(v, fieldLabel: 'Last name'),
                                    ),
                                    const SizedBox(height: 12),
                                  ],
                                  TextFormField(
                                    controller: _emailController,
                                    keyboardType: TextInputType.emailAddress,
                                    textInputAction: TextInputAction.next,
                                    autofillHints: const [AutofillHints.email],
                                    decoration: InputDecoration(
                                      labelText: 'Email address',
                                      prefixIcon: const Icon(Icons.email_outlined),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                    ),
                                    validator: _validateEmail,
                                  ),
                                  const SizedBox(height: 12),
                                  TextFormField(
                                    controller: _passwordController,
                                    obscureText: _obscurePassword,
                                    textInputAction: _isSignUp
                                        ? TextInputAction.next
                                        : TextInputAction.done,
                                    autofillHints: const [AutofillHints.password],
                                    decoration: InputDecoration(
                                      labelText: 'Password',
                                      prefixIcon: const Icon(Icons.lock_outline),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      suffixIcon: IconButton(
                                        onPressed: _isLoading
                                            ? null
                                            : () => setState(
                                                () => _obscurePassword = !_obscurePassword,
                                              ),
                                        icon: Icon(
                                          _obscurePassword
                                              ? Icons.visibility_outlined
                                              : Icons.visibility_off_outlined,
                                        ),
                                      ),
                                    ),
                                    validator: _validatePassword,
                                  ),
                                  if (_isSignUp) ...[
                                    const SizedBox(height: 12),
                                    TextFormField(
                                      controller: _confirmPasswordController,
                                      obscureText: _obscureConfirmPassword,
                                      textInputAction: TextInputAction.done,
                                      decoration: InputDecoration(
                                        labelText: 'Confirm password',
                                        prefixIcon: const Icon(Icons.lock_outline),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(14),
                                        ),
                                        suffixIcon: IconButton(
                                          onPressed: _isLoading
                                              ? null
                                              : () => setState(
                                                  () => _obscureConfirmPassword =
                                                      !_obscureConfirmPassword,
                                                ),
                                          icon: Icon(
                                            _obscureConfirmPassword
                                                ? Icons.visibility_outlined
                                                : Icons.visibility_off_outlined,
                                          ),
                                        ),
                                      ),
                                      validator: _validateConfirmPassword,
                                    ),
                                  ],
                                  const SizedBox(height: 14),
                                  SizedBox(
                                    width: double.infinity,
                                    child: FilledButton(
                                      onPressed: _isLoading ? null : _submitEmailPassword,
                                      style: FilledButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(vertical: 14),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(14),
                                        ),
                                      ),
                                      child: _isLoading
                                          ? const SizedBox(
                                              height: 18,
                                              width: 18,
                                              child: CircularProgressIndicator(strokeWidth: 2),
                                            )
                                          : Text(_isSignUp ? 'Create account' : 'Log in'),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],

                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                _isSignUp
                                    ? 'Already have an account? '
                                    : "Don't have an account? ",
                              ),
                              InkWell(
                                onTap: _isLoading ? null : _toggleAuthMode,
                                child: Text(
                                  _isSignUp ? 'Log in' : 'Sign up',
                                  style: TextStyle(
                                    color: cs.primary,
                                    fontWeight: FontWeight.w700,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 18),
                    Text(
                      'By continuing you agree to the terms & privacy policy.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.white,
                          ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
