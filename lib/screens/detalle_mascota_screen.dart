import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/mascota.dart';
import '../services/api_service.dart';
import 'carnet_screen.dart';

class DetalleMascotaScreen extends StatefulWidget {
  final int mascotaId;
  const DetalleMascotaScreen({super.key, required this.mascotaId});
  @override
  State<DetalleMascotaScreen> createState() => _DetalleMascotaScreenState();
}

class _DetalleMascotaScreenState extends State<DetalleMascotaScreen> {
  Mascota? _mascota;
  bool _loading = true;
  bool _showInfo = false;
  bool _showSalud = false;
  bool _showVacunas = false;
  bool _showDocumentos = false;
  bool _showRecetas = false;
  bool _subiendoFoto = false;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    final m = await ApiService.getDetalleMascota(widget.mascotaId);
    setState(() {
      _mascota = m;
      _loading = false;
    });
  }

  String _calcularEdad(String? fecha) {
    if (fecha == null || fecha.isEmpty) return 'N/A';
    final nac = DateTime.tryParse(fecha);
    if (nac == null) return 'N/A';
    final hoy = DateTime.now();
    int anios = hoy.year - nac.year;
    if (hoy.month < nac.month ||
        (hoy.month == nac.month && hoy.day < nac.day)) {
      anios--;
    }
    return '$anios ${anios != 1 ? 'años' : 'año'}';
  }

  Future<void> _abrirDocumento(DocumentoClinico documento) async {
    final uri = ApiService.getDocumentoUrl(documento.tokenDescarga);
    final abierto = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!abierto && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No fue posible abrir el documento')),
      );
    }
  }

  Future<void> _cambiarFoto() async {
    final archivo = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 1600,
    );
    if (archivo == null) return;
    setState(() => _subiendoFoto = true);
    final respuesta = await ApiService.subirFotoMascota(
      mascotaId: widget.mascotaId,
      bytes: await archivo.readAsBytes(),
      nombreArchivo: archivo.name,
    );
    if (!mounted) return;
    setState(() => _subiendoFoto = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(respuesta['message']?.toString() ?? 'Listo')),
    );
    if (respuesta['success'] == true) await _cargar();
  }

  String _etiquetaTipoDocumento(String tipo) {
    const etiquetas = {
      'receta': 'Receta médica',
      'examen': 'Examen médico',
      'radiografia': 'Radiografía',
      'informe': 'Informe clínico',
      'otro': 'Otro documento',
    };
    return etiquetas[tipo] ?? 'Documento clínico';
  }

  String _formatearTamano(int bytes) {
    if (bytes >= 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / 1024).toStringAsFixed(0)} KB';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8E1),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFF9A825)),
            )
          : _mascota == null
          ? const Center(child: Text('No se pudo cargar la mascota'))
          : _buildBody(),
    );
  }

  Widget _buildBody() {
    final m = _mascota!;
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          backgroundColor: const Color(0xFFF9A825),
          foregroundColor: Colors.white,
          pinned: true,
          title: Text(
            m.nombre.toUpperCase(),
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
          centerTitle: true,
        ),
        SliverToBoxAdapter(
          child: Column(
            children: [
              const SizedBox(height: 20),
              GestureDetector(
                key: const Key('cambiarFotoMascotaButton'),
                onTap: _subiendoFoto ? null : _cambiarFoto,
                child: Stack(
                  children: [
                    Container(
                      width: 96,
                      height: 96,
                      clipBehavior: Clip.antiAlias,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE0E0E0),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFFF9A825),
                          width: 3,
                        ),
                      ),
                      child: _subiendoFoto
                          ? const Padding(
                              padding: EdgeInsets.all(30),
                              child: CircularProgressIndicator(strokeWidth: 3),
                            )
                          : (m.fotoUrl ?? '').isNotEmpty
                          ? Image.network(
                              ApiService.resolveMediaUrl(m.fotoUrl!).toString(),
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) => const Icon(
                                Icons.pets,
                                size: 44,
                                color: Color(0xFFBDBDBD),
                              ),
                            )
                          : const Icon(
                              Icons.pets,
                              size: 44,
                              color: Color(0xFFBDBDBD),
                            ),
                    ),
                    const Positioned(
                      right: 0,
                      bottom: 0,
                      child: CircleAvatar(
                        radius: 16,
                        backgroundColor: Color(0xFFF9A825),
                        child: Icon(Icons.camera_alt, size: 17),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => CarnetScreen(mascota: m)),
                ),
                icon: const Icon(Icons.qr_code_2),
                label: const Text('Ver carnet digital QR'),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  padding: const EdgeInsets.all(16),
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
                  child: Column(
                    children: [
                      _statRow(
                        'Nombre',
                        m.nombre,
                        'Edad',
                        _calcularEdad(m.fechaNacimiento),
                      ),
                      const SizedBox(height: 10),
                      _statRow('Especie', m.especie, 'Peso', '${m.peso} kg'),
                      const SizedBox(height: 10),
                      _statRow('Raza', m.raza, 'Dueño', m.dueno),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _acordeon(
                titulo: 'Información General',
                subtitulo: 'Datos del paciente',
                icono: Icons.info_outline,
                abierto: _showInfo,
                onTap: () => setState(() => _showInfo = !_showInfo),
                contenido: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _infoItem('Identificador', m.identificador),
                      _infoItem('Especie', m.especie),
                      _infoItem('Raza', m.raza),
                      _infoItem('Peso', '${m.peso} kg'),
                      _infoItem(
                        'Nacimiento',
                        m.fechaNacimiento ?? 'No registrada',
                      ),
                      _infoItem('Teléfono', m.telefono),
                    ],
                  ),
                ),
              ),
              _acordeon(
                titulo: 'Historial Clínico',
                subtitulo:
                    '${m.historial.length} consulta${m.historial.length != 1 ? 's' : ''}',
                icono: Icons.medical_services_outlined,
                abierto: _showSalud,
                onTap: () => setState(() => _showSalud = !_showSalud),
                contenido: m.historial.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: Text(
                          'Sin consultas registradas.',
                          style: TextStyle(
                            color: Color(0xFF94A3B8),
                            fontSize: 13,
                          ),
                        ),
                      )
                    : Column(
                        children: m.historial
                            .map(
                              (h) => Container(
                                margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF8FAFC),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: const Color(0xFFE2E8F0),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          h.fechaVisita,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 13,
                                            color: Color(0xFF1E293B),
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFDBEAFE),
                                            borderRadius: BorderRadius.circular(
                                              20,
                                            ),
                                          ),
                                          child: Text(
                                            h.veterinario,
                                            style: const TextStyle(
                                              fontSize: 11,
                                              color: Color(0xFF1E40AF),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    _historialItem(
                                      'Diagnóstico',
                                      h.diagnostico,
                                      const Color(0xFFEF4444),
                                    ),
                                    const SizedBox(height: 4),
                                    _historialItem(
                                      'Tratamiento',
                                      h.tratamiento,
                                      const Color(0xFF16A34A),
                                    ),
                                  ],
                                ),
                              ),
                            )
                            .toList(),
                      ),
              ),
              _acordeon(
                titulo: 'Vacunas',
                subtitulo:
                    '${m.vacunas.length} vacuna${m.vacunas.length != 1 ? 's' : ''} registrada${m.vacunas.length != 1 ? 's' : ''}',
                icono: Icons.shield_outlined,
                abierto: _showVacunas,
                onTap: () => setState(() => _showVacunas = !_showVacunas),
                contenido: m.vacunas.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: Text(
                          'Sin vacunas registradas.',
                          style: TextStyle(
                            color: Color(0xFF94A3B8),
                            fontSize: 13,
                          ),
                        ),
                      )
                    : Column(
                        children: m.vacunas
                            .map(
                              (v) => Container(
                                margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF0FDF4),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: const Color(0xFFBBF7D0),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.check_circle_outline,
                                      color: Color(0xFF16A34A),
                                      size: 20,
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            v.nombreVacuna,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 13,
                                              color: Color(0xFF1E293B),
                                            ),
                                          ),
                                          Text(
                                            'Aplicada: ${v.fechaAplicacion}',
                                            style: const TextStyle(
                                              fontSize: 11,
                                              color: Color(0xFF64748B),
                                            ),
                                          ),
                                          if (v.fechaProximaDosis != null)
                                            Text(
                                              'Próxima: ${v.fechaProximaDosis}',
                                              style: const TextStyle(
                                                fontSize: 11,
                                                color: Color(0xFFD97706),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                            .toList(),
                      ),
              ),
              _acordeon(
                titulo: 'Recetas y medicamentos',
                subtitulo:
                    '${m.recetas.length} receta${m.recetas.length != 1 ? 's' : ''} activa${m.recetas.length != 1 ? 's' : ''}',
                icono: Icons.medication_outlined,
                abierto: _showRecetas,
                onTap: () => setState(() => _showRecetas = !_showRecetas),
                contenido: m.recetas.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: Text('No hay recetas activas.'),
                      )
                    : Column(children: m.recetas.map(_recetaCard).toList()),
              ),
              _acordeon(
                titulo: 'Documentos clínicos',
                subtitulo:
                    '${m.documentos.length} documento${m.documentos.length != 1 ? 's' : ''}',
                icono: Icons.folder_shared_outlined,
                abierto: _showDocumentos,
                onTap: () => setState(() => _showDocumentos = !_showDocumentos),
                contenido: m.documentos.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: Text(
                          'El veterinario todavía no ha compartido documentos.',
                          style: TextStyle(
                            color: Color(0xFF94A3B8),
                            fontSize: 13,
                          ),
                        ),
                      )
                    : Column(
                        children: m.documentos
                            .map((documento) => _documentoCard(documento))
                            .toList(),
                      ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ],
    );
  }

  Widget _statRow(String k1, String v1, String k2, String v2) {
    return Row(
      children: [
        Expanded(child: _statItem(k1, v1)),
        const SizedBox(width: 12),
        Expanded(child: _statItem(k2, v2)),
      ],
    );
  }

  Widget _statItem(String key, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          key,
          style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1E293B),
          ),
        ),
      ],
    );
  }

  Widget _infoItem(String key, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(
              key,
              style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Color(0xFF1E293B),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _historialItem(String label, String value, Color color) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: 12,
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 12, color: Color(0xFF475569)),
          ),
        ),
      ],
    );
  }

  Widget _documentoCard(DocumentoClinico documento) {
    final esPdf = documento.mimeType == 'application/pdf';
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: ListTile(
        onTap: () => _abrirDocumento(documento),
        leading: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: esPdf ? const Color(0xFFFEE2E2) : const Color(0xFFE0F2FE),
            borderRadius: BorderRadius.circular(9),
          ),
          child: Icon(
            esPdf ? Icons.picture_as_pdf_outlined : Icons.image_outlined,
            color: esPdf ? const Color(0xFFDC2626) : const Color(0xFF0284C7),
          ),
        ),
        title: Text(
          documento.titulo,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          '${_etiquetaTipoDocumento(documento.tipo)} · ${_formatearTamano(documento.tamano)}\n${documento.fechaSubida}',
          style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
        ),
        isThreeLine: true,
        trailing: const Icon(Icons.open_in_new, size: 18),
      ),
    );
  }

  Widget _recetaCard(Receta receta) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F3FF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFDDD6FE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            receta.medicamento,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFF6D28D9),
            ),
          ),
          const SizedBox(height: 6),
          _infoItem('Dosis', receta.dosis),
          _infoItem('Frecuencia', receta.frecuencia),
          _infoItem('Duración', receta.duracion),
          if (receta.indicaciones.isNotEmpty)
            _infoItem('Indicaciones', receta.indicaciones),
          Text(
            '${receta.fechaEmision} · ${receta.veterinario}',
            style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
          ),
        ],
      ),
    );
  }

  Widget _acordeon({
    required String titulo,
    required String subtitulo,
    required IconData icono,
    required bool abierto,
    required VoidCallback onTap,
    required Widget contenido,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Container(
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
        child: Column(
          children: [
            GestureDetector(
              onTap: onTap,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF8E1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        icono,
                        color: const Color(0xFFF9A825),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            titulo,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                          Text(
                            subtitulo,
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF94A3B8),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      abierto
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down,
                      color: const Color(0xFF94A3B8),
                    ),
                  ],
                ),
              ),
            ),
            if (abierto) ...[
              const Divider(height: 1, color: Color(0xFFF1F5F9)),
              contenido,
              const SizedBox(height: 12),
            ],
          ],
        ),
      ),
    );
  }
}
