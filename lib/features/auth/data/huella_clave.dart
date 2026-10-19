import 'dart:convert';
import 'package:crypto/crypto.dart';

/// Huella de la contraseña para entrar sin conexión: el teléfono nunca guarda
/// la contraseña, solo esta huella (SHA-256 repetido, con el correo como sal).
String huellaClave(String email, String password) {
  List<int> bytes = utf8.encode('agrocontrol:${email.trim().toLowerCase()}:$password');
  for (var i = 0; i < 20000; i++) {
    bytes = sha256.convert(bytes).bytes;
  }
  return base64Url.encode(bytes);
}

/// Una huella tiene 44 caracteres base64; lo demás es una contraseña antigua en texto.
bool esHuella(String valor) => valor.length == 44 && RegExp(r'^[A-Za-z0-9_-]{43}=$').hasMatch(valor);
