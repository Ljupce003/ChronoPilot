class LectureDetails {
  final String courseName;
  final String professor;
  final String room;
  final String studyProgramCode;

  LectureDetails({
    required this.courseName,
    required this.professor,
    required this.room,
    required this.studyProgramCode,
  });

  factory LectureDetails.fromJson(Map<String, dynamic> json) {
    return LectureDetails(
      courseName: json['courseName'],
      professor: json['professor'],
      room: json['room'],
      studyProgramCode: json['studyProgramCode'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'courseName': courseName,
      'professor': professor,
      'room': room,
      'studyProgramCode': studyProgramCode,
    };
  }
}
