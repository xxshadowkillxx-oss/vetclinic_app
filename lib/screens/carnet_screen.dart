import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/mascota.dart';
import '../services/api_service.dart';

class CarnetScreen extends StatefulWidget {
  final Mascota mascota;

  const CarnetScreen({super.key, required this.mascota});

  @override
  State<CarnetScreen> createState() => _CarnetScreenState();
}

class _CarnetScreenState extends State<CarnetScreen> {
  late final Future<Map<String, dynamic>> _future = ApiService.getCarnet(
    widget.mascota.id,
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8F5E9),
      appBar: AppBar(title: const Text('Carnet digital')),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final data = snapshot.data ?? {};
          final url = data['url']?.toString() ?? '';
          if (data['success'] != true || url.isEmpty) {
            return const Center(
              child: Text('No fue posible generar el carnet'),
            );
          }
          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: const [
                    BoxShadow(color: Colors.black12, blurRadius: 20),
                  ],
                ),
                child: Column(
                  children: [
                    const Text(
                      'CARNET VETERINARIO DIGITAL',
                      style: TextStyle(
                        color: Color(0xFF166534),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      widget.mascota.nombre,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${widget.mascota.identificador} · ${widget.mascota.especie}',
                    ),
                    const SizedBox(height: 24),
                    QrImageView(
                      data: url,
                      version: QrVersions.auto,
                      size: 220,
                      semanticsLabel: 'Código QR del carnet de la mascota',
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Escanea el código para abrir el carnet y sus vacunas.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    FilledButton.icon(
                      onPressed: () => launchUrl(
                        Uri.parse(url),
                        mode: LaunchMode.externalApplication,
                      ),
                      icon: const Icon(Icons.open_in_browser),
                      label: const Text('Abrir carnet'),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
