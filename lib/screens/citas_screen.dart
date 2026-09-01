import 'package:flutter/material.dart';

import '../models/mascota.dart';
import '../models/portal_models.dart';
import '../services/api_service.dart';

class CitasScreen extends StatefulWidget {
  final List<Mascota> mascotas;

  const CitasScreen({super.key, required this.mascotas});

  @override
  State<CitasScreen> createState() => _CitasScreenState();
}

class _CitasScreenState extends State<CitasScreen> {
  List<Cita> _citas = [];
  bool _cargando = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      _citas = await ApiService.getCitas();
    } catch (_) {
      _error = 'No fue posible cargar las citas';
    }
    if (mounted) setState(() => _cargando = false);
  }

  Future<DateTime?> _seleccionarFecha(DateTime inicial) async {
    final fecha = await showDatePicker(
      context: context,
      initialDate: inicial.isAfter(DateTime.now())
          ? inicial
          : DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (fecha == null || !mounted) return null;
    final hora = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(inicial),
    );
    if (hora == null) return null;
    return DateTime(fecha.year, fecha.month, fecha.day, hora.hour, hora.minute);
  }

  Future<void> _agendar() async {
    if (widget.mascotas.isEmpty) return;
    int mascotaId = widget.mascotas.first.id;
    DateTime fecha = DateTime.now().add(const Duration(days: 1, hours: 1));
    final motivo = TextEditingController();
    final enviar = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          title: const Text('Agendar consulta'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<int>(
                  initialValue: mascotaId,
                  decoration: const InputDecoration(labelText: 'Mascota'),
                  items: widget.mascotas
                      .map(
                        (m) => DropdownMenuItem(
                          value: m.id,
                          child: Text(m.nombre),
                        ),
                      )
                      .toList(),
                  onChanged: (value) => mascotaId = value ?? mascotaId,
                ),
                const SizedBox(height: 12),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.event_outlined),
                  title: const Text('Fecha y hora'),
                  subtitle: Text(_fechaHora(fecha)),
                  onTap: () async {
                    final seleccionada = await _seleccionarFecha(fecha);
                    if (seleccionada != null) {
                      setModalState(() => fecha = seleccionada);
                    }
                  },
                ),
                TextField(
                  controller: motivo,
                  maxLines: 3,
                  maxLength: 500,
                  decoration: const InputDecoration(
                    labelText: 'Motivo de la consulta',
                    hintText: 'Ej: control general o síntomas',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cerrar'),
            ),
            FilledButton(
              onPressed: () {
                if (motivo.text.trim().length < 5) {
                  ScaffoldMessenger.of(this.context).showSnackBar(
                    const SnackBar(content: Text('Describe el motivo')),
                  );
                  return;
                }
                Navigator.pop(dialogContext, true);
              },
              child: const Text('Solicitar'),
            ),
          ],
        ),
      ),
    );
    if (enviar != true) {
      motivo.dispose();
      return;
    }
    final respuesta = await ApiService.guardarCita(
      accion: 'crear',
      mascotaId: mascotaId,
      fechaHora: fecha,
      motivo: motivo.text,
    );
    motivo.dispose();
    if (!mounted) return;
    _mensaje(respuesta);
    if (respuesta['success'] == true) await _cargar();
  }

  Future<void> _reprogramar(Cita cita) async {
    final fecha = await _seleccionarFecha(
      cita.fechaHora.add(const Duration(days: 1)),
    );
    if (fecha == null) return;
    final respuesta = await ApiService.guardarCita(
      accion: 'reprogramar',
      citaId: cita.id,
      fechaHora: fecha,
    );
    if (!mounted) return;
    _mensaje(respuesta);
    if (respuesta['success'] == true) await _cargar();
  }

  Future<void> _cancelar(Cita cita) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancelar cita'),
        content: Text('¿Deseas cancelar la cita de ${cita.mascota}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Volver'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Cancelar cita'),
          ),
        ],
      ),
    );
    if (confirmar != true) return;
    final respuesta = await ApiService.cancelarCita(cita.id);
    if (!mounted) return;
    _mensaje(respuesta);
    if (respuesta['success'] == true) await _cargar();
  }

  void _mensaje(Map<String, dynamic> respuesta) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(respuesta['message']?.toString() ?? 'Listo')),
    );
  }

  static String _fechaHora(DateTime fecha) {
    String dos(int value) => value.toString().padLeft(2, '0');
    return '${dos(fecha.day)}/${dos(fecha.month)}/${fecha.year} · ${dos(fecha.hour)}:${dos(fecha.minute)}';
  }

  String _estado(String estado) => switch (estado) {
    'solicitada' => 'Solicitada',
    'confirmada' => 'Confirmada',
    'en_espera' => 'En espera',
    'atendida' => 'Atendida',
    'cancelada' => 'Cancelada',
    'no_asistio' => 'No asistió',
    _ => estado,
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(title: const Text('Mis citas')),
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('agendarCitaButton'),
        onPressed: widget.mascotas.isEmpty ? null : _agendar,
        icon: const Icon(Icons.add),
        label: const Text('Agendar'),
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(child: Text(_error!))
          : RefreshIndicator(
              onRefresh: _cargar,
              child: _citas.isEmpty
                  ? ListView(
                      children: const [
                        SizedBox(height: 180),
                        Icon(Icons.event_available, size: 58),
                        Center(child: Text('No tienes citas registradas')),
                      ],
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                      itemCount: _citas.length,
                      itemBuilder: (context, index) {
                        final cita = _citas[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.pets),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        cita.mascota,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 17,
                                        ),
                                      ),
                                    ),
                                    Chip(label: Text(_estado(cita.estado))),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(_fechaHora(cita.fechaHora)),
                                Text(cita.motivo),
                                if (cita.veterinario.isNotEmpty)
                                  Text('Veterinario: ${cita.veterinario}'),
                                if (cita.puedeModificar) ...[
                                  const Divider(),
                                  Row(
                                    children: [
                                      TextButton.icon(
                                        onPressed: () => _reprogramar(cita),
                                        icon: const Icon(Icons.edit_calendar),
                                        label: const Text('Reprogramar'),
                                      ),
                                      TextButton.icon(
                                        onPressed: () => _cancelar(cita),
                                        icon: const Icon(Icons.event_busy),
                                        label: const Text('Cancelar'),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}
