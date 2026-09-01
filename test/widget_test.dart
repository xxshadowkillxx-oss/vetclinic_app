import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vetclinic_app/main.dart';
import 'package:vetclinic_app/models/portal_models.dart';
import 'package:vetclinic_app/utils/rut.dart';
import 'package:vetclinic_app/models/mascota.dart';
import 'package:vetclinic_app/screens/citas_screen.dart';
import 'package:vetclinic_app/screens/urgencia_screen.dart';
import 'package:vetclinic_app/screens/pagos_screen.dart';
import 'package:flutter/material.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('normaliza y valida RUT chileno', () {
    expect(normalizeRut('12.345.678-5'), '12345678-5');
    expect(isValidRut('12.345.678-5'), isTrue);
    expect(isValidRut('12.345.678-9'), isTrue);
    expect(isValidRut('123-4'), isFalse);
  });

  test('formatea automáticamente puntos y guion del RUT', () {
    expect(formatRut('123456785'), '12.345.678-5');
    expect(formatRut('12.345.678-k'), '12.345.678-K');
  });

  testWidgets('el inicio de sesión solicita RUT', (tester) async {
    await tester.pumpWidget(const VetClinicApp(loggedIn: false));

    expect(find.text('RUT (ej: 12.345.678-5)'), findsOneWidget);
    expect(find.text('Iniciar Sesión'), findsOneWidget);
  });

  testWidgets('el dueño puede abrir el formulario de registro', (tester) async {
    await tester.pumpWidget(const VetClinicApp(loggedIn: false));

    await tester.tap(find.text('¿No tienes cuenta? Regístrate'));
    await tester.pumpAndSettle();

    expect(find.text('Registro del dueño'), findsOneWidget);
    expect(find.text('Nombre completo'), findsOneWidget);
    expect(find.text('RUT (ej: 12.345.678-5)'), findsOneWidget);
    expect(find.text('+569'), findsOneWidget);
    expect(find.text('1234 5678'), findsOneWidget);
    expect(find.text('Registrarme'), findsOneWidget);
  });

  testWidgets('el dueño puede abrir la recuperación de contraseña', (
    tester,
  ) async {
    await tester.pumpWidget(const VetClinicApp(loggedIn: false));

    await tester.tap(find.text('¿Olvidaste tu contraseña?'));
    await tester.pumpAndSettle();

    expect(find.text('Recuperar contraseña'), findsOneWidget);
    expect(find.text('RUT o correo electrónico'), findsOneWidget);
    expect(find.text('Enviar enlace'), findsOneWidget);
  });

  testWidgets('la recuperación requiere RUT o correo', (tester) async {
    await tester.pumpWidget(const VetClinicApp(loggedIn: false));
    await tester.tap(find.text('¿Olvidaste tu contraseña?'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Enviar enlace'));
    await tester.pump();

    expect(find.text('Ingresa tu RUT o correo electrónico'), findsOneWidget);
  });

  testWidgets('la urgencia solicita mascota, motivo, llegada y forma de pago', (
    tester,
  ) async {
    final mascota = Mascota(
      id: 1,
      identificador: 'M-1',
      nombre: 'Luna',
      especie: 'Perro',
      raza: 'Mestiza',
      peso: 12,
      dueno: 'María',
      telefono: '+56912345678',
    );

    await tester.pumpWidget(
      MaterialApp(home: UrgenciaScreen(mascotas: [mascota])),
    );

    expect(find.text('Atención de urgencia'), findsOneWidget);
    expect(find.text('Luna · Perro'), findsOneWidget);
    expect(find.text('Forma de pago al llegar'), findsOneWidget);
    expect(
      find.byKey(const Key('enviarUrgenciaButton'), skipOffstage: false),
      findsOneWidget,
    );
  });

  test('convierte documentos clínicos recibidos desde la API', () {
    final documento = DocumentoClinico.fromJson({
      'id': 4,
      'tipo': 'receta',
      'titulo': 'Receta de antibiótico',
      'nombre_original': 'receta.pdf',
      'mime_type': 'application/pdf',
      'tamano': 2048,
      'token_descarga': List.filled(64, 'a').join(),
      'fecha_subida': '2026-08-31 10:30:00',
      'subido_por': 'Dra. Veterinaria',
    });

    expect(documento.tipo, 'receta');
    expect(documento.titulo, 'Receta de antibiótico');
    expect(documento.tamano, 2048);
    expect(documento.tokenDescarga.length, 64);
  });

  test('organiza recetas y estados de urgencia recibidos desde la API', () {
    final mascota = Mascota.fromJson({
      'id': 1,
      'identificador': 'M-001',
      'nombre': 'Luna',
      'especie': 'Perro',
      'raza': 'Mestiza',
      'peso': '12.5',
      'dueno': 'María',
      'telefono': '+56912345678',
      'foto_url': 'uploads/mascotas/luna.jpg',
      'recetas': [
        {
          'id': 3,
          'medicamento': 'Amoxicilina',
          'dosis': '1 comprimido',
          'frecuencia': 'Cada 12 horas',
          'duracion': '7 días',
        },
      ],
    });
    final urgencia = UrgenciaEstado.fromJson({
      'id': 8,
      'mascota': 'Luna',
      'motivo': 'Accidente',
      'estado': 'en_atencion',
    });

    expect(mascota.fotoUrl, contains('luna.jpg'));
    expect(mascota.recetas.single.medicamento, 'Amoxicilina');
    expect(urgencia.etiquetaEstado, 'En atención');
    expect(urgencia.paso, 2);
  });

  testWidgets('la agenda permite iniciar una nueva solicitud', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: CitasScreen(mascotas: [])));
    await tester.pumpAndSettle();

    expect(find.text('Mis citas'), findsOneWidget);
    expect(find.text('Agendar'), findsOneWidget);
    expect(find.text('No tienes citas registradas'), findsOneWidget);
  });

  test('interpreta un presupuesto pendiente como pago disponible', () {
    final pago = PagoPresupuesto.fromJson({
      'id': 12,
      'mascota_id': 3,
      'mascota': 'Luna',
      'concepto': 'Consulta general',
      'monto': '25000.00',
      'abonado': '5000.00',
      'saldo': '20000.00',
      'estado': 'pendiente',
      'fecha_emision': '2026-08-31',
    });

    expect(pago.saldo, 20000);
    expect(pago.puedePagar, isTrue);
  });

  testWidgets('la sección de pagos informa cuando no hay cobros pendientes', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: PagosScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Pagos'), findsOneWidget);
    expect(find.text('Pendientes'), findsOneWidget);
    expect(find.text('No tienes pagos pendientes.'), findsOneWidget);
    expect(find.textContaining('Modo de prueba local'), findsOneWidget);
  });
}
