# VetClinic App

Aplicación Flutter para que los dueños consulten sus mascotas, historial clínico,
vacunas, recetas, citas, recordatorios, urgencias y pagos registrados por la
veterinaria.

## 1. Instalar Flutter en Windows

1. Instala [Git para Windows](https://git-scm.com/download/win).
2. Descarga el SDK estable desde la
   [guía oficial de instalación de Flutter](https://docs.flutter.dev/get-started/install/windows/mobile).
3. Descomprime Flutter, por ejemplo en `C:\Users\TU_USUARIO\flutter`.
4. Agrega `C:\Users\TU_USUARIO\flutter\bin` a la variable `Path` de Windows.
5. Instala Android Studio con Android SDK y crea un emulador.
6. Abre una terminal nueva y comprueba la instalación:

```powershell
flutter doctor
flutter doctor --android-licenses
```

Acepta las licencias y corrige los componentes que `flutter doctor` indique.

## 2. Descargar la aplicación

Este repositorio es privado. La cuenta que descargue el proyecto debe tener
acceso autorizado en GitHub.

```powershell
git clone https://github.com/xxshadowkillxx-oss/vetclinic_app.git
cd vetclinic_app
flutter pub get
```

## 3. Conectar con la API

Por defecto, la aplicación usa la API local de XAMPP:

- Navegador y escritorio: `http://localhost/veterinaria/public/api`
- Emulador Android: `http://10.0.2.2/veterinaria/public/api`

Antes de ejecutarla, inicia **Apache** y **MySQL** desde XAMPP y asegúrate de que
la página veterinaria esté instalada en `htdocs/veterinaria`.

Para utilizar una API remota sin modificar el código:

```powershell
flutter run --dart-define=API_BASE_URL=https://TU_DOMINIO/public/api
```

## 4. Ejecutar la aplicación

Consulta los dispositivos disponibles:

```powershell
flutter devices
```

Ejecutar en Chrome:

```powershell
flutter run -d chrome
```

Ejecutar en un teléfono o emulador Android:

```powershell
flutter run
```

Para usar un teléfono físico, activa **Opciones de desarrollador** y
**Depuración USB**, y luego conéctalo al computador.

## 5. Crear el APK para instalar

```powershell
flutter clean
flutter pub get
flutter build apk --release
```

El APK se genera en:

```text
build\app\outputs\flutter-apk\app-release.apk
```

Copia ese archivo al teléfono Android y ábrelo para instalarlo. Android puede
solicitar permiso para instalar aplicaciones desde esa fuente.

## Verificación del proyecto

```powershell
flutter analyze
flutter test
```
