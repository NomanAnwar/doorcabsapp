class RideOption {
  final String id;
  final String name;
  final String imageAsset;
  final String subtitle;
  final String description;
  final String fare;
  final int initialPassengers;
  final int minPassengers;
  final int maxPassengers;
  final int initialFare;
  final String categoryIcon;
  final bool isBase64Image;
  final Map<String, dynamic>? apiData; // ✅ ADDED: For fare calculation

  RideOption({
    required this.id,
    required this.name,
    required this.imageAsset,
    required this.subtitle,
    required this.description,
    required this.fare,
    required this.initialPassengers,
    required this.minPassengers,
    required this.maxPassengers,
    required this.initialFare,
    this.categoryIcon = "",
    this.isBase64Image = false,
    this.apiData, // ✅ ADDED
  });

  // ✅ ADDED: CopyWith method for updating fare and subtitle
  RideOption copyWith({
    String? fare,
    String? subtitle,
  }) {
    return RideOption(
      id: id,
      name: name,
      imageAsset: imageAsset,
      subtitle: subtitle ?? this.subtitle,
      description: description,
      fare: fare ?? this.fare,
      initialPassengers: initialPassengers,
      minPassengers: minPassengers,
      maxPassengers: maxPassengers,
      initialFare: initialFare,
      categoryIcon: categoryIcon,
      isBase64Image: isBase64Image,
      apiData: apiData,
    );
  }
}