/// Additional metadata for education/class events.
class EducationDetails {
  final String courseName;
  final String professor;
  final String room;
  final String studyProgramCode;

  /// Creates the education details payload.
  EducationDetails({
    required this.courseName,
    required this.professor,
    required this.room,
    required this.studyProgramCode,
  });

  /// Creates an education details payload from JSON.
  factory EducationDetails.fromJson(Map<String, dynamic> json) {
    return EducationDetails(
      courseName: json['courseName'],
      professor: json['professor'],
      room: json['room'],
      studyProgramCode: json['studyProgramCode'],
    );
  }

  /// Serializes the education details to JSON.
  Map<String, dynamic> toJson() {
    return {
      'courseName': courseName,
      'professor': professor,
      'room': room,
      'studyProgramCode': studyProgramCode,
    };
  }
}
