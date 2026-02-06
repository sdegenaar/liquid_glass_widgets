import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import '../models/destination.dart';
import '../theme/showcase_glass_theme.dart';

/// Detail page showcasing a single destination with immersive imagery
///
/// Features hero transitions, parallax effects, and glass morphism overlays
/// that provide information without overwhelming the beautiful imagery.
class DetailPage extends StatefulWidget {
  final Destination destination;
  final bool isFavorite;
  final VoidCallback onFavoriteToggle;

  const DetailPage({
    super.key,
    required this.destination,
    required this.isFavorite,
    required this.onFavoriteToggle,
  });

  @override
  State<DetailPage> createState() => _DetailPageState();
}

class _DetailPageState extends State<DetailPage>
    with SingleTickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  double _scrollOffset = 0.0;
  int _selectedSegment = 0;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    );
    _fadeController.forward();
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  void _onScroll() {
    setState(() {
      _scrollOffset = _scrollController.offset;
    });
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarBrightness: Brightness.dark,
        statusBarIconBrightness: Brightness.light,
      ),
    );

    return Scaffold(
      backgroundColor: const Color(0xFF0A1929),
      body: Stack(
        children: [
          // Main scrollable content
          CustomScrollView(
            controller: _scrollController,
            slivers: [
              // Hero image with parallax effect
              SliverAppBar(
                expandedHeight: 500,
                pinned: false,
                backgroundColor: Colors.transparent,
                automaticallyImplyLeading: false,
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Parallax hero image
                      Transform.translate(
                        offset: Offset(0, _scrollOffset * 0.5),
                        child: Hero(
                          tag: 'destination_${widget.destination.id}',
                          child: Image.asset(
                            widget.destination.heroImage,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                decoration: const BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Color(0xFF4A90E2),
                                      Color(0xFF357ABD)
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      // Bottom gradient
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: Container(
                          height: 200,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.transparent,
                                const Color(0xFF0A1929).withValues(alpha: 0.9),
                              ],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Content
              SliverToBoxAdapter(
                child: Container(
                  color: const Color(0xFF0A1929),
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeader(),
                        const SizedBox(height: 24),
                        _buildSegmentedControl(),
                        const SizedBox(height: 24),
                        _buildSelectedContent(),
                        const SizedBox(height: 24),
                        _buildHostInfo(),
                        const SizedBox(height: 24),
                        _buildLocation(),
                        const SizedBox(height: 100),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),

          // Floating top bar with glass effect
          FadeTransition(
            opacity: _fadeAnimation,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: AdaptiveLiquidGlassLayer(
                  quality: ShowcaseGlassTheme.premiumQuality,
                  settings: ShowcaseGlassTheme.detailHeaderButtons,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GlassButton(
                        icon: Icons.arrow_back_ios_new,
                        iconSize: 20,
                        width: 44,
                        height: 44,
                        onTap: () => Navigator.pop(context),
                      ),
                      Row(
                        children: [
                          GlassButton(
                            icon: Icons.share_outlined,
                            iconSize: 22,
                            width: 44,
                            height: 44,
                            onTap: () {},
                          ),
                          const SizedBox(width: 12),
                          GlassButton(
                            icon: widget.isFavorite
                                ? Icons.favorite
                                : Icons.favorite_outline,
                            iconColor:
                                widget.isFavorite ? Colors.red : Colors.white,
                            iconSize: 22,
                            width: 44,
                            height: 44,
                            onTap: widget.onFavoriteToggle,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Floating booking button at bottom
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: GlassCard(
                    padding: const EdgeInsets.all(16),
                    shape: const LiquidRoundedSuperellipse(borderRadius: 20),
                    settings: ShowcaseGlassTheme.bookingCard,
                    child: Row(
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              'Price per night',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              '\$${widget.destination.pricePerNight.toStringAsFixed(0)}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        GlassButton(
                          icon: Icons.calendar_month,
                          label: 'Book Now',
                          iconSize: 20,
                          width: 44,
                          height: 44,
                          settings: ShowcaseGlassTheme.actionButton,
                          onTap: () => _showBookingDialog(),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF4A90E2).withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFF4A90E2).withValues(alpha: 0.3),
                ),
              ),
              child: Text(
                widget.destination.category,
                style: const TextStyle(
                  color: Color(0xFF4A90E2),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 12),
            const Icon(Icons.star, color: Colors.amber, size: 18),
            const SizedBox(width: 4),
            Text(
              '${widget.destination.rating}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              ' (${widget.destination.reviewCount} reviews)',
              style: const TextStyle(
                color: Colors.white60,
                fontSize: 14,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          widget.destination.name,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 32,
            fontWeight: FontWeight.w700,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            const Icon(
              Icons.location_on_outlined,
              color: Colors.white60,
              size: 18,
            ),
            const SizedBox(width: 4),
            Text(
              widget.destination.location,
              style: const TextStyle(
                color: Colors.white60,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSegmentedControl() {
    return GlassSegmentedControl(
      segments: const ['Overview', 'Amenities', 'Reviews'],
      selectedIndex: _selectedSegment,
      onSegmentSelected: (index) {
        setState(() {
          _selectedSegment = index;
        });
      },
      glassSettings: ShowcaseGlassTheme.segmentedControl,
    );
  }

  Widget _buildSelectedContent() {
    switch (_selectedSegment) {
      case 0:
        return _buildDescription();
      case 1:
        return _buildAmenities();
      case 2:
        return _buildReviews();
      default:
        return _buildDescription();
    }
  }

  Widget _buildDescription() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'About',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          widget.destination.longDescription,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 15,
            height: 1.6,
          ),
        ),
      ],
    );
  }

  Widget _buildReviews() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Guest Reviews',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 16),
        _buildReviewCard(
          'Sarah Johnson',
          5,
          'Absolutely stunning! The views were breathtaking and the service was impeccable.',
          '2 weeks ago',
        ),
        const SizedBox(height: 12),
        _buildReviewCard(
          'Michael Chen',
          5,
          'Perfect getaway. Every detail was thoughtfully considered.',
          '1 month ago',
        ),
        const SizedBox(height: 12),
        _buildReviewCard(
          'Emma Williams',
          4,
          'Beautiful location and amazing amenities. Would definitely return!',
          '2 months ago',
        ),
      ],
    );
  }

  Widget _buildReviewCard(String name, int rating, String review, String time) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: const Color(0xFF4A90E2),
                child: Text(
                  name[0],
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Row(
                      children: [
                        ...List.generate(
                          rating,
                          (index) => const Icon(
                            Icons.star,
                            color: Colors.amber,
                            size: 14,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          time,
                          style: const TextStyle(
                            color: Colors.white60,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            review,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAmenities() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Amenities',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: widget.destination.amenities.map((amenity) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.2),
                ),
              ),
              child: Text(
                amenity,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            _buildSpec(
                Icons.people_outline, '${widget.destination.maxGuests} guests'),
            const SizedBox(width: 16),
            _buildSpec(
                Icons.bed_outlined, '${widget.destination.bedrooms} beds'),
            const SizedBox(width: 16),
            _buildSpec(Icons.bathroom_outlined,
                '${widget.destination.bathrooms} baths'),
          ],
        ),
      ],
    );
  }

  Widget _buildSpec(IconData icon, String label) {
    return Row(
      children: [
        Icon(icon, color: Colors.white60, size: 18),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildHostInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: const Color(0xFF4A90E2),
            child: Text(
              widget.destination.hostName[0],
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Hosted by',
                  style: TextStyle(
                    color: Colors.white60,
                    fontSize: 12,
                  ),
                ),
                Text(
                  widget.destination.hostName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          GlassButton(
            icon: Icons.chat_bubble_outline,
            label: 'Contact',
            height: 40,
            width: 40,
            settings: ShowcaseGlassTheme.actionButton,
            onTap: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildLocation() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Location',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          height: 200,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.1),
            ),
          ),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.map_outlined,
                  color: Colors.white.withValues(alpha: 0.3),
                  size: 48,
                ),
                const SizedBox(height: 8),
                Text(
                  'Map view coming soon',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showBookingDialog() {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.7),
      builder: (context) => GlassDialog(
        title: 'Confirm Booking',
        settings: ShowcaseGlassTheme.dialog,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.destination.name,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.destination.location,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Total per night',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    '\$${widget.destination.pricePerNight.toStringAsFixed(0)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'You will receive a confirmation email once your booking is confirmed.',
              style: TextStyle(
                color: Colors.white60,
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ],
        ),
        actions: [
          GlassDialogAction(
            label: 'Cancel',
            onPressed: () => Navigator.pop(context),
          ),
          GlassDialogAction(
            label: 'Confirm',
            isPrimary: true,
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Booking confirmed!'),
                  backgroundColor: Color(0xFF4A90E2),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
