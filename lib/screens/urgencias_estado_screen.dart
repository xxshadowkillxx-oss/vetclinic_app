import 'package:flutter/material.dart';

import '../models/portal_models.dart';
import '../services/api_service.dart';

class UrgenciasEstadoScreen extends StatefulWidget {
  const UrgenciasEstadoScreen({super.key});

  @override
  State<UrgenciasEstadoScreen> createState() => _UrgenciasEstadoScreenState();
}

class _UrgenciasEstadoScreenState extends State<UrgenciasEstadoScreen> {
  late Future<List<UrgenciaEstado>> _future = ApiService.getUrgencias();

  Future<void> _recargar() async {
    setState(() => _future = ApiService.getUrgencias());
    await _future;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(title: const Text('Estado de urgencias')),
      body: FutureBuilder<List<UrgenciaEstado>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final items = snapshot.data ?? [];
          return RefreshIndicator(
            onRefresh: _recargar,
            child: items.isEmpty
                ? ListView(
                    children: const [
                      SizedBox(height: 180),
                      Icon(Icons.health_and_safety_outlined, size: 58),
                      Center(child: Text('No hay urgencias registradas')),
                    ],
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final item = items[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(
                                    Icons.emergency,
                                    color: Colors.red,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      item.mascota,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 17,
                                      ),
                                    ),
                                  ),
                                  Chip(label: Text(item.etiquetaEstado)),
                                ],
                              ),
                              Text(item.motivo),
                              const SizedBox(height: 14),
                              Row(
                                children: List.generate(4, (paso) {
                                  final activo = paso <= item.paso;
                                  return Expanded(
                                    child: Column(
                                      children: [
                                        Container(
                                          height: 6,
                                          margin: const EdgeInsets.symmetric(
                                            horizontal: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: activo
                                                ? const Color(0xFF16A34A)
                                                : const Color(0xFFE2E8F0),
                                            borderRadius: BorderRadius.circular(
                                              4,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 5),
                                        Text(
                                          const [
                                            'Recibida',
                                            'Confirmada',
                                            'En atención',
                                            'Finalizada',
                                          ][paso],
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(fontSize: 9),
                                        ),
                                      ],
                                    ),
                                  );
                                }),
                              ),
                              if (item.observacion.isNotEmpty) ...[
                                const Divider(),
                                Text(item.observacion),
                              ],
                            ],
                          ),
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
