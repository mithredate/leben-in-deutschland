// "Fragen" tab — search/filter the catalog; ported from BrowseTab.vue.
import 'dart:math';

import 'package:flutter/material.dart';

import '../app_state.dart';
import '../models.dart';
import '../srs.dart';
import '../theme.dart';
import '../ui.dart';

class BrowseTab extends StatefulWidget {
  const BrowseTab({super.key, required this.onPractice});

  final void Function(List<Question> qs) onPractice;

  @override
  State<BrowseTab> createState() => _BrowseTabState();
}

class _BrowseTabState extends State<BrowseTab> {
  final app = AppState.I;
  String text = '';
  String cat = 'alle';
  String status = 'alle';

  static const statusOptions = {
    'alle': 'Jeder Status',
    'neu': 'Neu',
    'fehler': 'Fehler',
    'markiert': 'Markiert ★',
    'leech': 'Hartnäckig 🔥',
    'sicher': 'Sicher',
  };

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return ListenableBuilder(
      listenable: app.store,
      builder: (context, _) {
        final pool = app.pool;
        final cats = pool.map((q) => q.category).toSet().toList();
        final progress = app.store.getProgress();
        final marked = app.store.getMarked();

        final rows = pool.where((q) {
          if (cat != 'alle' && q.category != cat) return false;
          final e = progress[q.id];
          if (status == 'neu' && e != null && e.seen > 0) return false;
          if (status == 'fehler' && (e == null || e.box != 1)) return false;
          if (status == 'sicher' && (e == null || e.box < 5)) return false;
          if (status == 'leech' && !isLeech(e)) return false;
          if (status == 'markiert' && !marked.contains(q.id)) return false;
          if (text.isNotEmpty) {
            final t = text.toLowerCase();
            if (!q.question.toLowerCase().contains(t) &&
                !q.num.toLowerCase().contains(t) &&
                !q.answers.any((a) => a.toLowerCase().contains(t))) {
              return false;
            }
          }
          return true;
        }).toList();

        return ListView(padding: const EdgeInsets.fromLTRB(16, 16, 16, 24), children: [
          TabHeader(kicker: '${pool.length} Fragen im Katalog', title: 'Fragen'),
          TextField(
            decoration: _inputDecoration(c, 'Suchen…').copyWith(
                prefixIcon: Icon(Icons.search, color: c.muted)),
            onChanged: (v) => setState(() => text = v),
          ),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(
              child: _dropdown(c, cat, {
                'alle': 'Alle Themen',
                for (final x in cats) x: x,
              }, (v) => setState(() => cat = v)),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _dropdown(c, status, statusOptions, (v) => setState(() => status = v)),
            ),
          ]),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 2),
            child: Text.rich(TextSpan(children: [
              TextSpan(text: '${rows.length} Treffer'),
              if (rows.isNotEmpty) ...[
                const TextSpan(text: ' · '),
                WidgetSpan(
                  alignment: PlaceholderAlignment.baseline,
                  baseline: TextBaseline.alphabetic,
                  child: GestureDetector(
                    onTap: () {
                      final drill = [...rows]..shuffle(Random());
                      widget.onPractice(drill.take(30).toList());
                    },
                    child: Text('diese üben',
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: c.red,
                            decoration: TextDecoration.underline)),
                  ),
                ),
              ],
            ], style: TextStyle(fontSize: 13, color: c.muted))),
          ),
          for (final q in rows) _row(c, q, progress[q.id], marked.contains(q.id)),
        ]);
      },
    );
  }

  InputDecoration _inputDecoration(AppColors c, String hint) => InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: c.card,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: c.line, width: 1.5)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: c.gold, width: 1.5)),
      );

  Widget _dropdown(
      AppColors c, String value, Map<String, String> options, void Function(String) onChanged) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      decoration: _inputDecoration(c, ''),
      items: [
        for (final e in options.entries)
          DropdownMenuItem(value: e.key, child: Text(e.value, style: const TextStyle(fontSize: 14))),
      ],
      onChanged: (v) => v != null ? onChanged(v) : null,
    );
  }

  Widget _row(AppColors c, Question q, ProgressEntry? e, bool isMarked) {
    Color? dotColor;
    Border? dotBorder;
    double opacity = 1;
    if (e == null || e.seen == 0) {
      dotBorder = Border.all(color: c.muted, width: 1.5);
    } else if (e.box >= 5) {
      dotColor = c.gold;
    } else if (e.box == 1) {
      dotColor = c.red;
    } else {
      dotColor = c.red;
      opacity = 0.55;
    }
    return InkWell(
      onTap: () => widget.onPractice([q]),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
        decoration: BoxDecoration(border: Border(bottom: BorderSide(color: c.line))),
        child: Row(children: [
          Opacity(
            opacity: opacity,
            child: Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(color: dotColor, border: dotBorder, shape: BoxShape.circle),
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 44,
            child: Text(
              '${q.num}${isMarked ? ' ★' : ''}${isLeech(e) ? ' 🔥' : ''}',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: c.muted),
            ),
          ),
          Expanded(
            child: Text(q.question,
                maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 14)),
          ),
        ]),
      ),
    );
  }
}
