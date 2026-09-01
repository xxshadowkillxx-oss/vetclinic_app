import 'package:flutter/material.dart';
import '../models/mascota.dart';
import '../services/api_service.dart';
import 'detalle_mascota_screen.dart';
import 'citas_screen.dart';
import 'login_screen.dart';
import 'notificaciones_screen.dart';
import 'perfil_screen.dart';
import 'pagos_screen.dart';
import 'recordatorios_screen.dart';
import 'urgencia_screen.dart';
import 'urgencias_estado_screen.dart';

class MascotasScreen extends StatefulWidget {
  const MascotasScreen({super.key});
  @override
  State<MascotasScreen> createState() => _MascotasScreenState();
}

class _MascotasScreenState extends State<MascotasScreen> {
  List<Mascota> _mascotas = [];
  bool _loading = true;
  String _nombre = '';
  int _noLeidas = 0;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() => _loading = true);
    _nombre = await ApiService.getNombre();
    try {
      final resultados = await Future.wait([
        ApiService.getMisMascotas(),
        ApiService.getInicio(),
      ]);
      _mascotas = resultados[0] as List<Mascota>;
      final inicio = resultados[1] as Map<String, dynamic>;
      _noLeidas =
          int.tryParse(inicio['notificaciones_no_leidas']?.toString() ?? '0') ??
          0;
    } catch (_) {
      _mascotas = [];
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _logout() async {
    await ApiService.logout();
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  IconData _iconoEspecie(String especie) {
    switch (especie.toLowerCase()) {
      case 'perro':
        return Icons.pets;
      case 'gato':
        return Icons.catching_pokemon;
      case 'ave':
        return Icons.flutter_dash;
      default:
        return Icons.pets;
    }
  }

  Color _colorEspecie(String especie) {
    switch (especie.toLowerCase()) {
      case 'perro':
        return const Color(0xFF3B82F6);
      case 'gato':
        return const Color(0xFF8B5CF6);
      case 'ave':
        return const Color(0xFF10B981);
      default:
        return const Color(0xFF64748B);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8F5E9),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.asset(
                      'assets/app_icon_4k.png',
                      width: 44,
                      height: 44,
                      fit: BoxFit.cover,
                      semanticLabel: 'Logo de VetClinic',
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.logout, color: Color(0xFF64748B)),
                    onPressed: _logout,
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '¡Hola, $_nombre!',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1B5E20),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: _acciones(),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton.icon(
                  key: const Key('abrirUrgenciaButton'),
                  onPressed: _loading || _mascotas.isEmpty
                      ? null
                      : () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => UrgenciaScreen(mascotas: _mascotas),
                          ),
                        ),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFDC2626),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  icon: const Icon(Icons.emergency),
                  label: const Text(
                    'Solicitar atención de urgencia',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
            Expanded(
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF2563EB),
                      ),
                    )
                  : _mascotas.isEmpty
                  ? const Center(
                      child: Text(
                        'No tienes mascotas registradas.',
                        style: TextStyle(color: Color(0xFF64748B)),
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _cargar,
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _mascotas.length,
                        itemBuilder: (_, i) => _mascotaCard(_mascotas[i]),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _mascotaCard(Mascota m) {
    final color = _colorEspecie(m.especie);
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => DetalleMascotaScreen(mascotaId: m.id),
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              clipBehavior: Clip.antiAlias,
              child: (m.fotoUrl ?? '').isNotEmpty
                  ? Image.network(
                      ApiService.resolveMediaUrl(m.fotoUrl!).toString(),
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => Icon(
                        _iconoEspecie(m.especie),
                        color: color,
                        size: 26,
                      ),
                    )
                  : Icon(_iconoEspecie(m.especie), color: color, size: 26),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    m.nombre,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${m.especie} · ${m.raza}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF94A3B8),
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${m.peso} kg',
                  style: TextStyle(
                    fontSize: 12,
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                const Icon(
                  Icons.chevron_right,
                  color: Color(0xFFCBD5E1),
                  size: 18,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _acciones() {
    final items = [
      (
        'Citas',
        Icons.calendar_month_outlined,
        const Color(0xFF2563EB),
        () => _abrir(CitasScreen(mascotas: _mascotas)),
      ),
      (
        'Recordatorios',
        Icons.alarm_outlined,
        const Color(0xFFF59E0B),
        () => _abrir(const RecordatoriosScreen()),
      ),
      (
        'Avisos${_noLeidas > 0 ? ' ($_noLeidas)' : ''}',
        Icons.notifications_outlined,
        const Color(0xFF7C3AED),
        () => _abrir(const NotificacionesScreen()),
      ),
      (
        'Urgencias',
        Icons.monitor_heart_outlined,
        const Color(0xFFDC2626),
        () => _abrir(const UrgenciasEstadoScreen()),
      ),
      (
        'Pagos',
        Icons.credit_card_outlined,
        const Color(0xFF059669),
        () => _abrir(const PagosScreen()),
      ),
      (
        'Mi perfil',
        Icons.manage_accounts_outlined,
        const Color(0xFF0F766E),
        () => _abrir(const PerfilScreen()),
      ),
    ];
    return SizedBox(
      height: 88,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final item = items[index];
          return InkWell(
            key: Key('accion${item.$1.split(' ').first}'),
            onTap: _loading ? null : item.$4,
            borderRadius: BorderRadius.circular(14),
            child: Container(
              width: 105,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: item.$3.withValues(alpha: 0.2)),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(item.$2, color: item.$3),
                  const SizedBox(height: 6),
                  Text(
                    item.$1,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _abrir(Widget pantalla) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => pantalla));
    if (mounted) await _cargar();
  }
}
