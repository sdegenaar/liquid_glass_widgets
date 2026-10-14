import 'package:flutter/cupertino.dart';
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

    return GlassScaffold(
      backgroundColor: Color(0xFF0A1929),
      body: Stack(
        children: [
          // Main scrollable content
          CustomScrollView(
            controller: _scrollController,
            slivers: [
              // Hero image with parallax effect
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 500,
                  child: Stack(
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
                                decoration: BoxDecoration(
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
                                Color(0x00000000),
                                Color(0xFF0A1929).withValues(alpha: 0.9),
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
                  color: Color(0xFF0A1929),
                  child: Padding(
                    padding: EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeader(),
                        SizedBox(height: 24),
                        _buildSegmentedControl(),
                        SizedBox(height: 24),
                        _buildSelectedContent(),
                        SizedBox(height: 24),
                        _buildHostInfo(),
                        SizedBox(height: 24),
                        _buildLocation(),
                        SizedBox(height: 100),
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
                padding: EdgeInsets.all(16.0),
                child: AdaptiveLiquidGlassLayer(
                  quality: ShowcaseGlassTheme.premiumQuality,
                  settings: ShowcaseGlassTheme.detailHeaderButtons,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GlassButton(
                        icon: Icon(CupertinoIcons.back),
                        iconSize: 20,
                        width: 44,
                        height: 44,
                        onTap: () => Navigator.pop(context),
                      ),
                      Row(
                        children: [
                          GlassButton(
                            icon: Icon(CupertinoIcons.share),
                            iconSize: 22,
                            width: 44,
                            height: 44,
                            onTap: () {},
                          ),
                          SizedBox(width: 12),
                          GlassButton(
                            icon: Icon(widget.isFavorite
                                ? CupertinoIcons.heart_fill
                                : CupertinoIcons.heart),
                            iconColor: widget.isFavorite
                                ? CupertinoColors.systemRed
                                : CupertinoColors.white,
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
                  padding: EdgeInsets.all(20.0),
                  child: GlassContainer.card(
                    padding: EdgeInsets.all(16),
                    shape: const LiquidRoundedSuperellipse(borderRadius: 20),
                    settings: ShowcaseGlassTheme.bookingCard,
                    child: Row(
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Price per night',
                              style: TextStyle(
                                color: CupertinoColors.white
                                    .withValues(alpha: 0.70),
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              '\$${widget.destination.pricePerNight.toStringAsFixed(0)}',
                              style: TextStyle(
                                color: CupertinoColors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        GlassButton(
                          icon: Icon(CupertinoIcons.calendar),
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
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Color(0xFF4A90E2).withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Color(0xFF4A90E2).withValues(alpha: 0.3),
                ),
              ),
              child: Text(
                widget.destination.category,
                style: TextStyle(
                  color: Color(0xFF4A90E2),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            SizedBox(width: 12),
            Icon(CupertinoIcons.star,
                color: CupertinoColors.activeOrange, size: 18),
            SizedBox(width: 4),
            Text(
              '${widget.destination.rating}',
              style: TextStyle(
                color: CupertinoColors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              ' (${widget.destination.reviewCount} reviews)',
              style: TextStyle(
                color: CupertinoColors.white.withValues(alpha: 0.60),
                fontSize: 14,
              ),
            ),
          ],
        ),
        SizedBox(height: 12),
        Text(
          widget.destination.name,
          style: TextStyle(
            color: CupertinoColors.white,
            fontSize: 32,
            fontWeight: FontWeight.w700,
            height: 1.2,
          ),
        ),
        SizedBox(height: 8),
        Row(
          children: [
            Icon(
              CupertinoIcons.location,
              color: CupertinoColors.white.withValues(alpha: 0.60),
              size: 18,
            ),
            SizedBox(width: 4),
            Text(
              widget.destination.location,
              style: TextStyle(
                color: CupertinoColors.white.withValues(alpha: 0.60),
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
      segments: [
        GlassSegment(label: 'Overview'),
        GlassSegment(label: 'Amenities'),
        GlassSegment(label: 'Reviews')
      ],
      selectedIndex: _selectedSegment,
      onSegmentSelected: (index) {
        setState(() {
          _selectedSegment = index;
        });
      },
      settings: ShowcaseGlassTheme.segmentedControl,
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
        Text(
          'About',
          style: TextStyle(
            color: CupertinoColors.white,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        SizedBox(height: 12),
        Text(
          widget.destination.longDescription,
          style: TextStyle(
            color: CupertinoColors.white.withValues(alpha: 0.70),
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
        Text(
          'Guest Reviews',
          style: TextStyle(
            color: CupertinoColors.white,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        SizedBox(height: 16),
        _buildReviewCard(
          'Sarah Johnson',
          5,
          'Absolutely stunning! The views were breathtaking and the service was impeccable.',
          '2 weeks ago',
        ),
        SizedBox(height: 12),
        _buildReviewCard(
          'Michael Chen',
          5,
          'Perfect getaway. Every detail was thoughtfully considered.',
          '1 month ago',
        ),
        SizedBox(height: 12),
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
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CupertinoColors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: CupertinoColors.white.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                    shape: BoxShape.circle, color: Color(0xFF4A90E2)),
                child: Text(
                  name[0],
                  style: TextStyle(
                    color: CupertinoColors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: TextStyle(
                        color: CupertinoColors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Row(
                      children: [
                        ...List.generate(
                          rating,
                          (index) => Icon(
                            CupertinoIcons.star,
                            color: CupertinoColors.activeOrange,
                            size: 14,
                          ),
                        ),
                        SizedBox(width: 8),
                        Text(
                          time,
                          style: TextStyle(
                            color:
                                CupertinoColors.white.withValues(alpha: 0.60),
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
          SizedBox(height: 12),
          Text(
            review,
            style: TextStyle(
              color: CupertinoColors.white.withValues(alpha: 0.70),
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
        Text(
          'Amenities',
          style: TextStyle(
            color: CupertinoColors.white,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: widget.destination.amenities.map((amenity) {
            return Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: CupertinoColors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: CupertinoColors.white.withValues(alpha: 0.2),
                ),
              ),
              child: Text(
                amenity,
                style: TextStyle(
                  color: CupertinoColors.white,
                  fontSize: 13,
                ),
              ),
            );
          }).toList(),
        ),
        SizedBox(height: 16),
        Row(
          children: [
            _buildSpec(
                CupertinoIcons.group, '${widget.destination.maxGuests} guests'),
            SizedBox(width: 16),
            _buildSpec(CupertinoIcons.bed_double,
                '${widget.destination.bedrooms} beds'),
            SizedBox(width: 16),
            _buildSpec(
                CupertinoIcons.drop, '${widget.destination.bathrooms} baths'),
          ],
        ),
      ],
    );
  }

  Widget _buildSpec(IconData icon, String label) {
    return Row(
      children: [
        Icon(icon,
            color: CupertinoColors.white.withValues(alpha: 0.60), size: 18),
        SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            color: CupertinoColors.white.withValues(alpha: 0.70),
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildHostInfo() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CupertinoColors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: CupertinoColors.white.withValues(alpha: 0.1),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            alignment: Alignment.center,
            decoration:
                BoxDecoration(shape: BoxShape.circle, color: Color(0xFF4A90E2)),
            child: Text(
              widget.destination.hostName[0],
              style: TextStyle(
                color: CupertinoColors.white,
                fontSize: 24,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hosted by',
                  style: TextStyle(
                    color: CupertinoColors.white.withValues(alpha: 0.60),
                    fontSize: 12,
                  ),
                ),
                Text(
                  widget.destination.hostName,
                  style: TextStyle(
                    color: CupertinoColors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          GlassButton(
            icon: Icon(CupertinoIcons.chat_bubble),
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
        Text(
          'Location',
          style: TextStyle(
            color: CupertinoColors.white,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        SizedBox(height: 12),
        Container(
          height: 200,
          decoration: BoxDecoration(
            color: CupertinoColors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: CupertinoColors.white.withValues(alpha: 0.1),
            ),
          ),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  CupertinoIcons.map,
                  color: CupertinoColors.white.withValues(alpha: 0.3),
                  size: 48,
                ),
                SizedBox(height: 8),
                Text(
                  'Map view coming soon',
                  style: TextStyle(
                    color: CupertinoColors.white.withValues(alpha: 0.5),
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
    GlassDialog.show(
      context: context,
      barrierColor: CupertinoColors.black.withValues(alpha: 0.7),
      title: 'Confirm Booking',
      settings: ShowcaseGlassTheme.dialog,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.destination.name,
            style: TextStyle(
              color: CupertinoColors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 8),
          Text(
            widget.destination.location,
            style: TextStyle(
              color: CupertinoColors.white.withValues(alpha: 0.70),
              fontSize: 14,
            ),
          ),
          SizedBox(height: 16),
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: CupertinoColors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total per night',
                  style: TextStyle(
                    color: CupertinoColors.white.withValues(alpha: 0.70),
                    fontSize: 14,
                  ),
                ),
                Text(
                  '\$${widget.destination.pricePerNight.toStringAsFixed(0)}',
                  style: TextStyle(
                    color: CupertinoColors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 16),
          Text(
            'You will receive a confirmation email once your booking is confirmed.',
            style: TextStyle(
              color: CupertinoColors.white.withValues(alpha: 0.60),
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
          },
        ),
      ],
    );
  }
}
