// Testtrainer „Leben in Deutschland" — Flutter port of the PWA at
// https://mithredate.com/leben-in-deutschland/. Logic and storage formats
// are kept 1:1 with the web app (see ../app/composables/).
import 'package:flutter/material.dart';

import 'app_state.dart';
import 'models.dart';
import 'screens/browse_tab.dart';
import 'screens/exam_screen.dart';
import 'screens/exam_tab.dart';
import 'screens/home_tab.dart';
import 'screens/more_tab.dart';
import 'screens/onboarding_screen.dart';
import 'screens/study_screen.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppState.init();
  runApp(const LidApp());
}

class LidApp extends StatelessWidget {
  const LidApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppState.I.store,
      builder: (context, _) {
        final theme = AppState.I.settings.theme;
        return MaterialApp(
          title: 'Leben in Deutschland',
          debugShowCheckedModeBanner: false,
          theme: buildTheme(Brightness.light),
          darkTheme: buildTheme(Brightness.dark),
          themeMode: switch (theme) {
            'light' => ThemeMode.light,
            'dark' => ThemeMode.dark,
            _ => ThemeMode.system,
          },
          home: const Shell(),
        );
      },
    );
  }
}

class Shell extends StatefulWidget {
  const Shell({super.key});

  @override
  State<Shell> createState() => _ShellState();
}

class _ShellState extends State<Shell> {
  int tab = 0;
  bool onboarding = false;

  @override
  void initState() {
    super.initState();
    onboarding = AppState.I.settings.state == null;
  }

  void _startStudy([List<Question>? list]) {
    Navigator.of(context).push(MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => StudyScreen(list: list),
    ));
  }

  void _startExam() {
    Navigator.of(context).push(MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => ExamScreen(onDrill: (qs) => _startStudy(qs)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    if (onboarding) {
      return OnboardingScreen(onDone: () => setState(() => onboarding = false));
    }
    return Scaffold(
      backgroundColor: c.paper,
      body: SafeArea(
        bottom: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 620),
            child: switch (tab) {
              1 => BrowseTab(onPractice: _startStudy),
              2 => ExamTab(onStart: _startExam),
              3 => const MoreTab(),
              _ => HomeTab(onStudy: _startStudy, onExam: _startExam),
            },
          ),
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: c.card,
          border: Border(top: BorderSide(color: c.line)),
        ),
        child: NavigationBar(
          selectedIndex: tab,
          onDestinationSelected: (i) => setState(() => tab = i),
          backgroundColor: Colors.transparent,
          indicatorColor: Colors.transparent,
          height: 64,
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          destinations: [
            _dest(c, '◈', 'Heute', tab == 0),
            _dest(c, '≣', 'Fragen', tab == 1),
            _dest(c, '◷', 'Test', tab == 2),
            _dest(c, '⋯', 'Mehr', tab == 3),
          ],
        ),
      ),
    );
  }

  NavigationDestination _dest(AppColors c, String ico, String label, bool active) =>
      NavigationDestination(
        icon: Text(ico,
            style: TextStyle(fontSize: 20, height: 1, color: active ? c.red : c.muted)),
        label: label,
      );
}
