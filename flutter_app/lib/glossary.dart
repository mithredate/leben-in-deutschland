// Brief English glosses for German civic terms that stay untranslated in the
// English question/answer texts (Bundestag, Grundgesetz, …). Applied at render
// time so the bundled data stays pristine. 1:1 port of app/utils/glossary.ts —
// keep both in sync.
//
// Longest terms are matched first so "Bundesländer" wins over "Bundesland".
// \b is ASCII-only (it would match inside "Bundesländer" after "Bundesland"),
// so boundaries are explicit character classes instead.
const List<(String, String)> _terms = [
  ('Landeszentrale für politische Bildung', 'state agency for civic education'),
  ('Bundesverfassungsgericht', 'Federal Constitutional Court'),
  ('Bundesversammlung', 'Federal Convention, which elects the Federal President'),
  ('Bundeskanzlerin', 'Federal Chancellor, head of government'),
  ('Bundespräsident', 'Federal President, head of state'),
  ('Bundesregierung', 'federal government'),
  ('Bundeskanzler', 'Federal Chancellor, head of government'),
  ('Bundesländer', 'federal states'),
  ('Grundgesetz', "Basic Law, Germany's constitution"),
  ('Bundesland', 'federal state'),
  ('Bundestag', 'federal parliament'),
  ('Bundesrat', 'chamber of the 16 state governments'),
  ('Landkreis', 'rural administrative district'),
  ('Landtag', 'state parliament'),
];

const String _letter = 'A-Za-zÄÖÜäöüß';

final List<(RegExp, String)> _rules = (_terms.toList()
      ..sort((a, b) => b.$1.length - a.$1.length))
    .map((t) => (RegExp('(^|[^$_letter])(${t.$1})(?![$_letter-])'), t.$2))
    .toList();

/// Append "(gloss)" after the first occurrence of each known term,
/// unless the text already explains it with a parenthesis right there.
String gloss(String? text) {
  if (text == null || text.isEmpty) return '';
  var out = text;
  for (final (re, g) in _rules) {
    final m = re.firstMatch(out);
    if (m == null) continue;
    final end = m.end;
    final rest = out.substring(end);
    if (rest.startsWith(' (') || rest.startsWith('(')) continue;
    out = '${out.substring(0, end)} ($g)$rest';
  }
  return out;
}
