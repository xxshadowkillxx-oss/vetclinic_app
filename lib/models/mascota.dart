class Mascota {
  final int id;
  final String identificador;
  final String nombre;
  final String especie;
  final String raza;
  final double peso;
  final String? fechaNacimiento;
  final String? fotoUrl;
  final String dueno;
  final String telefono;
  final List<Historial> historial;
  final List<Vacuna> vacunas;
  final List<DocumentoClinico> documentos;
  final List<Receta> recetas;

  Mascota({
    required this.id,
    required this.identificador,
    required this.nombre,
    required this.especie,
    required this.raza,
    required this.peso,
    this.fechaNacimiento,
    this.fotoUrl,
    required this.dueno,
    required this.telefono,
    this.historial = const [],
    this.vacunas = const [],
    this.documentos = const [],
    this.recetas = const [],
  });

  factory Mascota.fromJson(Map<String, dynamic> json) {
    return Mascota(
      id: int.parse(json['id'].toString()),
      identificador: json['identificador'] ?? '',
      nombre: json['nombre'] ?? '',
      especie: json['especie'] ?? '',
      raza: json['raza'] ?? '',
      peso: double.parse(json['peso'].toString()),
      fechaNacimiento: json['fecha_nacimiento'],
      fotoUrl: json['foto_url']?.toString(),
      dueno: json['dueno'] ?? '',
      telefono: json['telefono'] ?? '',
      historial: (json['historial'] as List<dynamic>? ?? [])
          .map((h) => Historial.fromJson(h))
          .toList(),
      vacunas: (json['vacunas'] as List<dynamic>? ?? [])
          .map((v) => Vacuna.fromJson(v))
          .toList(),
      documentos: (json['documentos'] as List<dynamic>? ?? [])
          .map((d) => DocumentoClinico.fromJson(d))
          .toList(),
      recetas: (json['recetas'] as List<dynamic>? ?? [])
          .map((r) => Receta.fromJson(r))
          .toList(),
    );
  }
}

class Receta {
  final int id;
  final String diagnostico;
  final String medicamento;
  final String dosis;
  final String frecuencia;
  final String duracion;
  final String indicaciones;
  final String fechaEmision;
  final String veterinario;

  const Receta({
    required this.id,
    required this.diagnostico,
    required this.medicamento,
    required this.dosis,
    required this.frecuencia,
    required this.duracion,
    required this.indicaciones,
    required this.fechaEmision,
    required this.veterinario,
  });

  factory Receta.fromJson(Map<String, dynamic> json) => Receta(
    id: int.tryParse(json['id'].toString()) ?? 0,
    diagnostico: json['diagnostico']?.toString() ?? '',
    medicamento: json['medicamento']?.toString() ?? '',
    dosis: json['dosis']?.toString() ?? '',
    frecuencia: json['frecuencia']?.toString() ?? '',
    duracion: json['duracion']?.toString() ?? '',
    indicaciones: json['indicaciones']?.toString() ?? '',
    fechaEmision: json['fecha_emision']?.toString() ?? '',
    veterinario: json['veterinario']?.toString() ?? 'Veterinario',
  );
}

class DocumentoClinico {
  final int id;
  final String tipo;
  final String titulo;
  final String descripcion;
  final String nombreOriginal;
  final String mimeType;
  final int tamano;
  final String tokenDescarga;
  final String fechaSubida;
  final String subidoPor;

  DocumentoClinico({
    required this.id,
    required this.tipo,
    required this.titulo,
    required this.descripcion,
    required this.nombreOriginal,
    required this.mimeType,
    required this.tamano,
    required this.tokenDescarga,
    required this.fechaSubida,
    required this.subidoPor,
  });

  factory DocumentoClinico.fromJson(Map<String, dynamic> json) {
    return DocumentoClinico(
      id: int.parse(json['id'].toString()),
      tipo: json['tipo']?.toString() ?? 'otro',
      titulo: json['titulo']?.toString() ?? 'Documento clínico',
      descripcion: json['descripcion']?.toString() ?? '',
      nombreOriginal: json['nombre_original']?.toString() ?? '',
      mimeType: json['mime_type']?.toString() ?? 'application/octet-stream',
      tamano: int.tryParse(json['tamano'].toString()) ?? 0,
      tokenDescarga: json['token_descarga']?.toString() ?? '',
      fechaSubida: json['fecha_subida']?.toString() ?? '',
      subidoPor: json['subido_por']?.toString() ?? 'Veterinario',
    );
  }
}

class Historial {
  final int id;
  final String fechaVisita;
  final String diagnostico;
  final String tratamiento;
  final String veterinario;

  Historial({
    required this.id,
    required this.fechaVisita,
    required this.diagnostico,
    required this.tratamiento,
    required this.veterinario,
  });

  factory Historial.fromJson(Map<String, dynamic> json) {
    return Historial(
      id: int.parse(json['id'].toString()),
      fechaVisita: json['fecha_visita'] ?? '',
      diagnostico: json['diagnostico'] ?? '',
      tratamiento: json['tratamiento'] ?? '',
      veterinario: json['veterinario'] ?? '',
    );
  }
}

class Vacuna {
  final int id;
  final String nombreVacuna;
  final String fechaAplicacion;
  final String? fechaProximaDosis;

  Vacuna({
    required this.id,
    required this.nombreVacuna,
    required this.fechaAplicacion,
    this.fechaProximaDosis,
  });

  factory Vacuna.fromJson(Map<String, dynamic> json) {
    return Vacuna(
      id: int.parse(json['id'].toString()),
      nombreVacuna: json['nombre_vacuna'] ?? '',
      fechaAplicacion: json['fecha_aplicacion'] ?? '',
      fechaProximaDosis: json['fecha_proxima_dosis'],
    );
  }
}
