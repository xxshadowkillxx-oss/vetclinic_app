import 'package:flutter/services.dart';

String normalizeRut(String value) {
  final cleaned = value.toUpperCase().replaceAll(RegExp(r'[^0-9K]'), '');
  if (cleaned.length < 2) return '';
  return '${cleaned.substring(0, cleaned.length - 1)}-${cleaned.substring(cleaned.length - 1)}';
}

String formatRut(String value) {
  var cleaned = value.toUpperCase().replaceAll(RegExp(r'[^0-9K]'), '');
  if (cleaned.length > 9) {
    cleaned = cleaned.substring(0, 9);
  }
  if (cleaned.length < 2) return cleaned;

  final verifier = cleaned.substring(cleaned.length - 1);
  final body = cleaned.substring(0, cleaned.length - 1);
  final reversed = body.split('').reversed.toList();
  final groups = <String>[];
  for (var index = 0; index < reversed.length; index += 3) {
    final end = index + 3 < reversed.length ? index + 3 : reversed.length;
    groups.add(reversed.sublist(index, end).reversed.join());
  }
  return '${groups.reversed.join('.')}-$verifier';
}

class RutInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final formatted = formatRut(newValue.text);
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

bool isValidRut(String value) {
  final normalized = normalizeRut(value);
  if (normalized.isEmpty) return false;

  final parts = normalized.split('-');
  final body = parts[0];
  final verifier = parts[1];
  return RegExp(r'^\d{6,8}$').hasMatch(body) &&
      RegExp(r'^[0-9K]$').hasMatch(verifier);
}
