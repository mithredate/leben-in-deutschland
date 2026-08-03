// Small shared UI vocabulary mirroring the PWA's Tailwind idioms:
// gold primary button, outlined secondary, bordered cards, kicker labels.
import 'package:flutter/material.dart';

import 'theme.dart';

class AppButton extends StatelessWidget {
  const AppButton(this.label,
      {super.key, required this.onTap, this.variant = 'primary', this.enabled = true});

  final String label;
  final VoidCallback? onTap;
  final String variant; // primary | outline | danger
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final radius = BorderRadius.circular(kRadiusApp);
    final style = switch (variant) {
      'outline' => FilledButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: c.ink,
          side: BorderSide(color: c.line, width: 1.5),
        ),
      'danger' => FilledButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: c.red,
          side: BorderSide(color: c.red, width: 1.5),
        ),
      _ => FilledButton.styleFrom(backgroundColor: c.gold, foregroundColor: c.goldInk),
    };
    return FilledButton(
      onPressed: enabled ? onTap : null,
      style: style.copyWith(
        minimumSize: const WidgetStatePropertyAll(Size.fromHeight(52)),
        shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: radius)),
        textStyle: const WidgetStatePropertyAll(TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
      ),
      child: Text(label, textAlign: TextAlign.center),
    );
  }
}

class AppCard extends StatelessWidget {
  const AppCard({super.key, required this.child, this.padding = const EdgeInsets.all(16)});

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      padding: padding,
      decoration: BoxDecoration(
        color: c.card,
        border: Border.all(color: c.line),
        borderRadius: BorderRadius.circular(kRadiusApp),
      ),
      child: child,
    );
  }
}

class Kicker extends StatelessWidget {
  const Kicker(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) => Text(
        text.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.6,
          color: context.colors.muted,
        ),
      );
}

class TabHeader extends StatelessWidget {
  const TabHeader({super.key, required this.kicker, required this.title});
  final String kicker;
  final String title;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Kicker(kicker),
            Text(title,
                style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w800, height: 1.15)),
          ],
        ),
      );
}

Future<bool> confirmDialog(BuildContext context, String message,
    {String ok = 'OK', String cancel = 'Abbrechen'}) async {
  final res = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      content: Text(message),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(cancel)),
        TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text(ok)),
      ],
    ),
  );
  return res ?? false;
}
