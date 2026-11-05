import 'package:flutter/material.dart';

const navy = Color(0xFF0A1B3A);
const blue = Color(0xFF2878FF);
const purple = Color(0xFF6C4CFF);
const green = Color(0xFF12B76A);
const red = Color(0xFFFF5A5F);
const amber = Color(0xFFFFAE2B);
// Backward-compatible alias used by receipt/history UI.
const orange = amber;

class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? color;
  final VoidCallback? onTap;
  const AppCard({super.key, required this.child, this.padding = const EdgeInsets.all(16), this.color, this.onTap});

  @override
  Widget build(BuildContext context) {
    final body = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE4EAF3)),
        boxShadow: const [BoxShadow(color: Color(0x110A1B3A), blurRadius: 18, offset: Offset(0, 8))],
      ),
      child: child,
    );
    if (onTap == null) return body;
    return InkWell(borderRadius: BorderRadius.circular(22), onTap: onTap, child: body);
  }
}

class StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color accent;
  const StatCard({super.key, required this.label, required this.value, required this.icon, required this.accent});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(color: accent.withOpacity(.12), borderRadius: BorderRadius.circular(14)),
          child: Icon(icon, color: accent),
        ),
        const SizedBox(height: 14),
        Text(label, style: const TextStyle(color: Color(0xFF71809B), fontSize: 13)),
        const SizedBox(height: 5),
        Text(value, style: const TextStyle(color: navy, fontSize: 23, fontWeight: FontWeight.w800)),
      ]),
    );
  }
}

class StatusPill extends StatelessWidget {
  final String text;
  final Color color;
  const StatusPill(this.text, {super.key, required this.color});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color.withOpacity(.12),
          borderRadius: BorderRadius.circular(30),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w700,
            fontSize: 12,
          ),
        ),
      );
}

class EmptyState extends StatelessWidget {
  final String title;
  final String message;
  final IconData icon;
  const EmptyState({super.key, required this.title, required this.message, this.icon = Icons.inbox_outlined});
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 52, color: const Color(0xFF9AA8C0)),
        const SizedBox(height: 14),
        Text(title, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: navy)),
        const SizedBox(height: 6),
        Text(message, textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFF71809B), height: 1.4)),
      ]),
    ),
  );
}

InputDecoration fieldDecoration(String label, {String? hint, IconData? icon}) => InputDecoration(
  labelText: label,
  hintText: hint,
  prefixIcon: icon == null ? null : Icon(icon),
  filled: true,
  fillColor: const Color(0xFFF7F9FC),
  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFDCE4F0))),
  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFDCE4F0))),
  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: blue, width: 1.6)),
  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
);
