class Timetable {
  final int? id;
  final String subject;
  final String day;
  final String time;

  Timetable(
      {this.id, required this.subject, required this.day, required this.time});

  Map<String, dynamic> toMap() {
    return {'id': id, 'subject': subject, 'day': day, 'time': time};
  }

  factory Timetable.fromMap(Map<String, dynamic> map) {
    return Timetable(
      id: map['id'],
      subject: map['subject'],
      day: map['day'],
      time: map['time'],
    );
  }
}
