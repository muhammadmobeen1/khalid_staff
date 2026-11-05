import 'dart:math';

String money(dynamic cents) {
  final value = int.tryParse('${cents ?? 0}') ?? 0;
  final rupees = value / 100;
  final whole = rupees == rupees.roundToDouble();
  final text = whole ? rupees.toStringAsFixed(0) : rupees.toStringAsFixed(2);
  final parts = text.split('.');
  final chars = parts[0].split('').reversed.toList();
  final grouped = <String>[];
  for (var i = 0; i < chars.length; i++) {
    if (i > 0 && i % 3 == 0) grouped.add(',');
    grouped.add(chars[i]);
  }
  final integer = grouped.reversed.join();
  return 'Rs $integer${parts.length > 1 ? '.${parts[1]}' : ''}';
}

String todayIso() {
  final now = DateTime.now();
  return '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
}

String requestKey() {
  const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
  final r = Random.secure();
  return List.generate(28, (_) => chars[r.nextInt(chars.length)]).join();
}

List<Map<String, dynamic>> mapList(dynamic input) {
  if (input is! List) return const [];
  return input.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
}
