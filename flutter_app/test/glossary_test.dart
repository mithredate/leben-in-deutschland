// Parity tests for the render-time EN glossary (app/utils/glossary.ts).
import 'package:flutter_test/flutter_test.dart';
import 'package:lid_trainer/glossary.dart';

void main() {
  test('appends a brief English gloss after known German terms', () {
    expect(gloss('Who elects the Bundeskanzler in Germany?'),
        'Who elects the Bundeskanzler (Federal Chancellor, head of government) in Germany?');
  });

  test('longest term wins: Bundesländer is not glossed as Bundesland', () {
    expect(gloss('The Bundesländer send members.'),
        'The Bundesländer (federal states) send members.');
  });

  test('does not fire inside compounds like Bundestagswahl', () {
    expect(gloss('The Bundestagswahl takes place.'), 'The Bundestagswahl takes place.');
  });

  test('skips terms the text already explains in parentheses', () {
    const s = 'The Bundestag (parliament) meets in Berlin.';
    expect(gloss(s), s);
  });

  test('glosses multiple distinct terms in one text', () {
    expect(
      gloss('The Grundgesetz binds the Bundestag.'),
      "The Grundgesetz (Basic Law, Germany's constitution) binds the Bundestag (federal parliament).",
    );
  });

  test('null/empty safe', () {
    expect(gloss(null), '');
    expect(gloss(''), '');
  });
}
