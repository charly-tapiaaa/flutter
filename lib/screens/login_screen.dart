import 'package:flutter/material.dart';

import '../services/product_api.dart';
import 'product_catalog_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, this.api});

  final ProductApi? api;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  static const _demoUsername = 'admin';
  static const _demoPassword = '123456';

  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final Map<String, String> _registeredUsers = {};
  bool _isRegistering = false;
  bool _hidePassword = true;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final username = _usernameController.text.trim();
    final password = _passwordController.text;

    if (_isRegistering) {
      if (username == _demoUsername || _registeredUsers.containsKey(username)) {
        _showMessage('Ese usuario ya existe.');
        return;
      }
      _registeredUsers[username] = password;
      setState(() => _isRegistering = false);
      _passwordController.clear();
      _showMessage('Cuenta creada. Ya puedes iniciar sesión.');
      return;
    }

    final validCredentials =
        username == _demoUsername && password == _demoPassword;
    final registeredPassword = _registeredUsers[username];
    if (!validCredentials && registeredPassword != password) {
      _showMessage('Usuario o contraseña incorrectos.');
      return;
    }

    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => ProductCatalogScreen(
          username: username,
          api: widget.api,
        ),
      ),
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    height: size.width < 380 ? 100 : 128,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE4F2EE),
                      borderRadius: BorderRadius.circular(28),
                    ),
                    child: const Icon(
                      Icons.storefront_rounded,
                      size: 62,
                      color: Color(0xFF087E75),
                    ),
                  ),
                  const SizedBox(height: 30),
                  Text(
                    _isRegistering ? 'Crea tu cuenta' : 'Bienvenido a Tapia Store',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.8,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _isRegistering
                        ? 'Regístrate para administrar tu catálogo.'
                        : 'Tu catálogo, organizado en un solo lugar.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: const Color(0xFF68736E),
                        ),
                  ),
                  const SizedBox(height: 28),
                  Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextFormField(
                          controller: _usernameController,
                          textInputAction: TextInputAction.next,
                          autofillHints: const [AutofillHints.username],
                          decoration: const InputDecoration(
                            labelText: 'Usuario',
                            prefixIcon: Icon(Icons.person_outline_rounded),
                          ),
                          validator: (value) => value == null || value.trim().isEmpty
                              ? 'Ingresa tu usuario.'
                              : null,
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: _hidePassword,
                          textInputAction: TextInputAction.done,
                          autofillHints: const [AutofillHints.password],
                          onFieldSubmitted: (_) => _submit(),
                          decoration: InputDecoration(
                            labelText: 'Contraseña',
                            prefixIcon: const Icon(Icons.lock_outline_rounded),
                            suffixIcon: IconButton(
                              tooltip: _hidePassword
                                  ? 'Mostrar contraseña'
                                  : 'Ocultar contraseña',
                              onPressed: () => setState(
                                () => _hidePassword = !_hidePassword,
                              ),
                              icon: Icon(
                                _hidePassword
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                              ),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Ingresa tu contraseña.';
                            }
                            if (_isRegistering && value.length < 6) {
                              return 'Usa al menos 6 caracteres.';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 22),
                        SizedBox(
                          height: 54,
                          child: FilledButton(
                            onPressed: _submit,
                            child: Text(
                              _isRegistering ? 'Crear cuenta' : 'Ingresar',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () => setState(() {
                      _isRegistering = !_isRegistering;
                      _formKey.currentState?.reset();
                    }),
                    child: Text(
                      _isRegistering
                          ? '¿Ya tienes cuenta? Inicia sesión'
                          : '¿No tienes cuenta? Regístrate',
                    ),
                  ),
                  if (!_isRegistering) ...[
                    const SizedBox(height: 12),
                    const Text(
                      'Acceso de demostración: admin / 123456',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Color(0xFF68736E), fontSize: 13),
                    ),
                  ],
                  const SizedBox(height: 8),
                  const Text(
                    'Las cuentas registradas se guardan solo durante esta sesión.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Color(0xFF87918D), fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
