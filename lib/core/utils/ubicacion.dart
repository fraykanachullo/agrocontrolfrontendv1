import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';

/// Resultado de pedir la ubicación: la posición o el motivo, en palabras simples.
typedef UbicacionResultado = ({Position? posicion, String? error});

/// Toma la ubicación actual con el GPS del teléfono. Funciona sin internet.
/// Si el permiso se niega o el GPS está apagado, devuelve el motivo y el
/// registro sigue sin ubicación (RF-01: nunca bloquea).
Future<UbicacionResultado> obtenerUbicacionActual() async {
  if (!await Geolocator.isLocationServiceEnabled()) {
    return (posicion: null, error: 'Activa el GPS del teléfono y vuelve a intentar');
  }
  var permiso = await Geolocator.checkPermission();
  if (permiso == LocationPermission.denied) {
    permiso = await Geolocator.requestPermission();
  }
  if (permiso == LocationPermission.denied) {
    return (posicion: null, error: 'Sin permiso de ubicación');
  }
  if (permiso == LocationPermission.deniedForever) {
    return (posicion: null, error: 'Permiso de ubicación bloqueado: actívalo en Ajustes');
  }
  try {
    final posicion = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, timeLimit: Duration(seconds: 25)),
    );
    return (posicion: posicion, error: null);
  } catch (_) {
    // Sin señal a tiempo: se usa la última posición conocida, si hay.
    final ultima = await Geolocator.getLastKnownPosition();
    return ultima == null
        ? (posicion: null, error: 'No se pudo leer el GPS. Sal a cielo abierto y reintenta')
        : (posicion: ultima, error: null);
  }
}

String formatoCoordenadas(double lat, double lng) => '${lat.toStringAsFixed(5)}, ${lng.toStringAsFixed(5)}';

/// Abre el punto en Google Maps (o en el navegador). Necesita internet.
Future<bool> abrirEnMapa(double lat, double lng) =>
    launchUrl(Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng'), mode: LaunchMode.externalApplication);
