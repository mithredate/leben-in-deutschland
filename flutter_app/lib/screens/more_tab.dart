// "Mehr" tab — settings, exam knowledge, data export/import, about.
// Ported from MoreTab.vue; export/import uses the PWA's v1 JSON format.
import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../app_state.dart';
import '../models.dart';
import '../theme.dart';
import '../ui.dart';

class MoreTab extends StatelessWidget {
  const MoreTab({super.key});

  @override
  Widget build(BuildContext context) {
    final app = AppState.I;
    final c = context.colors;
    return ListenableBuilder(
      listenable: app.store,
      builder: (context, _) {
        final settings = app.settings;
        final health = app.store.storageHealth();
        return ListView(padding: const EdgeInsets.fromLTRB(16, 16, 16, 24), children: [
          const TabHeader(kicker: 'Einstellungen & Wissen', title: 'Mehr'),
          AppCard(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Einstellungen',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
              const SizedBox(height: 10),
              _select(context, 'Bundesland', settings.state ?? '', kStates, (v) {
                app.store.patchSettings(state: v);
                showToast(context, 'Bundesland gespeichert');
              }),
              _select(context, 'Erklärungen', settings.lang,
                  const {'en': 'Englisch', 'de': 'Deutsch'},
                  (v) => app.store.patchSettings(lang: v)),
              _dateField(context, 'Prüfungsdatum', settings.examDate,
                  (v) => app.store.patchSettings(examDate: v)),
              _select(context, 'Design', settings.theme,
                  const {'auto': 'Wie System', 'light': 'Hell', 'dark': 'Dunkel'},
                  (v) => app.store.patchSettings(theme: v)),
            ]),
          ),
          AppCard(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('So läuft die Prüfung',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
              const SizedBox(height: 10),
              _bullet('33 Fragen, Mehrfachauswahl, genau eine Antwort richtig.'),
              _bullet('60 Minuten Zeit – die meisten sind nach 15–20 Minuten fertig.'),
              _bullet('30 Fragen aus dem Katalog (300) + 3 aus deinem Bundesland (10).'),
              _bullet('Für die Niederlassungserlaubnis („Leben in Deutschland"): 15 richtige reichen.'),
              _bullet('Für die Einbürgerung zählt dieselbe Prüfung ab 17 richtigen – schaffst du 17+, ist das Zertifikat später auch dafür gültig.'),
              _bullet('Mitbringen: Ausweis/Pass und die Einladung. Handy bleibt aus.'),
              _bullet('Es gibt keine Minuspunkte – nie eine Frage offen lassen, im Zweifel raten.'),
            ]),
          ),
          AppCard(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Merkhilfen – die Zahlen, die immer drankommen',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
              const SizedBox(height: 10),
              _bullet('1949 Grundgesetz · 1961 Mauerbau · 9. Nov 1989 Mauerfall · 3. Okt 1990 Wiedervereinigung (Feiertag!) · 8. Mai 1945 Kriegsende'),
              _bullet('16 Bundesländer · Bundestagswahl alle 4 Jahre · wählen ab 18 · Schulpflicht ab 6'),
              _bullet('Bundeskanzler/in wird vom Bundestag gewählt; Staatsoberhaupt ist der/die Bundespräsident/in (gewählt von der Bundesversammlung)'),
              _bullet('Gewaltenteilung: Legislative (Parlament) · Exekutive (Regierung/Polizei) · Judikative (Gerichte). „Direktive" gibt es nicht!'),
              _bullet('Erststimme = Person im Wahlkreis · Zweitstimme = Partei (entscheidet Sitzverteilung) · 5%-Hürde'),
              _bullet('Deutschland: demokratischer + sozialer Bundesstaat · Rechtsstaat = Staat ist an Gesetze gebunden'),
              _bullet('9 Nachbarländer (u.a. Polen, Dänemark, Luxemburg, Tschechien, Österreich). Beliebte Fangfrage: die Schweiz ist Nachbar, aber nicht in der EU – Österreich schon.'),
              _bullet('Wappen: Bundesadler (gelb/schwarz) = BRD · Hammer & Zirkel im Ährenkranz = DDR · Sterne auf Blau = EU-Flagge'),
              _bullet('Sozialversicherung: Kranken-, Pflege-, Renten-, Unfall- und Arbeitslosenversicherung – keine „Autoversicherung"!'),
            ]),
          ),
          AppCard(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Daten', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
              const SizedBox(height: 8),
              Text(
                '💾 ${health.seen} Frage${health.seen == 1 ? '' : 'n'} gespeichert'
                ' · zuletzt: ${_lastSaved(health.lastSaved)}',
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: c.paper,
                  border: Border.all(color: c.line),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'Fortschritt aus der Web-App übernehmen: dort unter „Mehr" exportieren, '
                  'die Datei hier importieren. Das Format ist identisch.',
                  style: TextStyle(fontSize: 12.5, color: c.muted),
                ),
              ),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(
                    child: AppButton('Exportieren',
                        variant: 'outline', onTap: () => _export(context))),
                const SizedBox(width: 10),
                Expanded(
                    child: AppButton('Importieren',
                        variant: 'outline', onTap: () => _import(context))),
              ]),
              const SizedBox(height: 10),
              AppButton('Fortschritt zurücksetzen',
                  variant: 'danger', onTap: () => _reset(context)),
            ]),
          ),
          AppCard(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Über', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
              const SizedBox(height: 8),
              Text(
                'Keine offizielle App – kein Zusammenhang mit dem BAMF oder anderen Behörden. '
                'Alles bleibt auf deinem Gerät, keine Konten, keine Datensammlung.\n\n'
                'Fragenkatalog: BAMF „Gesamtfragenkatalog Leben in Deutschland / Einbürgerungstest" '
                '(Stand 05/2025), aufbereitet aus den MIT-lizenzierten Projekten '
                'flexsurfer/einburgerungstest und leben-in-deutschland-scrapper. '
                'Erklärungen KI-erstellt mit Quellenangabe, ohne Gewähr.',
                style: TextStyle(fontSize: 13.5, height: 1.5, color: c.muted),
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () => launchUrl(
                    Uri.parse('https://github.com/mithredate/leben-in-deutschland'),
                    mode: LaunchMode.externalApplication),
                child: Text('Quellcode & Fehler melden: GitHub',
                    style: TextStyle(
                        fontSize: 13.5, color: c.red, decoration: TextDecoration.underline)),
              ),
            ]),
          ),
        ]);
      },
    );
  }

  static String _lastSaved(int? ms) {
    if (ms == null) return '–';
    final d = DateTime.fromMillisecondsSinceEpoch(ms).toLocal();
    String p(int n) => n.toString().padLeft(2, '0');
    return '${p(d.day)}.${p(d.month)}. ${p(d.hour)}:${p(d.minute)}';
  }

  Future<void> _export(BuildContext context) async {
    final json = AppState.I.store.exportAll();
    final date = DateTime.now().toIso8601String().substring(0, 10);
    await SharePlus.instance.share(ShareParams(
      files: [
        XFile.fromData(utf8.encode(json),
            mimeType: 'application/json', name: 'lid-fortschritt-$date.json'),
      ],
      fileNameOverrides: ['lid-fortschritt-$date.json'],
    ));
  }

  Future<void> _import(BuildContext context) async {
    final res = await FilePicker.platform.pickFiles(type: FileType.any);
    final path = res?.files.single.path;
    if (path == null) return;
    try {
      AppState.I.store.importAll(await File(path).readAsString());
      if (context.mounted) showToast(context, 'Fortschritt importiert ✓');
    } catch (_) {
      if (context.mounted) showToast(context, 'Import fehlgeschlagen');
    }
  }

  Future<void> _reset(BuildContext context) async {
    if (await confirmDialog(context, 'Wirklich den gesamten Lernfortschritt löschen?')) {
      AppState.I.store.resetProgress();
      if (context.mounted) showToast(context, 'Zurückgesetzt');
    }
  }

  Widget _bullet(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('  •  '),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 14.5, height: 1.45))),
        ]),
      );

  Widget _select(BuildContext context, String label, String value, Map<String, String> options,
      void Function(String) onChanged) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label,
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: c.muted)),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          initialValue: options.containsKey(value) ? value : null,
          decoration: InputDecoration(
            filled: true,
            fillColor: c.card,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: c.line, width: 1.5)),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: c.gold, width: 1.5)),
          ),
          items: [
            for (final e in options.entries)
              DropdownMenuItem(value: e.key, child: Text(e.value)),
          ],
          onChanged: (v) => v != null ? onChanged(v) : null,
        ),
      ]),
    );
  }

  Widget _dateField(
      BuildContext context, String label, String value, void Function(String) onChanged) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label,
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: c.muted)),
        const SizedBox(height: 6),
        InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () async {
            final now = DateTime.now();
            final picked = await showDatePicker(
              context: context,
              initialDate: DateTime.tryParse(value) ?? now,
              firstDate: now.subtract(const Duration(days: 1)),
              lastDate: now.add(const Duration(days: 365 * 2)),
            );
            if (picked != null) onChanged(picked.toIso8601String().substring(0, 10));
          },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            decoration: BoxDecoration(
              color: c.card,
              border: Border.all(color: c.line, width: 1.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(value, style: const TextStyle(fontSize: 15)),
          ),
        ),
      ]),
    );
  }
}
