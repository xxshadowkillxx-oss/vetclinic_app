import 'package:flutter/material.dart';

import '../models/portal_models.dart';
import '../services/api_service.dart';

class RecordatoriosScreen extends StatefulWidget {
  const RecordatoriosScreen({super.key});

  @override
  State<RecordatoriosScreen> createState() => _RecordatoriosScreenState();
}

class _RecordatoriosScreenState extends State<RecordatoriosScreen> {
  late Future<List<Recordatorio>> _future = ApiService.getRecordatorios();

  Future<void> _recargar() async {
    setState(() => _future = ApiService.getRecordatorios());
    await _future;
  }

  IconData _icono(String tipo) => switch (tipo) {
    'vacuna' => Icons.vaccines_outlined,
    'medicamento' => Icons.medication_outlined,
    _ => Icons.event_available_outlined,
  };

  Color _color(String tipo) => switch (tipo) {
    'vacuna' => const Color(0xFF16A34A),
    'medicamento' => const Color(0xFF7C3AED),
    _ => const Color(0xFF2563EB),
  };

  String _fecha(DateTime? value) {
    if (value == null) return 'Sin fecha';
    return '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(title: const Text('Recordatorios')),
      body: FutureBuilder<List<Recordatorio>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(
              child: Text('No fue posible cargar recordatorios'),
            );
          }
          final items = snapshot.data ?? [];
          return RefreshIndicator(
            onRefresh: _recargar,
            child: items.isEmpty
                ? ListView(
                    children: const [
                      SizedBox(height: 180),
                      Icon(Icons.notifications_none, size: 58),
                      Center(child: Text('No hay recordatorios pendientes')),
                    ],
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final item = items[index];
                      final color = _color(item.tipo);
                      return Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: color.withValues(alpha: 0.12),
                            child: Icon(_icono(item.tipo), color: color),
                          ),
                          title: Text(item.titulo),
                          subtitle: Text(
                            '${item.mascota} · ${item.detalle}\n${_fecha(item.fecha)}',
                          ),
                          isThreeLine: true,
                        ),
                      );
                    },
                  ),
          );
        },
      ),
    );
  }
}
