// First-launch onboarding — Bundesland, then exam date (OnboardingOverlay.vue).
import 'package:flutter/material.dart';

import '../app_state.dart';
import '../models.dart';
import '../theme.dart';
import '../ui.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key, required this.onDone});

  final VoidCallback onDone;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  String step = 'state';
  late String date;

  @override
  void initState() {
    super.initState();
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final saved = AppState.I.settings.examDate;
    date = saved.compareTo(today) >= 0 ? saved : Settings.defaultExamDate();
  }

  void _pickState(String code) {
    AppState.I.store.patchSettings(state: code);
    setState(() => step = 'date');
  }

  void _finish() {
    AppState.I.store.patchSettings(examDate: date);
    widget.onDone();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Scaffold(
      backgroundColor: c.paper,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 620),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 48, 16, 40),
              child: step == 'state' ? _stateStep(c) : _dateStep(c),
            ),
          ),
        ),
      ),
    );
  }

  Widget _stateStep(AppColors c) => Column(children: [
        const Kicker('Willkommen'),
        const SizedBox(height: 6),
        const Text('In welchem Bundesland machst du die Prüfung?',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, height: 1.25)),
        const SizedBox(height: 8),
        Text('3 der 33 Prüfungsfragen kommen aus deinem Bundesland.',
            textAlign: TextAlign.center, style: TextStyle(color: c.muted)),
        const SizedBox(height: 20),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 2.9,
          children: [
            for (final e in kStates.entries)
              OutlinedButton(
                onPressed: () => _pickState(e.key),
                style: OutlinedButton.styleFrom(
                  backgroundColor: c.card,
                  side: BorderSide(color: c.line, width: 1.5),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                ),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(e.value,
                      style: TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w600, color: c.ink)),
                ),
              ),
          ],
        ),
      ]);

  Widget _dateStep(AppColors c) => Column(children: [
        const Kicker('Fast geschafft'),
        const SizedBox(height: 6),
        const Text('Wann ist deine Prüfung?',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, height: 1.25)),
        const SizedBox(height: 8),
        Text(
            'Daraus berechnet die App deinen Countdown und dein Tagespensum. Später änderbar unter „Mehr".',
            textAlign: TextAlign.center,
            style: TextStyle(color: c.muted)),
        const SizedBox(height: 18),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 280),
          child: Column(children: [
            InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () async {
                final now = DateTime.now();
                final picked = await showDatePicker(
                  context: context,
                  initialDate: DateTime.tryParse(date) ?? now,
                  firstDate: now,
                  lastDate: now.add(const Duration(days: 365 * 2)),
                );
                if (picked != null) {
                  setState(() => date = picked.toIso8601String().substring(0, 10));
                }
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: c.card,
                  border: Border.all(color: c.line, width: 1.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(date,
                    textAlign: TextAlign.center, style: const TextStyle(fontSize: 17)),
              ),
            ),
            const SizedBox(height: 18),
            SizedBox(width: double.infinity, child: AppButton("Los geht's", onTap: _finish)),
          ]),
        ),
      ]);
}
