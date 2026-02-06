/// A data model representing a luxury travel destination or unique stay
///
/// This class encapsulates all essential information about a destination,
/// including location details, pricing, descriptions, and imagery.
class Destination {
  /// Unique identifier for the destination
  final String id;

  /// The name/title of the destination
  final String name;

  /// The location (city, country or region)
  final String location;

  /// Brief description or tagline
  final String description;

  /// Longer detailed description
  final String longDescription;

  /// Price per night in USD
  final double pricePerNight;

  /// Rating out of 5.0
  final double rating;

  /// Number of reviews
  final int reviewCount;

  /// Asset path to the main hero image
  final String heroImage;

  /// List of additional gallery images
  final List<String> galleryImages;

  /// Destination category (e.g., 'Beach', 'Mountain', 'City', 'Desert')
  final String category;

  /// Number of guests the property can accommodate
  final int maxGuests;

  /// Number of bedrooms
  final int bedrooms;

  /// Number of bathrooms
  final int bathrooms;

  /// Key amenities/features
  final List<String> amenities;

  /// Host/property manager name
  final String hostName;

  /// Host avatar image path
  final String hostAvatar;

  /// Creates a new Destination instance
  Destination({
    required this.id,
    required this.name,
    required this.location,
    required this.description,
    required this.longDescription,
    required this.pricePerNight,
    required this.rating,
    required this.reviewCount,
    required this.heroImage,
    this.galleryImages = const [],
    required this.category,
    required this.maxGuests,
    required this.bedrooms,
    required this.bathrooms,
    this.amenities = const [],
    required this.hostName,
    required this.hostAvatar,
  });
}
