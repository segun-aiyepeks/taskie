# Taskie home screen widgets

In Taskie, open your profile, then **Settings → Home screen widgets**. Choose
**Next task** or **Next schedule**, then accept the launcher's placement prompt.
Alternatively, touch and hold the Android home screen, choose **Widgets**, and
find **Taskie: Next task** or **Taskie: Next schedule**. Removing a widget from
the home screen does not remove any tasks or schedules.

- **Next task** shows the earliest unfinished task with a due time at or after
  the current time. Completed tasks, past reminder times and undated tasks are
  excluded. A task with a past reminder stays Pending in the app until its
  scheduled day ends; the widget moves on to the next upcoming reminder.
- **Next schedule** shows the next start across every selected repeat day,
  whether or not that entry's alarm is enabled. An entry that has started is
  replaced by the next upcoming start, including the following week.
- Tap a task to open its details; tap a schedule to open its weekday in Schedule.
  The refresh button recalculates the next item without opening Flutter.

Android stores a private snapshot updated from both database streams. Native
providers choose the next item when Taskie is closed. Updates run at item times,
midnight, reboot, clock/timezone changes and the launcher's periodic refresh.
Existing exact-alarm access is used if available; without it, Android can batch
updates. The widgets themselves do not request notification or exact-alarm access.

The launcher controls placement approval. A successful pin request means the
prompt was accepted by the launcher; installation is checked separately.

## Verification

- Flutter: `flutter test test/home_widgets_test.dart test/task_archive_test.dart`
- Android selection logic: `gradlew :app:testDebugUnitTest`
- Native resources and host: `flutter build apk --debug`
- On a phone: place both widgets, complete/delete the displayed task, advance
  through a scheduled time with Taskie closed, tap each widget, resize it, and
  check the appearance after a reboot and a time-zone change.

## Platform references

- [Android widget pinning](https://developer.android.com/reference/android/appwidget/AppWidgetManager)
- [Widget update timing](https://developer.android.com/develop/ui/views/appwidgets/advanced)
- [Widget sizing and layouts](https://developer.android.com/develop/ui/views/appwidgets/layouts)
