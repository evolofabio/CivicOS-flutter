import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/services/tenant_refs.dart';
import 'forgot_password_screen.dart';
import 'registration_screen.dart';

class LoginScreen extends StatefulWidget {
  final VoidCallback onLoginSuccess;

  /// Chiamato quando l'utente risulta operatore abilitato.
  /// Riceve il [comuneId] del comune cui appartiene l'operatore.
  final void Function(String comuneId)? onOperatorLoginSuccess;

  const LoginScreen({
    required this.onLoginSuccess,
    this.onOperatorLoginSuccess,
    Key? key,
  }) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailCtrl = TextEditingController();
  final TextEditingController _passwordCtrl = TextEditingController();
  bool _obscure = true;
  bool _loading = false;

  Future<void> _login({bool operator = false}) async {
    if (_emailCtrl.text.isEmpty || _passwordCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Inserisci email e password')),
      );
      return;
    }
    setState(() => _loading = true);
    try {
      final cred = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailCtrl.text.trim(),
        password: _passwordCtrl.text.trim(),
      );
      final uid = cred.user?.uid;
      if (uid != null && widget.onOperatorLoginSuccess != null) {
        final detectedComuneId = await _detectOperatorComune(uid);
        if (detectedComuneId != null) {
          if (mounted) widget.onOperatorLoginSuccess!(detectedComuneId);
          return;
        }
      }
      if (mounted) widget.onLoginSuccess();
    } on FirebaseAuthException catch (e) {
      String msg;
      switch (e.code) {
        case 'user-not-found':
        case 'wrong-password':
        case 'invalid-credential':
          msg = 'Email o password non corretti';
          break;
        case 'too-many-requests':
          msg = 'Troppi tentativi, riprova più tardi';
          break;
        case 'user-disabled':
          msg = 'Account disabilitato';
          break;
        default:
          msg = e.message ?? 'Errore di accesso';
      }
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(msg)));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  /// Restituisce il comuneId se l'utente è un operatore abilitato, null altrimenti.
  Future<String?> _detectOperatorComune(String uid) async {
    try {
      // Prima prova via bootstrap globale (caso più veloce).
      final comuneId = await TenantRefs.resolveComuneId(uid);
      if (comuneId != null && comuneId.isNotEmpty) {
        final opDoc = await TenantRefs.operatoriDoc(comuneId, uid).get();
        if (opDoc.exists && opDoc.data()?['abilitato'] == true) {
          return comuneId;
        }
      }
      // Fallback: collectionGroup su tutti i comuni (primo accesso operatore).
      final snap = await FirebaseFirestore.instance
          .collectionGroup('operatori')
          .where('uid', isEqualTo: uid)
          .where('abilitato', isEqualTo: true)
          .limit(1)
          .get();
      if (snap.docs.isNotEmpty) {
        final docComuneId = snap.docs.first.reference.parent.parent?.id;
        if (docComuneId != null && docComuneId.isNotEmpty) {
          // Salva nel bootstrap per i login successivi.
          await TenantRefs.saveBootstrap(
            uid: uid,
            comuneId: docComuneId,
            email: FirebaseAuth.instance.currentUser?.email ?? '',
          );
          return docComuneId;
        }
      }
    } catch (e) {
      debugPrint('[Login] Errore rilevamento operatore: $e');
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: cs.surface,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(height: 40),
                Container(
                  padding: EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: cs.surface,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: cs.shadow.withOpacity(0.08),
                        blurRadius: 16,
                        offset: Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Image.asset(
                    'assets/CivicOS-Remove.png',
                    height: 72,
                    fit: BoxFit.contain,
                  ),
                ),
                SizedBox(height: 24),
                Text(
                  'Accedi',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: cs.onSurface,
                  ),
                ),
                SizedBox(height: 32),
                TextFormField(
                  key: const Key('emailField'),
                  controller: _emailCtrl,
                  style: TextStyle(color: cs.onSurface),
                  decoration: InputDecoration(
                    hintText: 'Email',
                    hintStyle: TextStyle(color: cs.onSurface.withOpacity(0.7)),
                    filled: true,
                    fillColor: cs.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    prefixIcon: Icon(Icons.email, color: cs.primary),
                  ),
                ),
                SizedBox(height: 18),
                TextFormField(
                  key: const Key('passwordField'),
                  controller: _passwordCtrl,
                  obscureText: _obscure,
                  style: TextStyle(color: cs.onSurface),
                  decoration: InputDecoration(
                    hintText: 'Password',
                    hintStyle: TextStyle(color: cs.onSurface.withOpacity(0.7)),
                    filled: true,
                    fillColor: cs.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    prefixIcon: Icon(Icons.lock, color: cs.primary),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscure ? Icons.visibility : Icons.visibility_off,
                        color: cs.primary,
                      ),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                  ),
                ),
                SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _loading ? null : () => _login(operator: false),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: cs.primary,
                      foregroundColor: cs.onPrimary,
                      textStyle: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: _loading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Accedi'),
                  ),
                ),
                SizedBox(height: 18),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const ForgotPasswordScreen(),
                      ),
                    );
                  },
                  child: Text(
                    'Password dimenticata?',
                    style: TextStyle(color: cs.primary),
                  ),
                  style: TextButton.styleFrom(foregroundColor: cs.primary),
                ),
                SizedBox(height: 28),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Non hai un account? ',
                      style: TextStyle(
                        color: cs.onSurface.withOpacity(0.7),
                        fontSize: 13,
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => RegistrationScreen(
                              onRegistrationSuccess: widget.onLoginSuccess,
                            ),
                          ),
                        );
                      },
                      child: Text(
                        'Registrati',
                        style: TextStyle(
                          color: cs.primary,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// End of LoginScreen widget
