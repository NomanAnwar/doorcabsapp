class RideType {
  final String title;
  final String image; // can be base64 or asset path
  final bool isBase64; // flag to check if it’s base64

  RideType(this.title, this.image, {this.isBase64 = false});
}