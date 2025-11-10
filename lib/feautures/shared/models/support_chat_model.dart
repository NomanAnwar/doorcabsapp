class Message {
  final String text;
  final bool isUser;
  final String avatar; // profile picture path
  final String? name;  // for showing agent name/role if needed

  Message({
    required this.text,
    required this.isUser,
    required this.avatar,
    this.name,
  });
}
