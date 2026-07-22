import 'package:flutter/material.dart';

// One GlobalKey per showcase step.
// These are static so they can be referenced from anywhere.
class TutorialKeys {
  TutorialKeys._();

  static final addTask    = GlobalKey();
  static final filterTabs = GlobalKey();
  static final searchIcon = GlobalKey();
  static final taskCard   = GlobalKey();
  static final scheduleTab = GlobalKey();
}