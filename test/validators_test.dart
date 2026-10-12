import 'package:flutter_test/flutter_test.dart';
import 'package:agrocontrol/core/utils/validators.dart';

void main() {
  group('AppValidators.email', () {
    test('rejects null and empty', () {
      expect(AppValidators.email(null), 'El correo es requerido');
      expect(AppValidators.email(''), 'El correo es requerido');
      expect(AppValidators.email('   '), 'El correo es requerido');
    });

    test('rejects invalid emails', () {
      expect(AppValidators.email('invalido'), 'Correo inválido');
      expect(AppValidators.email('a@b'), 'Correo inválido');
      expect(AppValidators.email('@dominio.com'), 'Correo inválido');
      expect(AppValidators.email('usuario@dominio'), 'Correo inválido');
    });

    test('accepts valid emails and trims whitespace', () {
      expect(AppValidators.email('usuario@dominio.com'), isNull);
      expect(AppValidators.email('mi.correo@sub.dominio.pe'), isNull);
      expect(AppValidators.email('  usuario@dominio.com  '), isNull);
    });
  });

  group('AppValidators.password', () {
    test('rejects null and empty', () {
      expect(AppValidators.password(null), 'La contraseña es requerida');
      expect(AppValidators.password(''), 'La contraseña es requerida');
    });

    test('rejects passwords shorter than 8 characters', () {
      expect(AppValidators.password('abc'), 'Mínimo 8 caracteres');
      expect(AppValidators.password('1234567'), 'Mínimo 8 caracteres');
    });

    test('accepts passwords of 8 or more characters', () {
      expect(AppValidators.password('12345678'), isNull);
      expect(AppValidators.password('una-clave-segura-2026'), isNull);
    });
  });

  group('AppValidators.required', () {
    test('rejects null and empty', () {
      expect(AppValidators.required('Nombre')(''), 'Nombre es requerido');
      expect(AppValidators.required('Nombre')(null), 'Nombre es requerido');
      expect(AppValidators.required('Nombre')('   '), 'Nombre es requerido');
    });

    test('accepts non-empty values', () {
      expect(AppValidators.required('Nombre')('Juan'), isNull);
    });
  });

  group('AppValidators.number', () {
    test('rejects null, empty and non-numeric', () {
      expect(AppValidators.number(null), 'El valor es requerido');
      expect(AppValidators.number(''), 'El valor es requerido');
      expect(AppValidators.number('abc'), 'Debe ser un número');
      expect(AppValidators.number('12a'), 'Debe ser un número');
    });

    test('accepts numeric strings', () {
      expect(AppValidators.number('12'), isNull);
      expect(AppValidators.number('12.5'), isNull);
      expect(AppValidators.number('-3'), isNull);
    });
  });

  group('AppValidators.positiveNumber', () {
    test('rejects null, zero and negatives', () {
      expect(AppValidators.positiveNumber(null), 'El valor es requerido');
      expect(AppValidators.positiveNumber('0'), 'Debe ser mayor a 0');
      expect(AppValidators.positiveNumber('-5'), 'Debe ser mayor a 0');
      expect(AppValidators.positiveNumber('abc'), 'Debe ser un número');
    });

    test('accepts positive numbers', () {
      expect(AppValidators.positiveNumber('1'), isNull);
      expect(AppValidators.positiveNumber('0.5'), isNull);
    });
  });

  group('AppValidators.phone', () {
    test('allows empty phone (optional field)', () {
      expect(AppValidators.phone(null), isNull);
      expect(AppValidators.phone(''), isNull);
      expect(AppValidators.phone('   '), isNull);
    });

    test('rejects phones without 9 digits', () {
      expect(AppValidators.phone('98765432'), 'Debe tener 9 dígitos');
      expect(AppValidators.phone('1234'), 'Debe tener 9 dígitos');
    });

    test('accepts Peruvian 9-digit phones, ignoring separators', () {
      expect(AppValidators.phone('987654321'), isNull);
      expect(AppValidators.phone('987 654 321'), isNull);
    });
  });

  group('AppValidators.minLength', () {
    test('rejects short values', () {
      expect(AppValidators.minLength(5)(''), 'Requerido');
      expect(AppValidators.minLength(5)(null), 'Requerido');
      expect(AppValidators.minLength(5)('abcd'), 'Mínimo 5 caracteres');
    });

    test('accepts values meeting the minimum', () {
      expect(AppValidators.minLength(5)('abcde'), isNull);
    });
  });

  group('AppValidators.compose', () {
    test('returns the first failing validator message', () {
      final composed = AppValidators.compose([
        AppValidators.required('Correo'),
        AppValidators.email,
      ]);
      expect(composed(null), 'Correo es requerido');
      expect(composed('invalido'), 'Correo inválido');
    });

    test('returns null when all validators pass', () {
      final composed = AppValidators.compose([
        AppValidators.required('Correo'),
        AppValidators.email,
      ]);
      expect(composed('usuario@dominio.com'), isNull);
    });
  });
}