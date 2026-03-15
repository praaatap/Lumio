class TaskModel {
  TaskModel({
    required this.id,
    required this.title,
    required this.startTime,
    required this.durationMinutes,
    this.withAlarm = false,
  });

  final String id;
  final String title;
  final String startTime;
  final int durationMinutes;
  bool withAlarm;
}
