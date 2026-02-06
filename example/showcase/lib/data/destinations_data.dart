import '../models/destination.dart';

/// Sample luxury travel destinations for showcase
///
/// This curated collection features diverse locations from around the world,
/// each with stunning imagery perfect for demonstrating glass morphism effects.
///
/// Note: Image assets should be replaced with actual high-quality photos
final List<Destination> sampleDestinations = [
  Destination(
    id: '1',
    name: 'Cliffside Villa Santorini',
    location: 'Santorini, Greece',
    description: 'Infinity pool overlooking the Aegean Sea',
    longDescription:
        'Experience unparalleled luxury in this stunning cliffside villa perched on the caldera. '
        'Wake up to breathtaking sunrises over the Aegean Sea, relax by your private infinity pool, '
        'and immerse yourself in the iconic white-washed architecture of Santorini.',
    pricePerNight: 850.0,
    rating: 4.9,
    reviewCount: 127,
    heroImage: 'assets/images/santorini_villa.jpg',
    galleryImages: [
      'assets/images/santorini_pool.jpg',
      'assets/images/santorini_interior.jpg',
      'assets/images/santorini_sunset.jpg',
    ],
    category: 'Beach',
    maxGuests: 6,
    bedrooms: 3,
    bathrooms: 3,
    amenities: [
      'Private Pool',
      'Ocean View',
      'Hot Tub',
      'Chef Available',
      'Concierge',
      'Beach Access'
    ],
    hostName: 'Elena Papadopoulos',
    hostAvatar: 'assets/images/host_elena.jpg',
  ),
  Destination(
    id: '2',
    name: 'Modern Mountain Chalet',
    location: 'Zermatt, Switzerland',
    description: 'Floor-to-ceiling windows with Matterhorn views',
    longDescription:
        'This architectural masterpiece combines contemporary luxury with alpine charm. '
        'Floor-to-ceiling windows frame the iconic Matterhorn, while the interior features '
        'sleek design, a private spa, and world-class amenities. Perfect for winter ski adventures '
        'or summer mountain retreats.',
    pricePerNight: 1250.0,
    rating: 5.0,
    reviewCount: 89,
    heroImage: 'assets/images/zermatt_chalet.jpg',
    galleryImages: [
      'assets/images/zermatt_living.jpg',
      'assets/images/zermatt_bedroom.jpg',
      'assets/images/zermatt_spa.jpg',
    ],
    category: 'Mountain',
    maxGuests: 8,
    bedrooms: 4,
    bathrooms: 4,
    amenities: [
      'Ski-in/Ski-out',
      'Private Spa',
      'Wine Cellar',
      'Fireplace',
      'Mountain View',
      'Heated Floors'
    ],
    hostName: 'Klaus Müller',
    hostAvatar: 'assets/images/host_klaus.jpg',
  ),
  Destination(
    id: '3',
    name: 'Desert Oasis Retreat',
    location: 'Marrakech, Morocco',
    description: 'Private riad with traditional hammam',
    longDescription:
        'Discover the magic of Morocco in this restored 19th-century riad. '
        'Hidden behind ancient walls lies a tranquil oasis featuring intricate tilework, '
        'lush gardens, a private hammam, and a rooftop terrace with panoramic views of '
        'the Atlas Mountains.',
    pricePerNight: 680.0,
    rating: 4.8,
    reviewCount: 156,
    heroImage: 'assets/images/marrakech_riad.jpg',
    galleryImages: [
      'assets/images/marrakech_courtyard.jpg',
      'assets/images/marrakech_hammam.jpg',
      'assets/images/marrakech_rooftop.jpg',
    ],
    category: 'Desert',
    maxGuests: 10,
    bedrooms: 5,
    bathrooms: 5,
    amenities: [
      'Private Hammam',
      'Rooftop Terrace',
      'Traditional Decor',
      'Chef Included',
      'Guided Tours',
      'Pool'
    ],
    hostName: 'Amina Benali',
    hostAvatar: 'assets/images/host_amina.jpg',
  ),
  Destination(
    id: '4',
    name: 'Overwater Bungalow Paradise',
    location: 'Bora Bora, French Polynesia',
    description: 'Glass floor panels reveal turquoise lagoon below',
    longDescription:
        'Your private overwater sanctuary awaits in the heart of the South Pacific. '
        'This luxurious bungalow features glass floor panels for lagoon viewing, '
        'direct ocean access, outdoor shower, and unobstructed views of Mount Otemanu. '
        'Paradise redefined.',
    pricePerNight: 1450.0,
    rating: 5.0,
    reviewCount: 203,
    heroImage: 'assets/images/borabora_bungalow.jpg',
    galleryImages: [
      'assets/images/borabora_deck.jpg',
      'assets/images/borabora_interior.jpg',
      'assets/images/borabora_sunset.jpg',
    ],
    category: 'Beach',
    maxGuests: 2,
    bedrooms: 1,
    bathrooms: 1,
    amenities: [
      'Ocean Access',
      'Glass Floor',
      'Private Deck',
      'Outdoor Shower',
      'Spa Services',
      'Kayaks Included'
    ],
    hostName: 'Teiva Dupont',
    hostAvatar: 'assets/images/host_teiva.jpg',
  ),
  Destination(
    id: '5',
    name: 'Manhattan Penthouse',
    location: 'New York City, USA',
    description: '360° skyline views from Central Park West',
    longDescription:
        'Live like royalty in this ultra-modern penthouse overlooking Central Park. '
        'Three-story glass walls offer panoramic views of the Manhattan skyline, '
        'while the interior showcases museum-quality art, a private cinema, '
        'and a chef\'s kitchen perfect for entertaining.',
    pricePerNight: 2100.0,
    rating: 4.9,
    reviewCount: 94,
    heroImage: 'assets/images/nyc_penthouse.jpg',
    galleryImages: [
      'assets/images/nyc_living.jpg',
      'assets/images/nyc_terrace.jpg',
      'assets/images/nyc_bedroom.jpg',
    ],
    category: 'City',
    maxGuests: 6,
    bedrooms: 3,
    bathrooms: 4,
    amenities: [
      'City Views',
      'Private Cinema',
      'Rooftop Terrace',
      'Concierge 24/7',
      'Gym Access',
      'Art Collection'
    ],
    hostName: 'Marcus Chen',
    hostAvatar: 'assets/images/host_marcus.jpg',
  ),
  Destination(
    id: '6',
    name: 'Rainforest Treehouse',
    location: 'Ubud, Bali',
    description: 'Suspended among ancient bamboo forests',
    longDescription:
        'Reconnect with nature in this architectural marvel suspended in the Balinese jungle. '
        'Bamboo construction, open-air design, and panoramic forest views create an '
        'unforgettable experience. Fall asleep to the sounds of the rainforest and wake '
        'up to monkeys playing in the canopy.',
    pricePerNight: 420.0,
    rating: 4.7,
    reviewCount: 178,
    heroImage: 'assets/images/bali_treehouse.jpg',
    galleryImages: [
      'assets/images/bali_deck.jpg',
      'assets/images/bali_bathroom.jpg',
      'assets/images/bali_pool.jpg',
    ],
    category: 'Jungle',
    maxGuests: 2,
    bedrooms: 1,
    bathrooms: 1,
    amenities: [
      'Jungle Views',
      'Outdoor Bath',
      'Infinity Pool',
      'Yoga Deck',
      'Breakfast Included',
      'Nature Tours'
    ],
    hostName: 'Made Suartika',
    hostAvatar: 'assets/images/host_made.jpg',
  ),
];
