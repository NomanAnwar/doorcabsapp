class VehicleImagesStep {
  final String title;
  final String description;
  final String imagePath;
  final int stepNumber;
  final double width;
  final double height;

  VehicleImagesStep({
    required this.title,
    required this.description,
    required this.imagePath,
    required this.stepNumber,
    double? width,
    double? height,
  })  : width = width ?? 380,
        height = height ?? 285;
}
