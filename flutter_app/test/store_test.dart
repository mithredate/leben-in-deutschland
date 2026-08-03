// Round-trip tests for the store: the v1 export format must stay import-
// compatible with the PWA (app/composables/useStore.ts exportAll/importAll).
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:lid_trainer/models.dart';
import 'package:lid_trainer/store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<Store> freshStore([Map<String, Object> seed = const {}]) async {
    SharedPreferences.setMockInitialValues(seed);
    return Store.open();
  }

  test('sets the paid-upfront grandfather flag on first open', () async {
    SharedPreferences.setMockInitialValues({});
    await Store.open();
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool('lid.paidUpfront.v1'), isTrue);
  });

  test('imports a PWA v1 export losslessly', () async {
    final store = await freshStore();
    // shape produced by the PWA's exportAll()
    final pwaExport = jsonEncode({
      'version': 1,
      'exportedAt': '2026-08-03T10:00:00.000Z',
      'settings': {'state': 'BE', 'lang': 'en', 'examDate': '2026-08-08', 'theme': 'auto'},
      'progress': {
        'bfe5b39944': {'box': 4, 'due': 1900000000000, 'seen': 1, 'right': 1, 'wrong': 0},
        'bed6cebeba': {'box': 1, 'due': 1800000000000, 'seen': 3, 'right': 1, 'wrong': 2},
      },
      'stats': {
        'days': {
          '2026-08-01': {'answered': 30, 'correct': 25},
          '2026-08-02': {'answered': 12, 'correct': 12},
        }
      },
      'exams': [
        {'date': '2026-08-02T18:00:00.000Z', 'score': 28, 'total': 33, 'passedLid': true, 'passedEinb': true},
      ],
      'marked': ['bed6cebeba'],
    });

    store.importAll(pwaExport);

    expect(store.getSettings().state, 'BE');
    expect(store.getSettings().examDate, '2026-08-08');
    final p = store.getProgress();
    expect(p['bfe5b39944']!.box, 4);
    expect(p['bed6cebeba']!.wrong, 2);
    expect(store.getExams().single.score, 28);
    expect(store.getMarked(), {'bed6cebeba'});
  });

  test('export → import round-trips', () async {
    final store = await freshStore();
    store.patchSettings(state: 'BY', lang: 'de');
    store.setProgress({'x': ProgressEntry(box: 2, due: 123, seen: 1, right: 1)});
    store.toggleMarked('x');
    store.addExam(const ExamRecord(
        date: '2026-08-03T00:00:00.000Z', score: 20, total: 33, passedLid: true, passedEinb: true));

    final dump = store.exportAll();
    final decoded = jsonDecode(dump) as Map<String, dynamic>;
    expect(decoded['version'], 1);

    final store2 = await freshStore();
    store2.importAll(dump);
    expect(store2.getSettings().state, 'BY');
    expect(store2.getProgress()['x']!.box, 2);
    expect(store2.getMarked(), {'x'});
    expect(store2.getExams().single.score, 20);
  });

  test('rejects unknown export versions', () async {
    final store = await freshStore();
    expect(() => store.importAll('{"version": 2}'), throwsFormatException);
    expect(() => store.importAll('[]'), throwsFormatException);
  });

  test('streak counts consecutive days and tolerates an untouched today', () async {
    final store = await freshStore();
    String day(int daysAgo) =>
        DateTime.now().toUtc().subtract(Duration(days: daysAgo)).toIso8601String().substring(0, 10);
    store.importAll(jsonEncode({
      'version': 1,
      'stats': {
        'days': {
          day(1): {'answered': 5, 'correct': 5},
          day(2): {'answered': 5, 'correct': 4},
        }
      },
    }));
    // nothing answered today yet — streak kept alive from yesterday
    expect(store.streak(), 2);
    store.recordAnswer(true);
    expect(store.streak(), 3);
  });
}
