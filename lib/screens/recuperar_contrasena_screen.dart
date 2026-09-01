import 'package:flutter/material.dart';

import '../services/api_service.dart';

class RecuperarContrasenaScreen extends StatefulWidget {
  const RecuperarContrasenaScreen({super.key});

  @override
  State<RecuperarContrasenaScreen> createState() =>
      _RecuperarContrasenaScreenState();
}

class _RecuperarContrasenaScreenState extends State<RecuperarContrasenaScreen> {
  final _identificadorCtrl = TextEditingController();
  bool _loading = false;
  String? _error;
  String? _mensajeExito;

  Future<void> _enviarSolicitud() async {
    final identificador = _identificadorCtrl.text.trim();
    if (identificador.isEmpty) {
      setState(() {
        _error = 'Ingresa tu RUT o correo electrónico';
        _mensajeExito = null;
      });
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() {
      _loading = true;
      _error = null;
      _mensajeExito = null;
    });

    final respuesta = await ApiService.recuperarContrasena(identificador);
    if (!mounted) return;

    setState(() {
      _loading = false;
      if (respuesta['success'] == true) {
        _mensajeExito =
            respuesta['message']?.toString() ??
            'Si existe una cuenta asociada, recibirás un enlace por correo.';
      } else {
        _error =
            respuesta['message']?.toString() ??
            'No fue posible enviar la solicitud';
      }
    });
  }

  @override
  void dispose() {
    _identificadorCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE3F0FB),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('Recuperar contraseña'),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
            child: Column(
              children: [
                Image.asset(
                  'assets/logo_vetclinic_4k.png',
                  width: 190,
                  height: 112,
                  fit: BoxFit.contain,
                  semanticLabel: 'Logo de VetClinic',
                ),
                const SizedBox(height: 16),
                const Text(
                  '¿Olvidaste tu contraseña?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 23,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E3A5F),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Ingresa el RUT o correo asociado a tu cuenta. '
                  'Te enviaremos un enlace para crear una nueva contraseña.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                ),
                const SizedBox(height: 28),
                TextField(
                  controller: _identificadorCtrl,
                  enabled: !_loading,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _loading ? null : _enviarSolicitud(),
                  decoration: InputDecoration(
                    hintText: 'RUT o correo electrónico',
                    prefixIcon: const Icon(Icons.alternate_email),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 14),
                  _messageBox(
                    _error!,
                    background: const Color(0xFFFEF2F2),
                    border: const Color(0xFFFCA5A5),
                    foreground: const Color(0xFFB91C1C),
                    icon: Icons.error_outline,
                  ),
                ],
                if (_mensajeExito != null) ...[
                  const SizedBox(height: 14),
                  _messageBox(
                    _mensajeExito!,
                    background: const Color(0xFFF0FDF4),
                    border: const Color(0xFF86EFAC),
                    foreground: const Color(0xFF166534),
                    icon: Icons.mark_email_read_outlined,
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Abre el enlace recibido en tu correo; se abrirá en el '
                    'navegador para completar el cambio de contraseña.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                  ),
                ],
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: _loading ? null : _enviarSolicitud,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: _loading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(Icons.send_outlined, color: Colors.white),
                    label: Text(
                      _loading ? 'Enviando...' : 'Enviar enlace',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                TextButton(
                  onPressed: _loading ? null : () => Navigator.pop(context),
                  child: const Text('Volver al inicio de sesión'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _messageBox(
    String message, {
    required Color background,
    required Color border,
    required Color foreground,
    required IconData icon,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: foreground, size: 20),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: foreground, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
