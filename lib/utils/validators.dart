/// Validadores para formularios
class FormValidators {
  /// Validar email
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'El email es requerido';
    }

    // Expresión regular para validar email
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );

    if (!emailRegex.hasMatch(value)) {
      return 'Ingresa un email válido';
    }

    return null;
  }

  /// Validar contraseña
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'La contraseña es requerida';
    }

    if (value.length < 6) {
      return 'La contraseña debe tener al menos 6 caracteres';
    }

    return null;
  }

  /// Validar nombre
  static String? validateName(String? value) {
    if (value == null || value.isEmpty) {
      return 'El nombre es requerido';
    }

    if (value.length < 3) {
      return 'El nombre debe tener al menos 3 caracteres';
    }

    if (value.length > 50) {
      return 'El nombre no puede exceder 50 caracteres';
    }

    // Solo letras, espacios y algunos caracteres especiales
    final nameRegex = RegExp(r'^[a-zA-ZáéíóúÁÉÍÓÚñÑ\s]+$');
    if (!nameRegex.hasMatch(value)) {
      return 'El nombre solo puede contener letras y espacios';
    }

    return null;
  }

  /// Validar campo requerido
  static String? validateRequired(String? value, {String fieldName = 'Este campo'}) {
    if (value == null || value.isEmpty) {
      return '$fieldName es requerido';
    }
    return null;
  }

  /// Validar longitud mínima
  static String? validateMinLength(String? value, int minLength, {String fieldName = 'Este campo'}) {
    if (value == null || value.isEmpty) {
      return '$fieldName es requerido';
    }

    if (value.length < minLength) {
      return '$fieldName debe tener al menos $minLength caracteres';
    }

    return null;
  }

  /// Validar longitud máxima
  static String? validateMaxLength(String? value, int maxLength, {String fieldName = 'Este campo'}) {
    if (value == null || value.isEmpty) {
      return null; // Opcional si está vacío
    }

    if (value.length > maxLength) {
      return '$fieldName no puede exceder $maxLength caracteres';
    }

    return null;
  }

  /// Validar número
  static String? validateNumber(String? value, {String fieldName = 'Este campo'}) {
    if (value == null || value.isEmpty) {
      return '$fieldName es requerido';
    }

    final number = num.tryParse(value);
    if (number == null) {
      return '$fieldName debe ser un número válido';
    }

    return null;
  }

  /// Validar número positivo
  static String? validatePositiveNumber(String? value, {String fieldName = 'Este campo'}) {
    if (value == null || value.isEmpty) {
      return '$fieldName es requerido';
    }

    final number = num.tryParse(value);
    if (number == null) {
      return '$fieldName debe ser un número válido';
    }

    if (number <= 0) {
      return '$fieldName debe ser mayor a 0';
    }

    return null;
  }

  /// Validar título de tarea o nota
  static String? validateTitle(String? value) {
    if (value == null || value.isEmpty) {
      return 'El título es requerido';
    }

    if (value.length < 3) {
      return 'El título debe tener al menos 3 caracteres';
    }

    if (value.length > 100) {
      return 'El título no puede exceder 100 caracteres';
    }

    return null;
  }

  /// Validar descripción
  static String? validateDescription(String? value) {
    if (value == null || value.isEmpty) {
      return 'La descripción es requerida';
    }

    if (value.length < 10) {
      return 'La descripción debe tener al menos 10 caracteres';
    }

    if (value.length > 500) {
      return 'La descripción no puede exceder 500 caracteres';
    }

    return null;
  }

  /// Validar contenido de nota (más largo)
  static String? validateNoteContent(String? value) {
    if (value == null || value.isEmpty) {
      return 'El contenido es requerido';
    }

    if (value.length < 5) {
      return 'El contenido debe tener al menos 5 caracteres';
    }

    if (value.length > 5000) {
      return 'El contenido no puede exceder 5000 caracteres';
    }

    return null;
  }

  /// Validar confirmación de contraseña
  static String? validatePasswordConfirmation(String? value, String password) {
    if (value == null || value.isEmpty) {
      return 'Confirma tu contraseña';
    }

    if (value != password) {
      return 'Las contraseñas no coinciden';
    }

    return null;
  }

  /// Validar fecha (no puede ser en el pasado)
  static String? validateFutureDate(DateTime? value) {
    if (value == null) {
      return 'La fecha es requerida';
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final selectedDate = DateTime(value.year, value.month, value.day);

    if (selectedDate.isBefore(today)) {
      return 'La fecha no puede ser en el pasado';
    }

    return null;
  }

  /// Validar rango de fechas
  static String? validateDateRange(DateTime? startDate, DateTime? endDate) {
    if (startDate == null || endDate == null) {
      return 'Ambas fechas son requeridas';
    }

    if (endDate.isBefore(startDate)) {
      return 'La fecha de fin debe ser posterior a la de inicio';
    }

    return null;
  }
}
