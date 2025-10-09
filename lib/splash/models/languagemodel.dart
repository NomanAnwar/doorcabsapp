class LanguageModel {
  final String language;
  final String flag;

  LanguageModel({
    required this.language,
    required this.flag,
  });

  factory LanguageModel.fromJson(Map<String, dynamic> json) {
    return LanguageModel(
      language: json['language'] ?? '',
      flag: json['flag'] ?? '',
    );
  }

  // ✅ ADDED: Missing toJson method
  Map<String, dynamic> toJson() {
    return {
      'language': language,
      'flag': flag,
    };
  }
}



// class LanguageModel {
//   final String language;
//   final String flag;
//
//   LanguageModel({
//     required this.language,
//     required this.flag,
//   });
//
//   factory LanguageModel.fromJson(Map<String, dynamic> json) {
//     return LanguageModel(
//       language: json['language'] ?? '',
//       flag: json['flag'] ?? '',
//     );
//   }
// }
