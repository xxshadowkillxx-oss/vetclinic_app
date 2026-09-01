import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/api_service.dart';
import '../utils/rut.dart';
import 'mascotas_screen.dart';

class RegistroDuenoScreen extends StatefulWidget {
  const RegistroDuenoScreen({super.key});

  @override
  State<RegistroDuenoScreen> createState() => _RegistroDuenoScreenState();
}

class _RegistroDuenoScreenState extends State<RegistroDuenoScreen> {
  final _nombreCtrl = TextEditingController();
  final _rutCtrl = TextEditingController();
  final _telefonoCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmarPassCtrl = TextEditingController();

  bool _loading = false;
  bool _verPass = false;
  String? _error;

  Future<void> _registrar() async {
    final nombre = _nombreCtrl.text.trim();
    final rut = _rutCtrl.text.trim();
    final telefonoLocal = _telefonoCtrl.text.trim();
    final email = _emailCtrl.text.trim();
    final password = _passCtrl.text;

    if ([
      nombre,
      rut,
      telefonoLocal,
      email,
      password,
      _confirmarPassCtrl.text,
    ].any((value) => value.isEmpty)) {
      setState(() => _error = 'Completa todos los campos');
      return;
    }
    if (!isValidRut(rut)) {
      setState(() => _error = 'Ingresa un RUT válido');
      return;
    }
    if (!RegExp(r'^\d{8}$').hasMatch(telefonoLocal)) {
      setState(() => _error = 'Ingresa los 8 dígitos de tu teléfono móvil');
      return;
    }
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      setState(() => _error = 'Ingresa un correo electrónico válido');
      return;
    }
    if (password.length < 6) {
      setState(() => _error = 'La contraseña debe tener al menos 6 caracteres');
      return;
    }
    if (password != _confirmarPassCtrl.text) {
      setState(() => _error = 'Las contraseñas no coinciden');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });
    final res = await ApiService.registrarDueno(
      nombre: nombre,
      rut: rut,
      telefono: '+569$telefonoLocal',
      email: email,
      password: password,
    );
    if (!mounted) return;
    setState(() => _loading = false);

    if (res['success'] == true) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const MascotasScreen()),
        (_) => false,
      );
    } else {
      setState(() => _error = res['message'] ?? 'No fue posible registrarte');
    }
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _rutCtrl.dispose();
    _telefonoCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _confirmarPassCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE3F0FB),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('Crear cuenta'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Image.asset(
                'assets/logo_vetclinic_4k.png',
                height: 105,
                fit: BoxFit.contain,
                semanticLabel: 'Logo de VetClinic',
              ),
              const SizedBox(height: 8),
              const Text(
                'Registro del dueño',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E3A5F),
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Usaremos tu RUT para mostrar todas las mascotas asociadas.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
              ),
              const SizedBox(height: 24),
              _field(_nombreCtrl, 'Nombre completo', Icons.person_outline),
              _field(
                _rutCtrl,
                'RUT (ej: 12.345.678-5)',
                Icons.badge_outlined,
                inputFormatters: [RutInputFormatter()],
              ),
              _field(
                _telefonoCtrl,
                '1234 5678',
                Icons.phone_outlined,
                keyboardType: TextInputType.phone,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(8),
                ],
                fixedPrefix: '+569',
              ),
              _field(
                _emailCtrl,
                'Correo electrónico',
                Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
              ),
              _field(
                _passCtrl,
                'Contraseña (mínimo 6 caracteres)',
                Icons.lock_outline,
                obscure: !_verPass,
                suffix: _passwordButton(),
              ),
              _field(
                _confirmarPassCtrl,
                'Confirmar contraseña',
                Icons.lock_reset_outlined,
                obscure: !_verPass,
              ),
              if (_error != null) ...[
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFFCA5A5)),
                  ),
                  child: Text(
                    _error!,
                    style: const TextStyle(color: Color(0xFFB91C1C)),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: _loading ? null : _registrar,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _loading
                      ? const CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        )
                      : const Text(
                          'Registrarme',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController controller,
    String hint,
    IconData icon, {
    TextInputType? keyboardType,
    bool obscure = false,
    List<TextInputFormatter>? inputFormatters,
    Widget? suffix,
    String? fixedPrefix,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        obscureText: obscure,
        inputFormatters: inputFormatters,
        enabled: !_loading,
        decoration: InputDecoration(
          hintText: hint,
          prefixIcon: fixedPrefix == null
              ? Icon(icon)
              : Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(icon),
                      const SizedBox(width: 10),
                      Text(
                        fixedPrefix,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
          suffixIcon: suffix,
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _passwordButton() {
    return IconButton(
      onPressed: () => setState(() => _verPass = !_verPass),
      icon: Icon(_verPass ? Icons.visibility_off : Icons.visibility),
    );
  }
}
