class AppValidators {
  AppValidators._();

  // ── Email ──
  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'El correo es requerido';
    }
    final regex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!regex.hasMatch(value.trim())) {
      return 'Correo inválido';
    }
    return null;
  }

  // ── Password ──
  static String? password(String? value) {
    if (value == null || value.isEmpty) {
      return 'La contraseña es requerida';
    }
    if (value.length < 8) {
      return 'Mínimo 8 caracteres';
    }
    return null;
  }

  // ── Required ──
  static String? Function(String?) required(String fieldName) {
    return (String? value) {
      if (value == null || value.trim().isEmpty) {
        return '$fieldName es requerido';
      }
      return null;
    };
  }

  // ── Number ──
  static String? number(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'El valor es requerido';
    }
    if (double.tryParse(value.trim()) == null) {
      return 'Debe ser un número';
    }
    return null;
  }

  // ── Positive Number ──
  static String? positiveNumber(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'El valor es requerido';
    }
    final parsed = double.tryParse(value.trim());
    if (parsed == null) {
      return 'Debe ser un número';
    }
    if (parsed <= 0) {
      return 'Debe ser mayor a 0';
    }
    return null;
  }

  // ── Phone ──
  static String? phone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null;
    }
    final cleaned = value.replaceAll(RegExp(r'[^\d]'), '');
    if (cleaned.length != 9) {
      return 'Debe tener 9 dígitos';
    }
    return null;
  }

  // ── Min Length ──
  static String? Function(String?) minLength(int min) {
    return (String? value) {
      if (value == null || value.isEmpty) {
        return 'Requerido';
      }
      if (value.length < min) {
        return 'Mínimo $min caracteres';
      }
      return null;
    };
  }

  // ── Compose multiple validators ──
  static String? Function(String?) compose(
      List<String? Function(String?)> validators) {
    return (String? value) {
      for (final validator in validators) {
        final result = validator(value);
        if (result != null) return result;
      }
      return null;
    };
  }
}
