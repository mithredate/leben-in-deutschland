// App-wide state: the question catalog + the persisted store. Mirrors the
// PWA's useApp/useQuestions composables. Store is a ChangeNotifier; widgets
// that show progress-derived data listen to it.
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'models.dart';
import 'store.dart';

class AppState {
  AppState._(this.store, this.questions);

  final Store store;
  final List<Question> questions;

  static AppState? _instance;
  static AppState get I => _instance!;

  static Future<AppState> init() async {
    final store = await Store.open();
    final raw = await rootBundle.loadString('assets/data/questions.json');
    final questions =
        (jsonDecode(raw) as List).map((j) => Question.fromJson(j as Map<String, dynamic>)).toList();
    return _instance = AppState._(store, questions);
  }

  Settings get settings => store.getSettings();

  /// General catalog + the questions of the selected Bundesland.
  List<Question> get pool {
    final state = settings.state;
    return questions.where((q) => q.state == null || q.state == state).toList();
  }
}

void showToast(BuildContext context, String message) {
  final messenger = ScaffoldMessenger.maybeOf(context);
  if (messenger == null) return;
  messenger.hideCurrentSnackBar();
  messenger.showSnackBar(SnackBar(
    content: Text(message, textAlign: TextAlign.center),
    behavior: SnackBarBehavior.floating,
    duration: const Duration(milliseconds: 2200),
    margin: const EdgeInsets.only(bottom: 80, left: 40, right: 40),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  ));
}
