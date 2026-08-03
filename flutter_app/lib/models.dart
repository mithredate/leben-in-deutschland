// Data models — field names and JSON shapes are IDENTICAL to the PWA
// (app/composables/useQuestions.ts + useStore.ts) so progress exports
// migrate losslessly between web and app.

class QuestionEn {
  final String? question;
  final List<String?> answers;
  final String? explanation;

  const QuestionEn({this.question, this.answers = const [], this.explanation});

  factory QuestionEn.fromJson(Map<String, dynamic>? j) {
    if (j == null) return const QuestionEn();
    return QuestionEn(
      question: j['question'] as String?,
      answers: (j['answers'] as List? ?? []).map((a) => a as String?).toList(),
      explanation: j['explanation'] as String?,
    );
  }
}

class QuestionSrc {
  final String t;
  final String u;
  const QuestionSrc({required this.t, required this.u});

  static QuestionSrc? fromJson(Map<String, dynamic>? j) {
    if (j == null || j['u'] == null) return null;
    return QuestionSrc(t: (j['t'] as String?) ?? '', u: j['u'] as String);
  }
}

class Question {
  final String id;
  final String num;
  final String? state;
  final String category;
  final String question;
  final List<String> answers;
  final int correct;
  final String? image;
  final QuestionEn en;
  final String? explanationDe;
  final QuestionSrc? src;

  const Question({
    required this.id,
    required this.num,
    required this.state,
    required this.category,
    required this.question,
    required this.answers,
    required this.correct,
    required this.image,
    required this.en,
    required this.explanationDe,
    required this.src,
  });

  factory Question.fromJson(Map<String, dynamic> j) => Question(
        id: j['id'] as String,
        num: j['num'] as String,
        state: j['state'] as String?,
        category: j['category'] as String,
        question: j['question'] as String,
        answers: (j['answers'] as List).cast<String>(),
        correct: j['correct'] as int,
        image: j['image'] as String?,
        en: QuestionEn.fromJson(j['en'] as Map<String, dynamic>?),
        explanationDe: j['explanation_de'] as String?,
        src: QuestionSrc.fromJson(j['src'] as Map<String, dynamic>?),
      );
}

class ProgressEntry {
  int box;
  int due; // epoch ms, like Date.now()
  int seen;
  int right;
  int wrong;

  ProgressEntry({this.box = 0, this.due = 0, this.seen = 0, this.right = 0, this.wrong = 0});

  factory ProgressEntry.fromJson(Map<String, dynamic> j) => ProgressEntry(
        box: (j['box'] as num?)?.toInt() ?? 0,
        due: (j['due'] as num?)?.toInt() ?? 0,
        seen: (j['seen'] as num?)?.toInt() ?? 0,
        right: (j['right'] as num?)?.toInt() ?? 0,
        wrong: (j['wrong'] as num?)?.toInt() ?? 0,
      );

  Map<String, dynamic> toJson() => {'box': box, 'due': due, 'seen': seen, 'right': right, 'wrong': wrong};
}

class Settings {
  String? state;
  String lang; // 'en' | 'de'
  String examDate; // yyyy-MM-dd
  String theme; // 'auto' | 'light' | 'dark'

  Settings({this.state, this.lang = 'en', required this.examDate, this.theme = 'auto'});

  factory Settings.fromJson(Map<String, dynamic> j) => Settings(
        state: j['state'] as String?,
        lang: (j['lang'] as String?) ?? 'en',
        examDate: (j['examDate'] as String?) ?? defaultExamDate(),
        theme: (j['theme'] as String?) ?? 'auto',
      );

  Map<String, dynamic> toJson() => {'state': state, 'lang': lang, 'examDate': examDate, 'theme': theme};

  static String defaultExamDate() =>
      DateTime.now().add(const Duration(days: 14)).toIso8601String().substring(0, 10);
}

class ExamRecord {
  final String date; // ISO string
  final int score;
  final int total;
  final bool passedLid;
  final bool passedEinb;

  const ExamRecord({
    required this.date,
    required this.score,
    required this.total,
    required this.passedLid,
    required this.passedEinb,
  });

  factory ExamRecord.fromJson(Map<String, dynamic> j) => ExamRecord(
        date: j['date'] as String,
        score: (j['score'] as num).toInt(),
        total: (j['total'] as num).toInt(),
        passedLid: j['passedLid'] as bool? ?? false,
        passedEinb: j['passedEinb'] as bool? ?? false,
      );

  Map<String, dynamic> toJson() =>
      {'date': date, 'score': score, 'total': total, 'passedLid': passedLid, 'passedEinb': passedEinb};
}

const Map<String, String> kStates = {
  'BW': 'Baden-Württemberg', 'BY': 'Bayern', 'BE': 'Berlin', 'BB': 'Brandenburg',
  'HB': 'Bremen', 'HH': 'Hamburg', 'HE': 'Hessen', 'MV': 'Mecklenburg-Vorpommern',
  'NI': 'Niedersachsen', 'NW': 'Nordrhein-Westfalen', 'RP': 'Rheinland-Pfalz',
  'SL': 'Saarland', 'SN': 'Sachsen', 'ST': 'Sachsen-Anhalt',
  'SH': 'Schleswig-Holstein', 'TH': 'Thüringen',
};

const int kPassLid = 15;
const int kPassEinbuergerung = 17;
