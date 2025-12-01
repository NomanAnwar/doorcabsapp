class FAQ {
  final String id;
  final String question;
  final String answer;
  bool isExpanded;

  FAQ({
    required this.id,
    required this.question,
    required this.answer,
    this.isExpanded = false,
  });
}