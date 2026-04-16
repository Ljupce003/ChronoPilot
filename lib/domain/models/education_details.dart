class EducationDetails {
  final String courseName;
  final String professor;
  final String room;
  final String studyProgramCode;

  EducationDetails({
    required this.courseName,
    required this.professor,
    required this.room,
    required this.studyProgramCode,
  });

  factory EducationDetails.fromJson(Map<String, dynamic> json) {
    return EducationDetails(
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
