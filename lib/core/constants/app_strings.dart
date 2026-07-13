class AppStrings {
  AppStrings._();

  static const String appName = 'Taskie';
  static const String tagLine = 'Your day, Organized';

  //Onboarding
  static const String ob1Title = 'Stay on Top of Everything';
  static const String ob1Sub = 'Create tasks, set priorities and never miss a deadline';
  static const String ob2Title = 'Organised by Category';
  static const String ob2Sub = 'Keep work, personal and study tasks cleanly seperated';
  static const String ob3Title = 'Yours, Forever Offline';
  static const String ob3Sub = 'No Account, No Internet, Your Data lives on your device';
  static const String getStarted = 'Get Started';

  //Screen Titles
  static const String homeTitle = "My Tasks";
  static const String todayTitle = "Today";
  static const String categoriesTitle = "Categories";
  static const String statsTitle = "Progress";
  static const String settingsTitle = "Settings";

  //Task Actions
  static const String addTask = 'New Task';
  static const String editTask = 'Edit Task';
  static const String deleteTask = 'Delete Task';
  static const String save = 'Save';
  static const String cancel = 'Cancel';
  static const String delete = 'Delete';

  //Priority Labels
  static const String priorityHigh = 'High';
  static const String priorityMedium = 'Medium';
  static const String priorityLow = 'Low';

  //Empty States
  static const String emptyTitle = 'All Clear!';
  static const String emptySub = 'No tasks here, tap + to add one';
  static const String emptyToday = 'Nothing due today';
  static const String emptyTodaySub = 'Add a Task and set today as the due date';

  //Validation
  static const String titleRequired = 'Please give your task a title';
  static const String genericError = 'Something went wrong. Try Again';

  //Confirmation Dialogs
  static const String deleteConfirmTitle = 'Delete this task?';
  static const String deleteConfirmMessage = 'This cannot be undone';
  static const String confirmDelete = 'Yes, delete';

  //Personalization Settings
  static const String onboardingNameTitle = 'What should we call you?';
  static const String onboardingNameSub = "We'll use this to personalize your experience.";
  static const String nameHint = 'Enter your name';
  static const String skip = 'Skip';

  //Developer Credit
  static const String developerCredit = 'Developed by Aiyepeks';

  //Search
  static const String searchHint = 'Search Tasks....';
  static const String noResultsTitle = 'No matching tasks';

  // Notifications
  static const String notifChannelId   = 'taskie_reminders';
  static const String notifChannelName = 'Task Reminders';
  static const String notifChannelDesc = 'Reminders for tasks with due dates';
  static const String notifBody        = 'This task is due today.';
}
