import 'package:flutter/material.dart';
import '../models/mascota.dart';
import '../services/api_service.dart';

class UrgenciaScreen extends StatefulWidget {
  final List<Mascota> mascotas;

  const UrgenciaScreen({super.key, required this.mascotas});

  @override
  State<UrgenciaScreen> createState() => _UrgenciaScreenState();
}

class _UrgenciaScreenState extends State<UrgenciaScreen> {
  final _formKey = GlobalKey<FormState>();
  final _motivoCtrl = TextEditingController();
  final _telefonoCtrl = TextEditingController();
  int? _mascotaId;
  int _minutosLlegada = 15;
  String _formaPago = 'por_definir';
  bool _enviando = false;

  @override
  void initState() {
    super.initState();
    if (widget.mascotas.isNotEmpty) {
      _mascotaId = widget.mascotas.first.id;
      _telefonoCtrl.text = widget.mascotas.first.telefono;
    }
  }

  @override
  void dispose() {
    _motivoCtrl.dispose();
    _telefonoCtrl.dispose();
    super.dispose();
  }

  void _cambiarMascota(int? id) {
    setState(() {
      _mascotaId = id;
      final mascota = widget.mascotas
          .where((item) => item.id == id)
          .firstOrNull;
      if (mascota != null && _telefonoCtrl.text.trim().isEmpty) {
        _telefonoCtrl.text = mascota.telefono;
      }
    });
  }

  Future<void> _enviar() async {
    if (!_formKey.currentState!.validate() || _mascotaId == null) return;
    setState(() => _enviando = true);

    final respuesta = await ApiService.solicitarUrgencia(
      mascotaId: _mascotaId!,
      motivo: _motivoCtrl.text,
      telefono: _telefonoCtrl.text,
      minutosLlegada: _minutosLlegada,
      formaPago: _formaPago,
    );

    if (!mounted) return;
    setState(() => _enviando = false);
    final exito = respuesta['success'] == true;
    final mensaje =
        respuesta['message']?.toString() ??
        (exito
            ? 'Urgencia enviada correctamente'
            : 'No fue posible enviar la urgencia');

    await showDialog<void>(
      context: context,
      barrierDismissible: exito,
      builder: (context) => AlertDialog(
        icon: Icon(
          exito ? Icons.mark_email_read_outlined : Icons.error_outline,
          color: exito ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
          size: 42,
        ),
        title: Text(exito ? 'Solicitud recibida' : 'No se pudo enviar'),
        content: Text(mensaje),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Aceptar'),
          ),
        ],
      ),
    );

    if (exito && mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Atención de urgencia'),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF991B1B),
        elevation: 0,
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFFECACA)),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.warning_amber_rounded, color: Color(0xFFDC2626)),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Si existe riesgo vital, llama inmediatamente a la clínica. La solicitud queda pendiente hasta que recepción la confirme.',
                        style: TextStyle(
                          color: Color(0xFF7F1D1D),
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              DropdownButtonFormField<int>(
                initialValue: _mascotaId,
                decoration: _decoracion('Mascota', Icons.pets),
                items: widget.mascotas
                    .map(
                      (mascota) => DropdownMenuItem(
                        value: mascota.id,
                        child: Text('${mascota.nombre} · ${mascota.especie}'),
                      ),
                    )
                    .toList(),
                onChanged: _enviando ? null : _cambiarMascota,
                validator: (value) =>
                    value == null ? 'Selecciona una mascota' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _motivoCtrl,
                minLines: 3,
                maxLines: 5,
                maxLength: 500,
                decoration:
                    _decoracion(
                      '¿Qué está ocurriendo?',
                      Icons.medical_information_outlined,
                    ).copyWith(
                      hintText:
                          'Describe síntomas, accidente o motivo de la urgencia',
                    ),
                validator: (value) {
                  if ((value ?? '').trim().length < 10) {
                    return 'Describe la urgencia con al menos 10 caracteres';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _telefonoCtrl,
                keyboardType: TextInputType.phone,
                decoration: _decoracion(
                  'Teléfono de contacto',
                  Icons.phone_outlined,
                ),
                validator: (value) {
                  final telefono = (value ?? '').trim();
                  if (!RegExp(r'^[0-9+()\s-]{8,30}$').hasMatch(telefono)) {
                    return 'Ingresa un teléfono válido';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<int>(
                initialValue: _minutosLlegada,
                decoration: _decoracion(
                  'Tiempo estimado de llegada',
                  Icons.schedule,
                ),
                items: const [5, 10, 15, 30, 45, 60]
                    .map(
                      (minutos) => DropdownMenuItem(
                        value: minutos,
                        child: Text('$minutos minutos'),
                      ),
                    )
                    .toList(),
                onChanged: _enviando
                    ? null
                    : (value) => setState(() => _minutosLlegada = value ?? 15),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _formaPago,
                decoration: _decoracion(
                  'Forma de pago al llegar',
                  Icons.payments_outlined,
                ),
                items:
                    const {
                          'por_definir': 'Por definir',
                          'efectivo': 'Efectivo',
                          'debito': 'Débito',
                          'credito': 'Crédito',
                          'transferencia': 'Transferencia',
                        }.entries
                        .map(
                          (item) => DropdownMenuItem(
                            value: item.key,
                            child: Text(item.value),
                          ),
                        )
                        .toList(),
                onChanged: _enviando
                    ? null
                    : (value) =>
                          setState(() => _formaPago = value ?? 'por_definir'),
              ),
              const SizedBox(height: 8),
              const Text(
                'La forma de pago es informativa; no se realizará ningún cobro desde la aplicación.',
                style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: 54,
                child: FilledButton.icon(
                  key: const Key('enviarUrgenciaButton'),
                  onPressed: _enviando ? null : _enviar,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFDC2626),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: _enviando
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.emergency),
                  label: Text(
                    _enviando ? 'Enviando...' : 'Enviar urgencia a recepción',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _decoracion(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
    );
  }
}
