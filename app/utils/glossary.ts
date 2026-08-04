// Brief English glosses for German civic terms that stay untranslated in the
// English question/answer texts (Bundestag, Grundgesetz, …). Applied at render
// time so questions.json stays pristine. Keep in sync with the Flutter port
// (flutter_app/lib/glossary.dart).
//
// Longest terms are matched first so "Bundesländer" wins over "Bundesland".
// JS \b is ASCII-only (it would match inside "Bundesländer" after "Bundesland"),
// so boundaries are explicit character classes instead.
const TERMS: [string, string][] = [
  ['Landeszentrale für politische Bildung', 'state agency for civic education'],
  ['Bundesverfassungsgericht', 'Federal Constitutional Court'],
  ['Bundesversammlung', 'Federal Convention, which elects the Federal President'],
  ['Bundeskanzlerin', 'Federal Chancellor, head of government'],
  ['Bundespräsident', 'Federal President, head of state'],
  ['Bundesregierung', 'federal government'],
  ['Bundeskanzler', 'Federal Chancellor, head of government'],
  ['Bundesländer', 'federal states'],
  ['Grundgesetz', "Basic Law, Germany's constitution"],
  ['Bundesland', 'federal state'],
  ['Bundestag', 'federal parliament'],
  ['Bundesrat', 'chamber of the 16 state governments'],
  ['Landkreis', 'rural administrative district'],
  ['Landtag', 'state parliament'],
]

const LETTER = 'A-Za-zÄÖÜäöüß'
const RULES = TERMS
  .slice()
  .sort((a, b) => b[0].length - a[0].length)
  .map(([term, gloss]) => ({
    re: new RegExp(`(^|[^${LETTER}])(${term})(?![${LETTER}-])`),
    gloss,
  }))

// Append "(gloss)" after the first occurrence of each known term,
// unless the text already explains it with a parenthesis right there.
export function gloss(text: string | null | undefined): string {
  if (!text) return ''
  let out = text
  for (const rule of RULES) {
    const m = rule.re.exec(out)
    if (!m) continue
    const end = m.index + m[0].length
    if (out.slice(end).startsWith(' (') || out.slice(end).startsWith('(')) continue
    out = `${out.slice(0, end)} (${rule.gloss})${out.slice(end)}`
  }
  return out
}
