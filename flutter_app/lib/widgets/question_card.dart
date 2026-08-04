// The question card — ported from app/components/QuestionCard.vue.
// study mode: instant grading, explanation, EN flip, difficult-star.
// exam mode: selection only, grading happens at submit.
import 'dart:math';

import 'package:flutter/material.dart';

import '../app_state.dart';
import '../glossary.dart';
import '../models.dart';
import '../theme.dart';
import 'source_line.dart';

class QuestionCard extends StatefulWidget {
  const QuestionCard({
    super.key,
    required this.q,
    required this.mode, // 'study' | 'exam'
    this.picked,
    this.label,
    this.onAnswer,
    this.onPick,
    this.controlled = false,
    this.answered,
  });

  final Question q;
  final String mode;
  final int? picked;
  final String? label;
  final void Function(bool correct, int picked)? onAnswer;
  final void Function(int index)? onPick;

  /// study mode: when [controlled] is true the parent owns the answer state
  /// via [answered] (enables revisiting an answered card with feedback intact)
  final bool controlled;
  final int? answered;

  @override
  State<QuestionCard> createState() => _QuestionCardState();
}

class _QuestionCardState extends State<QuestionCard> {
  late List<int> order;
  int? localAnswered;
  int? get answered => widget.controlled ? widget.answered : localAnswered;
  bool flipped = false;
  bool showAlt = false;
  bool marked = false;

  // answers stay in catalog order when they reference image positions/numbers
  static final _positional = RegExp(r'^(bild\s*)?\d+\s*€?$', caseSensitive: false);
  bool get isPositional => widget.q.answers.every((a) => _positional.hasMatch(a.trim()));

  @override
  void initState() {
    super.initState();
    _resetFor(widget.q);
  }

  @override
  void didUpdateWidget(QuestionCard old) {
    super.didUpdateWidget(old);
    if (old.q.id != widget.q.id) _resetFor(widget.q);
  }

  void _resetFor(Question q) {
    order = isPositional ? [0, 1, 2, 3] : ([0, 1, 2, 3]..shuffle(Random()));
    localAnswered = null;
    flipped = false;
    showAlt = false;
    marked = AppState.I.store.getMarked().contains(q.id);
  }

  void _toggleMark() {
    setState(() => marked = AppState.I.store.toggleMarked(widget.q.id));
    showToast(context, marked ? '★ Als schwierig markiert' : 'Markierung entfernt');
  }

  QuestionEn get en => widget.q.en;

  bool get hasBack =>
      widget.mode == 'study' &&
      AppState.I.settings.lang != 'de' &&
      (en.question != null || en.explanation != null || en.answers.any((a) => a != null));

  String? get expl {
    final lang = AppState.I.settings.lang;
    return lang == 'en' ? en.explanation : (widget.q.explanationDe ?? en.explanation);
  }

  String? get altExpl {
    final lang = AppState.I.settings.lang;
    return lang == 'en' ? widget.q.explanationDe : en.explanation;
  }

  void _choose(int i) {
    if (widget.mode == 'exam') {
      widget.onPick?.call(i);
      return;
    }
    if (answered != null) return;
    if (!widget.controlled) setState(() => localAnswered = i);
    widget.onAnswer?.call(i == widget.q.correct, i);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final q = widget.q;
    final correct = answered != null && answered == q.correct;

    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 24, top: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Expanded(
              child: Text(
                (widget.label ?? 'Frage ${q.num} · ${q.category}').toUpperCase(),
                style: TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 1.4, color: c.muted),
              ),
            ),
            if (widget.mode == 'study') ...[
              _chip(
                marked ? '★' : '☆',
                active: marked,
                activeColor: c.gold,
                onTap: _toggleMark,
              ),
              const SizedBox(width: 6),
            ],
            if (hasBack)
              _chip(
                'EN ⇄',
                active: flipped,
                activeColor: c.gold,
                onTap: () => setState(() => flipped = !flipped),
              ),
          ]),
          const SizedBox(height: 8),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            transitionBuilder: (child, anim) => FadeTransition(opacity: anim, child: child),
            child: flipped ? _backFace(c, q) : _frontFace(c, q),
          ),
          if (widget.mode == 'study' && answered != null) _feedback(c, correct),
        ],
      ),
    );
  }

  Widget _chip(String label, {required bool active, required Color activeColor, VoidCallback? onTap}) {
    final c = context.colors;
    return InkWell(
      borderRadius: BorderRadius.circular(99),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          border: Border.all(color: active ? activeColor : c.line, width: 1.5),
          borderRadius: BorderRadius.circular(99),
        ),
        child: Text(label,
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: active ? (label.startsWith('★') ? c.gold : c.ink) : c.muted)),
      ),
    );
  }

  Widget _frontFace(AppColors c, Question q) => Column(
        key: const ValueKey('front'),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(q.question,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, height: 1.35)),
          if (q.image != null) _image(c, q.image!),
          const SizedBox(height: 14),
          for (final (pos, i) in order.indexed) ...[
            _answerButton(c, q, i, pos),
            const SizedBox(height: 10),
          ],
        ],
      );

  Widget _backFace(AppColors c, Question q) => Column(
        key: const ValueKey('back'),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('ENGLISH',
              style: TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 1.4, color: c.muted)),
          const SizedBox(height: 6),
          Text(gloss(en.question ?? q.question),
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, height: 1.35)),
          const SizedBox(height: 14),
          for (final (pos, i) in order.indexed) ...[
            _answerButton(c, q, i, pos,
                text: gloss((i < en.answers.length ? en.answers[i] : null) ?? q.answers[i])),
            const SizedBox(height: 10),
          ],
          if (en.explanation != null)
            Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: c.paper,
                border: Border.all(color: c.line),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(en.explanation!, style: TextStyle(fontSize: 14, color: c.muted)),
            ),
          SourceLine(q),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: () => setState(() => flipped = false),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
              side: BorderSide(color: c.line, width: 1.5),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kRadiusApp)),
            ),
            child: Text('← Zurück zur Frage',
                style: TextStyle(fontWeight: FontWeight.w700, color: c.ink)),
          ),
        ],
      );

  Widget _image(AppColors c, String file) => Container(
        margin: const EdgeInsets.only(top: 10),
        constraints: const BoxConstraints(maxWidth: 460),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: c.line),
          borderRadius: BorderRadius.circular(10),
        ),
        clipBehavior: Clip.antiAlias,
        child: Image.asset('assets/img/$file', width: double.infinity, fit: BoxFit.contain),
      );

  // [text] overrides the answer label (EN back face); selection state and
  // grading colors are shared with the front — one model, two faces.
  Widget _answerButton(AppColors c, Question q, int i, int pos, {String? text}) {
    Color border = c.line, bg = c.card, letterBg = c.paper, letterFg = c.ink, letterBorder = c.line;
    if (widget.mode == 'exam') {
      if (widget.picked == i) {
        border = c.ink;
        bg = c.paper;
        letterBg = c.ink;
        letterFg = c.paper;
      }
    } else if (answered != null) {
      if (i == q.correct) {
        border = c.green;
        bg = c.greenSoft;
        letterBg = c.green;
        letterFg = Colors.white;
        letterBorder = c.green;
      } else if (i == answered) {
        border = c.red;
        bg = c.redSoft;
        letterBg = c.red;
        letterFg = Colors.white;
        letterBorder = c.red;
      }
    }
    final disabled = widget.mode == 'study' && answered != null;
    return InkWell(
      borderRadius: BorderRadius.circular(kRadiusApp),
      onTap: disabled ? null : () => _choose(i),
      child: _answerShell(c,
          letter: 'ABCD'[pos],
          text: text ?? q.answers[i],
          border: border,
          bg: bg,
          letterBg: letterBg,
          letterFg: letterFg,
          letterBorder: letterBorder),
    );
  }

  Widget _answerShell(AppColors c,
      {required String letter,
      required String text,
      required Color border,
      required Color bg,
      Color? letterBg,
      Color? letterFg,
      Color? letterBorder}) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 52),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: bg,
        border: Border.all(color: border, width: 1.5),
        borderRadius: BorderRadius.circular(kRadiusApp),
      ),
      child: Row(children: [
        Container(
          width: 28,
          height: 28,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: letterBg ?? c.paper,
            border: Border.all(color: letterBorder ?? c.line),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(letter,
              style: TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w700, color: letterFg ?? c.ink)),
        ),
        const SizedBox(width: 12),
        Expanded(child: Text(text, style: const TextStyle(fontSize: 15.5, height: 1.4))),
      ]),
    );
  }

  Widget _feedback(AppColors c, bool correct) {
    final e = expl;
    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(correct ? 'Richtig!' : 'Leider falsch.',
              style: TextStyle(
                  fontSize: 17, fontWeight: FontWeight.w800, color: correct ? c.green : c.red)),
          if (e != null)
            Container(
              margin: const EdgeInsets.only(top: 6),
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: c.paper,
                border: Border.all(color: c.line),
                borderRadius: BorderRadius.circular(10),
              ),
              child: _ExplanationBlock(
                q: widget.q,
                expl: e,
                altExpl: altExpl,
                initiallyOpen: !correct,
              ),
            ),
        ],
      ),
    );
  }
}

class _ExplanationBlock extends StatefulWidget {
  const _ExplanationBlock(
      {required this.q, required this.expl, required this.altExpl, required this.initiallyOpen});

  final Question q;
  final String expl;
  final String? altExpl;
  final bool initiallyOpen;

  @override
  State<_ExplanationBlock> createState() => _ExplanationBlockState();
}

class _ExplanationBlockState extends State<_ExplanationBlock> {
  late bool open = widget.initiallyOpen;
  bool showAlt = false;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final isEn = AppState.I.settings.lang == 'en';
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => setState(() => open = !open),
        child: Row(children: [
          Icon(open ? Icons.expand_more : Icons.chevron_right, size: 18, color: c.muted),
          const Text('Erklärung', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
        ]),
      ),
      if (open) ...[
        const SizedBox(height: 8),
        Text(widget.expl, style: TextStyle(fontSize: 14, height: 1.45, color: c.muted)),
        SourceLine(widget.q),
        if (widget.altExpl != null) ...[
          const SizedBox(height: 4),
          GestureDetector(
            onTap: () => setState(() => showAlt = !showAlt),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Text(
                'Auf ${isEn ? 'Deutsch' : 'Englisch'} zeigen',
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: c.red,
                    decoration: TextDecoration.underline),
              ),
            ),
          ),
          if (showAlt)
            Text(widget.altExpl!, style: TextStyle(fontSize: 14, height: 1.45, color: c.muted)),
        ],
      ],
    ]);
  }
}
