import 'package:flutter/material.dart';

// One GlobalKey per showcase step.
// These are static so they can be referenced from anywhere.
class TutorialKeys {
  TutorialKeys._();

  static const String scope = 'taskie_app_tour';

  static final profile = GlobalKey();
  static final searchIcon = GlobalKey();
  static final filterTabs = GlobalKey();
  static final taskList = GlobalKey();
  static final addTask = GlobalKey();
  static final archive = GlobalKey();
  static final appNavigation = GlobalKey();

  static final categoriesList = GlobalKey();
  static final addCategory = GlobalKey();

  static final scheduleDays = GlobalKey();
  static final scheduleList = GlobalKey();
  static final addSchedule = GlobalKey();

  static final progressRing = GlobalKey();
  static final progressSummary = GlobalKey();

  static List<GlobalKey> get appTourSteps => [
    profile,
    searchIcon,
    filterTabs,
    taskList,
    addTask,
    archive,
    appNavigation,
    categoriesList,
    addCategory,
    scheduleDays,
    scheduleList,
    addSchedule,
    progressRing,
    progressSummary,
  ];

  static int? tabFor(GlobalKey key) {
    if (key == categoriesList || key == addCategory) return 1;
    if (key == scheduleDays || key == scheduleList || key == addSchedule) {
      return 2;
    }
    if (key == progressRing || key == progressSummary) return 3;
    if (key == profile ||
        key == searchIcon ||
        key == filterTabs ||
        key == taskList ||
        key == addTask ||
        key == archive ||
        key == appNavigation) {
      return 0;
    }
    return null;
  }
}
