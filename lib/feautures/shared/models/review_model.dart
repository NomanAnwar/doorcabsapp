class Review {
  final String name;
  final String date;
  final double rating;
  final String comment;
  final String imageUrl;
  final List<String> ratingTags;

  Review({
    required this.name,
    required this.date,
    required this.rating,
    required this.comment,
    required this.imageUrl,
    required this.ratingTags,
  });

  factory Review.fromJson(Map<String, dynamic> json) {
    final nameData = json['rated_by_name'] ?? {};
    final firstName = nameData['firstName'] ?? '';
    final lastName = nameData['lastName'] ?? '';
    final fullName = '$firstName $lastName'.trim();

    // Format date from "2025-11-20T13:09:43.785Z" to "20/11/2025"
    final rawDate = json['date'] ?? '';
    String formattedDate = '';
    try {
      if (rawDate.isNotEmpty) {
        final dateTime = DateTime.parse(rawDate);
        formattedDate = '${dateTime.day.toString().padLeft(2, '0')}/${dateTime.month.toString().padLeft(2, '0')}/${dateTime.year}';
      }
    } catch (e) {
      formattedDate = 'Unknown date';
    }

    return Review(
      name: fullName.isNotEmpty ? fullName : 'Anonymous',
      date: formattedDate,
      rating: (json['rating'] ?? 0).toDouble(),
      comment: json['comments'] ?? '',
      imageUrl: 'https://i.pravatar.cc/150?img=${(fullName.hashCode % 70).abs()}',
      ratingTags: List<String>.from(json['rating_tags'] ?? []),
    );
  }
}