class Cita {
  final int id;
  final int mascotaId;
  final String mascota;
  final DateTime fechaHora;
  final String motivo;
  final String estado;
  final String veterinario;
  final String observacion;

  const Cita({
    required this.id,
    required this.mascotaId,
    required this.mascota,
    required this.fechaHora,
    required this.motivo,
    required this.estado,
    required this.veterinario,
    required this.observacion,
  });

  bool get puedeModificar => estado == 'solicitada' || estado == 'confirmada';

  factory Cita.fromJson(Map<String, dynamic> json) => Cita(
    id: int.tryParse(json['id'].toString()) ?? 0,
    mascotaId: int.tryParse(json['mascota_id'].toString()) ?? 0,
    mascota: json['mascota']?.toString() ?? '',
    fechaHora:
        DateTime.tryParse(json['fecha_hora']?.toString() ?? '') ??
        DateTime.now(),
    motivo: json['motivo']?.toString() ?? '',
    estado: json['estado']?.toString() ?? 'solicitada',
    veterinario: json['veterinario']?.toString() ?? '',
    observacion: json['observacion']?.toString() ?? '',
  );
}

class Recordatorio {
  final int id;
  final String tipo;
  final String mascota;
  final String titulo;
  final String detalle;
  final DateTime? fecha;

  const Recordatorio({
    required this.id,
    required this.tipo,
    required this.mascota,
    required this.titulo,
    required this.detalle,
    required this.fecha,
  });

  factory Recordatorio.fromJson(Map<String, dynamic> json) => Recordatorio(
    id: int.tryParse(json['id'].toString()) ?? 0,
    tipo: json['tipo']?.toString() ?? 'control',
    mascota: json['mascota']?.toString() ?? '',
    titulo: json['titulo']?.toString() ?? '',
    detalle: json['detalle']?.toString() ?? '',
    fecha: DateTime.tryParse(json['fecha']?.toString() ?? ''),
  );
}

class NotificacionDueno {
  final int id;
  final String titulo;
  final String mensaje;
  final String tipo;
  final bool leida;
  final DateTime? fecha;

  const NotificacionDueno({
    required this.id,
    required this.titulo,
    required this.mensaje,
    required this.tipo,
    required this.leida,
    required this.fecha,
  });

  factory NotificacionDueno.fromJson(Map<String, dynamic> json) =>
      NotificacionDueno(
        id: int.tryParse(json['id'].toString()) ?? 0,
        titulo: json['titulo']?.toString() ?? '',
        mensaje: json['mensaje']?.toString() ?? '',
        tipo: json['tipo']?.toString() ?? 'info',
        leida: json['leida'] == true || json['leida'].toString() == '1',
        fecha: DateTime.tryParse(json['fecha_creacion']?.toString() ?? ''),
      );
}

class UrgenciaEstado {
  final int id;
  final String mascota;
  final String motivo;
  final String estado;
  final String observacion;
  final DateTime? fecha;

  const UrgenciaEstado({
    required this.id,
    required this.mascota,
    required this.motivo,
    required this.estado,
    required this.observacion,
    required this.fecha,
  });

  String get etiquetaEstado => switch (estado) {
    'pendiente' || 'recibida' => 'Recibida',
    'confirmada' => 'Confirmada',
    'en_atencion' => 'En atención',
    'atendida' || 'finalizada' => 'Finalizada',
    'rechazada' => 'Rechazada',
    'cancelada' => 'Cancelada',
    _ => estado,
  };

  int get paso => switch (estado) {
    'pendiente' || 'recibida' => 0,
    'confirmada' => 1,
    'en_atencion' => 2,
    'atendida' || 'finalizada' => 3,
    _ => 0,
  };

  factory UrgenciaEstado.fromJson(Map<String, dynamic> json) => UrgenciaEstado(
    id: int.tryParse(json['id'].toString()) ?? 0,
    mascota: json['mascota']?.toString() ?? '',
    motivo: json['motivo']?.toString() ?? '',
    estado: json['estado']?.toString() ?? 'recibida',
    observacion: json['observacion_recepcion']?.toString() ?? '',
    fecha: DateTime.tryParse(json['fecha_solicitud']?.toString() ?? ''),
  );
}

class PerfilDueno {
  final String rut;
  final String nombre;
  final String telefono;
  final String email;

  const PerfilDueno({
    required this.rut,
    required this.nombre,
    required this.telefono,
    required this.email,
  });

  factory PerfilDueno.fromJson(Map<String, dynamic> json) => PerfilDueno(
    rut: json['rut']?.toString() ?? '',
    nombre: json['nombre']?.toString() ?? '',
    telefono: json['telefono']?.toString() ?? '',
    email: json['email']?.toString() ?? '',
  );
}

class PagoPresupuesto {
  final int id;
  final int mascotaId;
  final String mascota;
  final String concepto;
  final String detalle;
  final int monto;
  final int abonado;
  final int saldo;
  final String estado;
  final DateTime? fechaEmision;
  final DateTime? fechaVencimiento;

  const PagoPresupuesto({
    required this.id,
    required this.mascotaId,
    required this.mascota,
    required this.concepto,
    required this.detalle,
    required this.monto,
    required this.abonado,
    required this.saldo,
    required this.estado,
    required this.fechaEmision,
    required this.fechaVencimiento,
  });

  bool get puedePagar =>
      saldo > 0 && (estado == 'pendiente' || estado == 'aceptado');

  factory PagoPresupuesto.fromJson(Map<String, dynamic> json) {
    int numero(dynamic value) =>
        double.tryParse(value?.toString() ?? '')?.round() ?? 0;
    return PagoPresupuesto(
      id: numero(json['id']),
      mascotaId: numero(json['mascota_id']),
      mascota: json['mascota']?.toString() ?? '',
      concepto: json['concepto']?.toString() ?? '',
      detalle: json['detalle']?.toString() ?? '',
      monto: numero(json['monto']),
      abonado: numero(json['abonado']),
      saldo: numero(json['saldo']),
      estado: json['estado']?.toString() ?? 'pendiente',
      fechaEmision: DateTime.tryParse(json['fecha_emision']?.toString() ?? ''),
      fechaVencimiento: DateTime.tryParse(
        json['fecha_vencimiento']?.toString() ?? '',
      ),
    );
  }
}
