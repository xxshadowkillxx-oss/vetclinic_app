import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/portal_models.dart';
import '../services/api_service.dart';

class PagosScreen extends StatefulWidget {
  const PagosScreen({super.key});

  @override
  State<PagosScreen> createState() => _PagosScreenState();
}

class _PagosScreenState extends State<PagosScreen> {
  List<PagoPresupuesto> _pagos = [];
  bool _cargando = true;
  int? _procesando;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    if (mounted) {
      setState(() {
        _cargando = true;
        _error = null;
      });
    }
    try {
      _pagos = await ApiService.getPagos();
    } catch (_) {
      _error = 'No fue posible cargar tus cobros. Revisa la conexión local.';
    }
    if (mounted) setState(() => _cargando = false);
  }

  String _dinero(int valor) {
    final texto = valor.toString();
    final salida = StringBuffer();
    for (var i = 0; i < texto.length; i++) {
      if (i > 0 && (texto.length - i) % 3 == 0) salida.write('.');
      salida.write(texto[i]);
    }
    return '\$${salida.toString()}';
  }

  String _fecha(DateTime? fecha) => fecha == null
      ? 'Sin fecha'
      : '${fecha.day.toString().padLeft(2, '0')}/'
            '${fecha.month.toString().padLeft(2, '0')}/${fecha.year}';

  Future<void> _pagar(PagoPresupuesto pago) async {
    setState(() => _procesando = pago.id);
    final respuesta = await ApiService.iniciarPago(pago.id);
    if (!mounted) return;
    setState(() => _procesando = null);
    if (respuesta['success'] != true) {
      _mensaje(
        respuesta['message']?.toString() ?? 'No se pudo iniciar el pago',
      );
      return;
    }
    if (respuesta['pago_automatico'] == true) {
      _mensaje(
        respuesta['message']?.toString() ??
            'Pago de prueba registrado correctamente',
      );
      await _cargar();
      return;
    }
    final uri = Uri.tryParse(respuesta['checkout_url']?.toString() ?? '');
    if (uri == null ||
        !await launchUrl(uri, mode: LaunchMode.platformDefault)) {
      if (mounted) _mensaje('No se pudo abrir Webpay en el navegador.');
      return;
    }
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Pago abierto en Webpay'),
        content: const Text(
          'Completa el pago en el navegador. Al terminar, vuelve aquí y presiona “Actualizar”.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }

  void _mensaje(String texto) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(texto)));
  }

  @override
  Widget build(BuildContext context) {
    final pendientes = _pagos.where((p) => p.puedePagar).toList();
    final anteriores = _pagos.where((p) => !p.puedePagar).toList();
    return Scaffold(
      backgroundColor: const Color(0xFFF0FDF4),
      appBar: AppBar(
        title: const Text('Pagos'),
        backgroundColor: Colors.white,
        actions: [
          IconButton(
            key: const Key('actualizarPagosButton'),
            tooltip: 'Actualizar',
            onPressed: _cargando ? null : _cargar,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(_error!, textAlign: TextAlign.center),
              ),
            )
          : RefreshIndicator(
              onRefresh: _cargar,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFECFDF5),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFA7F3D0)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.lock_outline, color: Color(0xFF047857)),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Modo de prueba local: al presionar pagar, el cobro se aprobará automáticamente y no se cobrará dinero real.',
                            style: TextStyle(color: Color(0xFF065F46)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),
                  const Text(
                    'Pendientes',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  if (pendientes.isEmpty)
                    const _Vacio(texto: 'No tienes pagos pendientes.')
                  else
                    ...pendientes.map(_tarjeta),
                  if (anteriores.isNotEmpty) ...[
                    const SizedBox(height: 22),
                    const Text(
                      'Historial',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    ...anteriores.map(_tarjeta),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _tarjeta(PagoPresupuesto pago) {
    final pagado = pago.estado == 'pagado';
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    pago.concepto,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                Text(
                  pagado ? 'Pagado' : pago.estado,
                  style: TextStyle(
                    color: pagado
                        ? const Color(0xFF15803D)
                        : const Color(0xFFD97706),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              '${pago.mascota} · Emitido ${_fecha(pago.fechaEmision)}',
              style: const TextStyle(color: Color(0xFF64748B)),
            ),
            if (pago.detalle.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(pago.detalle),
            ],
            const Divider(height: 24),
            Row(
              children: [
                Expanded(
                  child: Text(pagado ? 'Total pagado' : 'Saldo a pagar'),
                ),
                Text(
                  _dinero(pagado ? pago.monto : pago.saldo),
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            if (pago.puedePagar) ...[
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  key: Key('pagarPresupuesto${pago.id}'),
                  onPressed: _procesando == null ? () => _pagar(pago) : null,
                  icon: _procesando == pago.id
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.credit_card),
                  label: const Text('Pagar ahora (prueba)'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Vacio extends StatelessWidget {
  final String texto;
  const _Vacio({required this.texto});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(28),
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
    ),
    child: Text(texto, style: const TextStyle(color: Color(0xFF64748B))),
  );
}
