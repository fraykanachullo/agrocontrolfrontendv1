import 'package:agrocontrol/features/auth/data/huella_clave.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('la huella no guarda la contraseña y no distingue mayúsculas del correo', () {
    final h = huellaClave('Agricultor@Test.com ', 'secreta123');
    expect(h, isNot(contains('secreta123')));
    expect(h, huellaClave('agricultor@test.com', 'secreta123'));
    expect(h, isNot(huellaClave('agricultor@test.com', 'Secreta123')));
    expect(h, isNot(huellaClave('otro@test.com', 'secreta123')));
  });

  test('distingue una huella de una contraseña antigua en texto', () {
    expect(esHuella(huellaClave('a@b.com', 'x')), isTrue);
    expect(esHuella('password123'), isFalse);
  });
}
