import 'package:flutter/material.dart';

import '../models/portal_models.dart';
import '../services/api_service.dart';

class NotificacionesScreen extends StatefulWidget {
  const NotificacionesScreen({super.key});

  @override
  State<NotificacionesScreen> createState() => _NotificacionesScreenState();
}

class _NotificacionesScreenState extends State<NotificacionesScreen> {
  List<NotificacionDueno> _items = [];
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() => _cargando = true);
    _items = await ApiService.getNotificaciones();
    if (mounted) setState(() => _cargando = false);
  }

  Future<void> _leer(NotificacionDueno item) async {
    if (!item.leida) await ApiService.marcarNotificacion(item.id);
    await _cargar();
  }

  IconData _icono(String tipo) => switch (tipo) {
    'vacuna' => Icons.vaccines,
    'consulta' => Icons.medical_information,
    'documento' => Icons.description,
    'receta' => Icons.medication,
    'cita' => Icons.event,
    _ => Icons.notifications,
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Notificaciones'),
        actions: [
          TextButton(
            onPressed: _items.any((item) => !item.leida)
                ? () async {
                    await ApiService.marcarNotificacion(null);
                    await _cargar();
                  }
                : null,
            child: const Text('Leer todas'),
          ),
        ],
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _cargar,
              child: _items.isEmpty
                  ? ListView(
                      children: const [
                        SizedBox(height: 180),
                        Icon(Icons.notifications_none, size: 58),
                        Center(child: Text('No tienes notificaciones')),
                      ],
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _items.length,
                      itemBuilder: (context, index) {
                        final item = _items[index];
                        return Card(
                          color: item.leida
                              ? Colors.white
                              : const Color(0xFFEFF6FF),
                          child: ListTile(
                            onTap: () => _leer(item),
                            leading: Icon(
                              _icono(item.tipo),
                              color: const Color(0xFF2563EB),
                            ),
                            title: Text(
                              item.titulo,
                              style: TextStyle(
                                fontWeight: item.leida
                                    ? FontWeight.w500
                                    : FontWeight.bold,
                              ),
                            ),
                            subtitle: Text(item.mensaje),
                            trailing: item.leida
                                ? null
                                : const Icon(Icons.circle, size: 10),
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}
