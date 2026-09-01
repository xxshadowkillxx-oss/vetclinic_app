import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/portal_models.dart';
import '../services/api_service.dart';

class PerfilScreen extends StatefulWidget {
  const PerfilScreen({super.key});

  @override
  State<PerfilScreen> createState() => _PerfilScreenState();
}

class _PerfilScreenState extends State<PerfilScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombre = TextEditingController();
  final _telefono = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _cargando = true;
  bool _guardando = false;
  String _rut = '';
  Map<String, dynamic> _clinica = {};

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    final resultados = await Future.wait([
      ApiService.getPerfil(),
      ApiService.getInicio(),
    ]);
    final perfil = resultados[0] as PerfilDueno?;
    final inicio = resultados[1] as Map<String, dynamic>;
    if (perfil != null) {
      _rut = perfil.rut;
      _nombre.text = perfil.nombre;
      _telefono.text = perfil.telefono;
      _email.text = perfil.email;
    }
    _clinica = inicio['clinica'] is Map
        ? Map<String, dynamic>.from(inicio['clinica'] as Map)
        : {};
    if (mounted) setState(() => _cargando = false);
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _guardando = true);
    final respuesta = await ApiService.actualizarPerfil(
      nombre: _nombre.text,
      telefono: _telefono.text,
      email: _email.text,
      password: _password.text,
    );
    if (!mounted) return;
    setState(() => _guardando = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(respuesta['message']?.toString() ?? 'Perfil actualizado'),
      ),
    );
    if (respuesta['success'] == true) _password.clear();
  }

  Future<void> _abrir(String scheme, String valor) async {
    final limpio = scheme == 'https'
        ? valor.replaceAll(RegExp(r'\D'), '')
        : valor;
    final uri = scheme == 'https'
        ? Uri.parse('https://wa.me/$limpio')
        : Uri(scheme: scheme, path: limpio);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication) &&
        mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No fue posible abrir esta opción')),
      );
    }
  }

  @override
  void dispose() {
    _nombre.dispose();
    _telefono.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final telefonoClinica = _clinica['telefono_clinica']?.toString() ?? '';
    final whatsapp = _clinica['whatsapp_clinica']?.toString() ?? '';
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(title: const Text('Mi perfil y contacto')),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  const Text(
                    'Contacto rápido',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: telefonoClinica.isEmpty
                              ? null
                              : () => _abrir('tel', telefonoClinica),
                          icon: const Icon(Icons.call),
                          label: const Text('Llamar'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: FilledButton.icon(
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF16A34A),
                          ),
                          onPressed: whatsapp.isEmpty
                              ? null
                              : () => _abrir('https', whatsapp),
                          icon: const Icon(Icons.chat),
                          label: const Text('WhatsApp'),
                        ),
                      ),
                    ],
                  ),
                  if (telefonoClinica.isEmpty && whatsapp.isEmpty)
                    const Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: Text(
                        'La veterinaria debe completar sus datos de contacto en Configuración.',
                        style: TextStyle(color: Color(0xFF64748B)),
                      ),
                    ),
                  const SizedBox(height: 28),
                  const Text(
                    'Datos del dueño',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    initialValue: _rut,
                    enabled: false,
                    decoration: const InputDecoration(
                      labelText: 'RUT',
                      prefixIcon: Icon(Icons.badge_outlined),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _nombre,
                    decoration: const InputDecoration(
                      labelText: 'Nombre completo',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                    validator: (value) => (value ?? '').trim().isEmpty
                        ? 'Ingresa tu nombre'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _telefono,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'Teléfono',
                      prefixIcon: Icon(Icons.phone_outlined),
                    ),
                    validator: (value) => (value ?? '').trim().length < 8
                        ? 'Ingresa un teléfono válido'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Correo electrónico',
                      prefixIcon: Icon(Icons.email_outlined),
                    ),
                    validator: (value) =>
                        !RegExp(
                          r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                        ).hasMatch((value ?? '').trim())
                        ? 'Ingresa un correo válido'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _password,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Nueva contraseña (opcional)',
                      helperText: 'Déjala vacía para conservar la actual',
                      prefixIcon: Icon(Icons.lock_outline),
                    ),
                    validator: (value) =>
                        (value ?? '').isNotEmpty && (value ?? '').length < 8
                        ? 'Debe tener al menos 8 caracteres'
                        : null,
                  ),
                  const SizedBox(height: 22),
                  SizedBox(
                    height: 52,
                    child: FilledButton.icon(
                      key: const Key('guardarPerfilButton'),
                      onPressed: _guardando ? null : _guardar,
                      icon: _guardando
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.save_outlined),
                      label: const Text('Guardar cambios'),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
