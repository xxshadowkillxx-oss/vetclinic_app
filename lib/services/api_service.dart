import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config.dart';
import '../models/mascota.dart';
import '../models/portal_models.dart';
import '../utils/rut.dart';

final dio = Dio(
  BaseOptions(
    baseUrl: baseUrl,
    connectTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(seconds: 30),
    headers: {'Content-Type': 'application/json'},
  ),
);

class ApiService {
  static Future<String?> _rutSesion() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('dueno_rut');
  }

  static Map<String, dynamic> _mapaRespuesta(dynamic data) {
    if (data is Map) return Map<String, dynamic>.from(data);
    return {'success': false, 'message': 'Respuesta inválida del servidor'};
  }

  static Map<String, dynamic> _errorDeConexion(Object error) {
    if (error is DioException &&
        error.type == DioExceptionType.connectionError) {
      return {
        'success': false,
        'message':
            'No se pudo conectar con la API en $baseUrl. '
            'Comprueba que Apache esté iniciado.',
      };
    }
    return {
      'success': false,
      'message': error is DioException && error.response?.statusCode != null
          ? 'El servidor no pudo completar la solicitud '
                '(error ${error.response!.statusCode}). Inténtalo nuevamente.'
          : 'No fue posible completar la solicitud',
    };
  }

  static Future<void> _guardarSesion(Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('dueno_id', int.parse(data['dueno_id'].toString()));
    await prefs.setString('dueno_nombre', data['nombre'].toString());
    await prefs.setString('dueno_rut', data['rut'].toString());
  }

  static Future<Map<String, dynamic>> login(String rut, String password) async {
    try {
      final response = await dio.post(
        '/login.php',
        data: jsonEncode({'rut': normalizeRut(rut), 'password': password}),
      );
      final data = response.data;
      if (data['success'] == true) {
        await _guardarSesion(Map<String, dynamic>.from(data));
      }
      return data;
    } catch (e) {
      return _errorDeConexion(e);
    }
  }

  static Future<Map<String, dynamic>> registrarDueno({
    required String nombre,
    required String rut,
    required String telefono,
    required String email,
    required String password,
  }) async {
    try {
      final response = await dio.post(
        '/registro_dueno.php',
        data: jsonEncode({
          'nombre': nombre.trim(),
          'rut': normalizeRut(rut),
          'telefono': telefono.trim(),
          'email': email.trim(),
          'password': password,
        }),
      );
      final data = Map<String, dynamic>.from(response.data);
      if (data['success'] == true) {
        await _guardarSesion(data);
      }
      return data;
    } catch (e) {
      return _errorDeConexion(e);
    }
  }

  static Future<Map<String, dynamic>> recuperarContrasena(
    String identificador,
  ) async {
    try {
      final response = await dio.post(
        '/recuperar_contrasena.php',
        data: jsonEncode({'identificador': identificador.trim()}),
      );
      if (response.data is Map) {
        return Map<String, dynamic>.from(response.data as Map);
      }
      return {
        'success': false,
        'message': 'El servidor entregó una respuesta no válida',
      };
    } on DioException catch (error) {
      if (error.response?.data is Map) {
        return Map<String, dynamic>.from(error.response!.data as Map);
      }
      return {
        'success': false,
        'message':
            'No se pudo conectar con el servidor. '
            'Revisa tu conexión a internet e inténtalo nuevamente.',
      };
    } catch (_) {
      return {
        'success': false,
        'message': 'No fue posible solicitar la recuperación de contraseña',
      };
    }
  }

  static Future<List<Mascota>> getMisMascotas() async {
    final prefs = await SharedPreferences.getInstance();
    final rut = prefs.getString('dueno_rut');
    if (rut == null) return [];
    final response = await dio.get(
      '/mis_mascotas.php',
      queryParameters: {'rut': rut},
    );
    final data = response.data;
    if (data['success'] == true) {
      return (data['mascotas'] as List)
          .map((m) => Mascota.fromJson(m))
          .toList();
    }
    return [];
  }

  static Future<Mascota?> getDetalleMascota(int id) async {
    final prefs = await SharedPreferences.getInstance();
    final rut = prefs.getString('dueno_rut');
    if (rut == null) return null;
    final response = await dio.get(
      '/detalle_mascota.php',
      queryParameters: {'id': id, 'rut': normalizeRut(rut)},
    );
    final data = response.data;
    if (data['success'] == true) {
      return Mascota.fromJson(data['mascota']);
    }
    return null;
  }

  static Uri getDocumentoUrl(String token) {
    final apiUri = Uri.parse(baseUrl);
    return apiUri.replace(
      path: '${apiUri.path}/ver_documento.php'.replaceAll('//', '/'),
      queryParameters: {'token': token},
    );
  }

  static Uri resolveMediaUrl(String ruta) {
    final uri = Uri.tryParse(ruta);
    if (uri != null && uri.hasScheme) return uri;
    final apiUri = Uri.parse(baseUrl);
    final publicPath = apiUri.path.replaceFirst(RegExp(r'/api/?$'), '');
    return apiUri.replace(
      path: '$publicPath/${ruta.replaceFirst(RegExp(r'^/+'), '')}',
      queryParameters: null,
    );
  }

  static Future<List<Cita>> getCitas() async {
    final rut = await _rutSesion();
    if (rut == null) return [];
    final response = await dio.get('/citas.php', queryParameters: {'rut': rut});
    final data = _mapaRespuesta(response.data);
    return (data['citas'] as List<dynamic>? ?? [])
        .map((item) => Cita.fromJson(Map<String, dynamic>.from(item as Map)))
        .toList();
  }

  static Future<Map<String, dynamic>> guardarCita({
    required String accion,
    required DateTime fechaHora,
    int? mascotaId,
    int? citaId,
    String motivo = '',
  }) async {
    final rut = await _rutSesion();
    if (rut == null) return {'success': false, 'message': 'Sesión vencida'};
    try {
      final payload = <String, dynamic>{
        'rut': rut,
        'accion': accion,
        'fecha_hora': fechaHora.toIso8601String(),
        if (motivo.isNotEmpty) 'motivo': motivo.trim(),
      };
      if (mascotaId case final id?) payload['mascota_id'] = id;
      if (citaId case final id?) payload['id'] = id;
      final response = await dio.post('/citas.php', data: jsonEncode(payload));
      return _mapaRespuesta(response.data);
    } on DioException catch (error) {
      return error.response?.data is Map
          ? _mapaRespuesta(error.response?.data)
          : _errorDeConexion(error);
    }
  }

  static Future<Map<String, dynamic>> cancelarCita(int citaId) async {
    final rut = await _rutSesion();
    if (rut == null) return {'success': false, 'message': 'Sesión vencida'};
    try {
      final response = await dio.post(
        '/citas.php',
        data: jsonEncode({'rut': rut, 'accion': 'cancelar', 'id': citaId}),
      );
      return _mapaRespuesta(response.data);
    } on DioException catch (error) {
      return error.response?.data is Map
          ? _mapaRespuesta(error.response?.data)
          : _errorDeConexion(error);
    }
  }

  static Future<List<Recordatorio>> getRecordatorios() async {
    final rut = await _rutSesion();
    if (rut == null) return [];
    final response = await dio.get(
      '/recordatorios.php',
      queryParameters: {'rut': rut},
    );
    final data = _mapaRespuesta(response.data);
    return (data['recordatorios'] as List<dynamic>? ?? [])
        .map(
          (item) =>
              Recordatorio.fromJson(Map<String, dynamic>.from(item as Map)),
        )
        .toList();
  }

  static Future<List<NotificacionDueno>> getNotificaciones() async {
    final rut = await _rutSesion();
    if (rut == null) return [];
    final response = await dio.get(
      '/notificaciones.php',
      queryParameters: {'rut': rut},
    );
    final data = _mapaRespuesta(response.data);
    return (data['notificaciones'] as List<dynamic>? ?? [])
        .map(
          (item) => NotificacionDueno.fromJson(
            Map<String, dynamic>.from(item as Map),
          ),
        )
        .toList();
  }

  static Future<void> marcarNotificacion(int? id) async {
    final rut = await _rutSesion();
    if (rut == null) return;
    final payload = <String, dynamic>{'rut': rut};
    if (id case final notificationId?) payload['id'] = notificationId;
    await dio.post('/notificaciones.php', data: jsonEncode(payload));
  }

  static Future<List<UrgenciaEstado>> getUrgencias() async {
    final rut = await _rutSesion();
    if (rut == null) return [];
    final response = await dio.get(
      '/mis_urgencias.php',
      queryParameters: {'rut': rut},
    );
    final data = _mapaRespuesta(response.data);
    return (data['urgencias'] as List<dynamic>? ?? [])
        .map(
          (item) =>
              UrgenciaEstado.fromJson(Map<String, dynamic>.from(item as Map)),
        )
        .toList();
  }

  static Future<Map<String, dynamic>> getInicio() async {
    final rut = await _rutSesion();
    if (rut == null) return {'success': false};
    final response = await dio.get(
      '/inicio.php',
      queryParameters: {'rut': rut},
    );
    return _mapaRespuesta(response.data);
  }

  static Future<List<PagoPresupuesto>> getPagos() async {
    final rut = await _rutSesion();
    if (rut == null) return [];
    final response = await dio.get('/pagos.php', queryParameters: {'rut': rut});
    final data = _mapaRespuesta(response.data);
    return (data['pagos'] as List<dynamic>? ?? [])
        .map(
          (item) =>
              PagoPresupuesto.fromJson(Map<String, dynamic>.from(item as Map)),
        )
        .toList();
  }

  static Future<Map<String, dynamic>> iniciarPago(int presupuestoId) async {
    final rut = await _rutSesion();
    if (rut == null) return {'success': false, 'message': 'Sesión vencida'};
    try {
      final response = await dio.post(
        '/iniciar_pago.php',
        data: jsonEncode({'rut': rut, 'presupuesto_id': presupuestoId}),
      );
      return _mapaRespuesta(response.data);
    } on DioException catch (error) {
      return error.response?.data is Map
          ? _mapaRespuesta(error.response?.data)
          : _errorDeConexion(error);
    }
  }

  static Future<PerfilDueno?> getPerfil() async {
    final rut = await _rutSesion();
    if (rut == null) return null;
    final response = await dio.get(
      '/perfil.php',
      queryParameters: {'rut': rut},
    );
    final data = _mapaRespuesta(response.data);
    return data['perfil'] is Map
        ? PerfilDueno.fromJson(Map<String, dynamic>.from(data['perfil'] as Map))
        : null;
  }

  static Future<Map<String, dynamic>> actualizarPerfil({
    required String nombre,
    required String telefono,
    required String email,
    String password = '',
  }) async {
    final rut = await _rutSesion();
    if (rut == null) return {'success': false, 'message': 'Sesión vencida'};
    try {
      final response = await dio.post(
        '/perfil.php',
        data: jsonEncode({
          'rut': rut,
          'nombre': nombre.trim(),
          'telefono': telefono.trim(),
          'email': email.trim(),
          if (password.isNotEmpty) 'password': password,
        }),
      );
      final data = _mapaRespuesta(response.data);
      if (data['success'] == true) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('dueno_nombre', nombre.trim());
      }
      return data;
    } on DioException catch (error) {
      return error.response?.data is Map
          ? _mapaRespuesta(error.response?.data)
          : _errorDeConexion(error);
    }
  }

  static Future<Map<String, dynamic>> getCarnet(int mascotaId) async {
    final rut = await _rutSesion();
    if (rut == null) return {'success': false, 'message': 'Sesión vencida'};
    final response = await dio.get(
      '/carnet.php',
      queryParameters: {'rut': rut, 'id': mascotaId},
    );
    return _mapaRespuesta(response.data);
  }

  static Future<Map<String, dynamic>> subirFotoMascota({
    required int mascotaId,
    required Uint8List bytes,
    required String nombreArchivo,
  }) async {
    final rut = await _rutSesion();
    if (rut == null) return {'success': false, 'message': 'Sesión vencida'};
    try {
      final response = await dio.post(
        '/foto_mascota.php',
        data: FormData.fromMap({
          'rut': rut,
          'mascota_id': mascotaId,
          'foto': MultipartFile.fromBytes(bytes, filename: nombreArchivo),
        }),
      );
      return _mapaRespuesta(response.data);
    } on DioException catch (error) {
      return error.response?.data is Map
          ? _mapaRespuesta(error.response?.data)
          : _errorDeConexion(error);
    }
  }

  static Future<Map<String, dynamic>> solicitarUrgencia({
    required int mascotaId,
    required String motivo,
    required String telefono,
    required int minutosLlegada,
    required String formaPago,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final duenoId = prefs.getInt('dueno_id');
    final rut = prefs.getString('dueno_rut');
    if (duenoId == null || rut == null) {
      return {
        'success': false,
        'message': 'Tu sesión venció. Inicia sesión nuevamente.',
      };
    }

    try {
      final response = await dio.post(
        '/solicitar_urgencia.php',
        data: jsonEncode({
          'dueno_id': duenoId,
          'rut': normalizeRut(rut),
          'mascota_id': mascotaId,
          'motivo': motivo.trim(),
          'telefono': telefono.trim(),
          'minutos_llegada': minutosLlegada,
          'forma_pago': formaPago,
        }),
      );
      return Map<String, dynamic>.from(response.data as Map);
    } on DioException catch (error) {
      if (error.response?.data is Map) {
        return Map<String, dynamic>.from(error.response!.data as Map);
      }
      return _errorDeConexion(error);
    } catch (error) {
      return _errorDeConexion(error);
    }
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('dueno_rut') != null;
  }

  static Future<String> getNombre() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('dueno_nombre') ?? 'Dueño';
  }
}

class MyHttpOverrides {}
