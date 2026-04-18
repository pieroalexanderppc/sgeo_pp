import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TutorialService {
  static final GlobalKey mapReportBtnKey = GlobalKey();
  static final GlobalKey mapFilterBtnKey = GlobalKey();
  static final ValueNotifier<String?> triggerTutorialNotifier = ValueNotifier<String?>(null);

  /// Intenta iniciar el tutorial verificando si es la primera vez.
  /// Se debe llamar desde la vista que contiene el widget.
  static Future<void> checkFirstTimeTutorial() async {
    final prefs = await SharedPreferences.getInstance();
    bool hasSeen = prefs.getBool('has_seen_map_tutorial') ?? false;
    
    if (!hasSeen) {
      triggerTutorial('all');
      await prefs.setBool('has_seen_map_tutorial', true);
    }
  }

  /// Forza el inicio del tutorial desde cualquier parte de la app
  static Future<void> forceStartTutorial(String tutorialType) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_seen_map_tutorial', true);
    triggerTutorial(tutorialType);
  }

  static void triggerTutorial(String tutorialType) {
    triggerTutorialNotifier.value = tutorialType;
    // Reseteamos rápidamente para permitir futuros triggers
    Future.delayed(const Duration(milliseconds: 500), () {
      triggerTutorialNotifier.value = null;
    });
  }
}
