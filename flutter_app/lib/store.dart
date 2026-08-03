// Persistence — SharedPreferences with the SAME keys and JSON shapes as the
// PWA's localStorage (app/composables/useStore.ts), so exports from the web
// app import losslessly here and vice versa.
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'models.dart';

class _K {
  static const settings = 'lid.settings.v1';
  static const progress = 'lid.progress.v1';
  static const stats = 'lid.stats.v1';
  static const exams = 'lid.exams.v1';
  static const marked = 'lid.marked.v1';
  static const lastSaved = 'lid.lastSaved.v1';
  // Set on every launch while the app is sold paid-upfront. If the app later
  // switches to free + IAP, this flag grandfathers early buyers.
  static const paidUpfront = 'lid.paidUpfront.v1';
}

class Store extends ChangeNotifier {
  Store(this._prefs) {
    _prefs.setBool(_K.paidUpfront, true);
  }

  final SharedPreferences _prefs;

  static Future<Store> open() async => Store(await SharedPreferences.getInstance());

  T _read<T>(String key, T Function(dynamic) parse, T fallback) {
    final raw = _prefs.getString(key);
    if (raw == null) return fallback;
    try {
      return parse(jsonDecode(raw));
    } catch (_) {
      return fallback;
    }
  }

  void _write(String key, Object? value) {
    _prefs.setString(key, jsonEncode(value));
    _prefs.setString(_K.lastSaved, jsonEncode(DateTime.now().millisecondsSinceEpoch));
    notifyListeners();
  }

  // ---- settings ----

  Settings getSettings() => _read(
        _K.settings,
        (j) => Settings.fromJson(j as Map<String, dynamic>),
        Settings(examDate: Settings.defaultExamDate()),
      );

  void patchSettings({String? state, String? lang, String? examDate, String? theme}) {
    final s = getSettings();
    if (state != null) s.state = state;
    if (lang != null) s.lang = lang;
    if (examDate != null) s.examDate = examDate;
    if (theme != null) s.theme = theme;
    _write(_K.settings, s.toJson());
  }

  // ---- progress ----

  Map<String, ProgressEntry> getProgress() => _read(
        _K.progress,
        (j) => (j as Map<String, dynamic>)
            .map((k, v) => MapEntry(k, ProgressEntry.fromJson(v as Map<String, dynamic>))),
        <String, ProgressEntry>{},
      );

  void setProgress(Map<String, ProgressEntry> p) =>
      _write(_K.progress, p.map((k, v) => MapEntry(k, v.toJson())));

  // ---- daily stats / streak ----

  Map<String, dynamic> _getStatsRaw() => _read(
        _K.stats,
        (j) => (j as Map<String, dynamic>),
        <String, dynamic>{'days': <String, dynamic>{}},
      );

  // UTC like the PWA's `toISOString().slice(0, 10)` — keys must match exactly
  // or imported streaks/day counts split across two dates near midnight.
  static String _dayKey(DateTime d) => d.toUtc().toIso8601String().substring(0, 10);

  void recordAnswer(bool correct) {
    final stats = _getStatsRaw();
    final days = (stats['days'] as Map<String, dynamic>? ?? {});
    final day = _dayKey(DateTime.now());
    final d = (days[day] as Map<String, dynamic>? ?? {'answered': 0, 'correct': 0});
    d['answered'] = (d['answered'] as num).toInt() + 1;
    if (correct) d['correct'] = (d['correct'] as num).toInt() + 1;
    days[day] = d;
    stats['days'] = days;
    _write(_K.stats, stats);
  }

  int answeredToday() {
    final days = (_getStatsRaw()['days'] as Map<String, dynamic>? ?? {});
    final d = days[_dayKey(DateTime.now())] as Map<String, dynamic>?;
    return ((d?['answered'] as num?) ?? 0).toInt();
  }

  int streak() {
    final days = (_getStatsRaw()['days'] as Map<String, dynamic>? ?? {});
    int answered(String key) =>
        (((days[key] as Map<String, dynamic>?)?['answered'] as num?) ?? 0).toInt();
    var n = 0;
    var d = DateTime.now();
    // today may still be untouched; a streak kept alive until yesterday counts
    if (answered(_dayKey(d)) == 0) d = d.subtract(const Duration(days: 1));
    while (answered(_dayKey(d)) > 0) {
      n += 1;
      d = d.subtract(const Duration(days: 1));
    }
    return n;
  }

  // ---- exams ----

  List<ExamRecord> getExams() => _read(
        _K.exams,
        (j) => (j as List).map((e) => ExamRecord.fromJson(e as Map<String, dynamic>)).toList(),
        <ExamRecord>[],
      );

  void addExam(ExamRecord e) =>
      _write(_K.exams, [...getExams().map((x) => x.toJson()), e.toJson()]);

  // ---- manually bookmarked ("difficult") questions ----

  Set<String> getMarked() => _read(
        _K.marked,
        (j) => (j as List).cast<String>().toSet(),
        <String>{},
      );

  bool toggleMarked(String id) {
    final s = getMarked();
    final nowMarked = !s.contains(id);
    if (nowMarked) {
      s.add(id);
    } else {
      s.remove(id);
    }
    _write(_K.marked, s.toList());
    return nowMarked;
  }

  // ---- export / import (format identical to the PWA, version 1) ----

  String exportAll() => jsonEncode({
        'version': 1,
        'exportedAt': DateTime.now().toUtc().toIso8601String(),
        'settings': getSettings().toJson(),
        'progress': getProgress().map((k, v) => MapEntry(k, v.toJson())),
        'stats': _getStatsRaw(),
        'exams': getExams().map((e) => e.toJson()).toList(),
        'marked': getMarked().toList(),
      });

  void importAll(String json) {
    final data = jsonDecode(json);
    if (data is! Map<String, dynamic> || data['version'] != 1) {
      throw const FormatException('Unbekanntes Format');
    }
    if (data['settings'] != null) _write(_K.settings, data['settings']);
    if (data['progress'] != null) _write(_K.progress, data['progress']);
    if (data['stats'] != null) _write(_K.stats, data['stats']);
    if (data['exams'] != null) _write(_K.exams, data['exams']);
    if (data['marked'] != null) _write(_K.marked, data['marked']);
  }

  void resetProgress() {
    _prefs.remove(_K.progress);
    _prefs.remove(_K.stats);
    _prefs.remove(_K.exams);
    _prefs.remove(_K.marked);
    notifyListeners();
  }

  ({int seen, int? lastSaved}) storageHealth() {
    final seen = getProgress().values.where((e) => e.seen > 0).length;
    final lastSaved = _read<int?>(_K.lastSaved, (j) => (j as num).toInt(), null);
    return (seen: seen, lastSaved: lastSaved);
  }
}
