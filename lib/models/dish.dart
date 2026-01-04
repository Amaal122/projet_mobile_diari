class Dish {
  final String name;
  final String price;
  final String cookName;
  final String cookerId; // Added for order tracking
  final double rating;
  final String location;
  final String imageAsset;

  Dish({
    required this.name,
    required this.price,
    required this.cookName,
    this.cookerId = '', // Default empty
    required this.rating,
    required this.location,
    required this.imageAsset,
  });
}
