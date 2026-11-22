/// Mengubah teks koordinat (boleh memakai koma desimal) menjadi angka.
double? parseCoordinate(String? v) =>
    double.tryParse((v ?? '').trim().replaceAll(',', '.'));

String? validateCoordinate(String? v, double min, double max, String label) {
  final value = parseCoordinate(v);
  if (value == null) return '$label harus berupa angka';
  if (value < min || value > max) return '$label harus antara $min dan $max';
  return null;
}
