import 'dart:math' as math;
import 'dart:ui';

import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:flutter/services.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import '../data/destinations_data.dart';
import '../models/destination.dart';
import '../widgets/animated_background.dart';
import '../theme/showcase_glass_theme.dart';
import 'detail_page.dart';
import 'concierge_page.dart';

/// The main home page featuring a scrollable feed of luxury destinations
///
/// This page showcases full-bleed imagery with minimal glass overlays,
/// demonstrating how glass morphism can enhance rather than hide content.
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final Set<String> _favoriteIds = {};
  int _selectedTab = 0;
  final double _minPrice = 0;
  double _maxPrice = 2000;
  bool _showInstantBook = false;

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _toggleFavorite(String id) {
    setState(() {
      if (_favoriteIds.contains(id)) {
        _favoriteIds.remove(id);
      } else {
        _favoriteIds.add(id);
      }
    });
  }

  List<Destination> get _filteredDestinations {
    // Filter logic can be added here based on _selectedTab
    return sampleDestinations;
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarBrightness: Brightness.dark,
        statusBarIconBrightness: Brightness.light,
      ),
    );

    return AppBackground(
      child: GlassScaffold(
        body: GestureDetector(
          onTap: () => _searchFocusNode.unfocus(),
          child: Stack(
            children: [
              // Main content: scrollable destination cards
              ListView.separated(
                itemCount: _filteredDestinations.length,
                separatorBuilder: (context, index) => SizedBox(height: 20),
                padding: EdgeInsets.only(
                  top: 200,
                  left: 20,
                  right: 20,
                  bottom: 120,
                ),
                itemBuilder: (context, index) {
                  final destination = _filteredDestinations[index];
                  return _buildDestinationCard(destination);
                },
              ),

              // Top gradient overlay
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Container(
                  height: 200,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Color(0xFF0A1929).withValues(alpha: 0.95),
                        Color(0xFF0A1929).withValues(alpha: 0),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
              ),

              // Top bar with search and branding
              SafeArea(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20.0),
                  child: Column(
                    children: [
                      SizedBox(height: 8),
                      _buildTopBar(),
                      SizedBox(height: 16),
                      _buildSearchBar(),
                      Spacer(),
                      _buildBottomBar(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Logo/Brand
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Wanderlust',
              style: TextStyle(
                color: CupertinoColors.white,
                fontSize: 28,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.5,
              ),
            ),
            Text(
              'Luxury Escapes',
              style: TextStyle(
                color: CupertinoColors.white.withValues(alpha: 0.60),
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),

        // Profile button
        GlassButton(
          quality: ShowcaseGlassTheme.premiumQuality,
          settings: ShowcaseGlassTheme.profileButton,
          icon: Icon(CupertinoIcons.person),
          iconSize: 22,
          width: 44,
          height: 44,
          useOwnLayer: true,
          onTap: () {},
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return AdaptiveLiquidGlassLayer(
      quality: ShowcaseGlassTheme.premiumQuality,
      settings: ShowcaseGlassTheme.searchBar,
      child: Row(
        children: [
          Expanded(
            child: GlassTextField(
              controller: _searchController,
              focusNode: _searchFocusNode,
              placeholder: 'Search destinations...',
              shape: LiquidRoundedSuperellipse(borderRadius: 50),
              placeholderStyle: TextStyle(
                color: CupertinoColors.white.withValues(alpha: 0.60),
                fontSize: 15,
              ),
              prefixIcon: Icon(
                CupertinoIcons.search,
                color: CupertinoColors.white.withValues(alpha: 0.70),
                size: 22,
              ),
            ),
          ),
          SizedBox(width: 8),
          GlassButton(
            icon: Icon(CupertinoIcons.slider_horizontal_3),
            iconSize: 22,
            height: 48,
            width: 48,
            onTap: () => _showFilterSheet(),
          ),
        ],
      ),
    );
  }

  void _showFilterSheet() {
    GlassModalSheet.show(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => GlassSheet(
          settings: ShowcaseGlassTheme.bottomSheet,
          child: Padding(
            padding: EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Filters',
                  style: TextStyle(
                    color: CupertinoColors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 24),
                Text(
                  'Price Range',
                  style: TextStyle(
                    color: CupertinoColors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 8),
                Row(
                  children: [
                    Text(
                      '\$${_minPrice.toInt()}',
                      style: TextStyle(
                        color: CupertinoColors.white.withValues(alpha: 0.70),
                        fontSize: 16,
                      ),
                    ),
                    Spacer(),
                    Text(
                      '\$${_maxPrice.toInt()}+',
                      style: TextStyle(
                        color: CupertinoColors.white.withValues(alpha: 0.70),
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12),
                GlassSlider(
                  value: _maxPrice,
                  min: 0,
                  max: 2000,
                  onChanged: (value) {
                    setSheetState(() {
                      _maxPrice = value;
                    });
                  },
                ),
                SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Instant Book',
                      style: TextStyle(
                        color: CupertinoColors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    GlassSwitch(
                      value: _showInstantBook,
                      onChanged: (value) {
                        setSheetState(() {
                          _showInstantBook = value;
                        });
                      },
                    ),
                  ],
                ),
                SizedBox(height: 24),
                AdaptiveLiquidGlassLayer(
                  settings: ShowcaseGlassTheme.modalActionButtons,
                  child: Row(
                    children: [
                      Expanded(
                        child: GlassButton(
                          icon: Icon(CupertinoIcons.clear),
                          label: 'Clear',
                          height: 40,
                          shape: LiquidRoundedSuperellipse(borderRadius: 12),
                          onTap: () {
                            setSheetState(() {
                              _maxPrice = 2000;
                              _showInstantBook = false;
                            });
                            setState(() {
                              _maxPrice = 2000;
                              _showInstantBook = false;
                            });
                          },
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: GlassButton(
                          icon: Icon(CupertinoIcons.checkmark),
                          label: 'Apply',
                          height: 40,
                          shape: LiquidRoundedSuperellipse(borderRadius: 12),
                          onTap: () {
                            setState(() {
                              // Apply filters
                            });
                            Navigator.pop(context);
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDestinationCard(Destination destination) {
    final isFavorite = _favoriteIds.contains(destination.id);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => DetailPage(
              destination: destination,
              isFavorite: isFavorite,
              onFavoriteToggle: () => _toggleFavorite(destination.id),
            ),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
                  return FadeTransition(opacity: animation, child: child);
                },
            transitionDuration: const Duration(milliseconds: 400),
          ),
        );
      },
      child: Hero(
        tag: 'destination_${destination.id}',
        flightShuttleBuilder:
            (flightContext, animation, direction, fromContext, toContext) {
              return Container(
                color: Color(0x00000000),
                child: toContext.widget,
              );
            },
        child: Container(
          color: Color(0x00000000),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(32),
            child: Container(
              height: 460,
              decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    color: CupertinoColors.black.withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Full-bleed hero image
                  Image.asset(
                    destination.heroImage,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      // Fallback gradient for missing images
                      return Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Color(0xFF4A90E2), Color(0xFF357ABD)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: Center(
                          child: Icon(
                            CupertinoIcons.photo,
                            size: 80,
                            color: CupertinoColors.white.withValues(alpha: 0.5),
                          ),
                        ),
                      );
                    },
                  ),

                  // Minimal glass overlay at bottom
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: ClipRRect(
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                CupertinoColors.black.withValues(alpha: 0.0),
                                CupertinoColors.black.withValues(alpha: 0.6),
                              ],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                          ),
                          padding: EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          destination.name,
                                          style: TextStyle(
                                            color: CupertinoColors.white,
                                            fontSize: 22,
                                            fontWeight: FontWeight.w700,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          softWrap: false,
                                        ),
                                        SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Icon(
                                              CupertinoIcons.location,
                                              color: CupertinoColors.white
                                                  .withValues(alpha: 0.70),
                                              size: 16,
                                            ),
                                            SizedBox(width: 4),
                                            Expanded(
                                              child: Text(
                                                destination.location,
                                                style: TextStyle(
                                                  color: CupertinoColors.white
                                                      .withValues(alpha: 0.70),
                                                  fontSize: 14,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  SizedBox(width: 12),
                                  GestureDetector(
                                    onTap: () =>
                                        _toggleFavorite(destination.id),
                                    child: Container(
                                      padding: EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: CupertinoColors.white.withValues(
                                          alpha: 0.2,
                                        ),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        isFavorite
                                            ? CupertinoIcons.heart_fill
                                            : CupertinoIcons.heart,
                                        color: isFavorite
                                            ? CupertinoColors.systemRed
                                            : CupertinoColors.white,
                                        size: 24,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 12),
                              Row(
                                children: [
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 5,
                                    ),
                                    decoration: BoxDecoration(
                                      color: CupertinoColors.white.withValues(
                                        alpha: 0.2,
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          CupertinoIcons.star,
                                          color: CupertinoColors.activeOrange,
                                          size: 14,
                                        ),
                                        SizedBox(width: 4),
                                        Text(
                                          '${destination.rating}',
                                          style: TextStyle(
                                            color: CupertinoColors.white,
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        Text(
                                          ' (${destination.reviewCount})',
                                          style: TextStyle(
                                            color: CupertinoColors.white
                                                .withValues(alpha: 0.70),
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Spacer(),
                                  Text(
                                    '\$${destination.pricePerNight.toStringAsFixed(0)}',
                                    style: TextStyle(
                                      color: CupertinoColors.white,
                                      fontSize: 24,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  Text(
                                    ' /night',
                                    style: TextStyle(
                                      color: CupertinoColors.white.withValues(
                                        alpha: 0.70,
                                      ),
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    const defaultGlassColor = Color(
      0x3DFFFFFF,
    ); // CupertinoColors.white.withValues(alpha: 0.24)
    const defaultLightAngle =
        0.75 * math.pi; // 135° — Apple standard, upper-left
    return Padding(
      padding: EdgeInsets.only(bottom: 0),
      child: GlassTabBar.bottom(
        verticalPadding: 0,
        horizontalPadding: 8,
        indicatorColor: CupertinoColors.black.withValues(alpha: 0.26),
        settings: LiquidGlassSettings(
          thickness: 30,
          blur: 3,
          chromaticAberration: 0.3,
          lightIntensity: 0.6,
          refractiveIndex: 1.59,
          saturation: 0.7,
          ambientStrength: 1,
          lightAngle: defaultLightAngle,
          glassColor: defaultGlassColor,
        ),
        extraButton: GlassTabBarExtraButton(
          icon: Icon(CupertinoIcons.person_fill),
          onTap: () {
            Navigator.push(
              context,
              CupertinoPageRoute(builder: (context) => const ConciergePage()),
            );
          },
          label: 'Concierge',
        ),
        tabs: [
          GlassTab(
            label: 'Explore',
            icon: Icon(CupertinoIcons.compass),
            activeIcon: Icon(CupertinoIcons.compass_fill),
          ),
          GlassTab(
            label: 'Saved',
            icon: Icon(CupertinoIcons.heart),
            activeIcon: Icon(CupertinoIcons.heart_fill),
          ),
          GlassTab(
            label: 'Trips',
            icon: Icon(CupertinoIcons.bag),
            activeIcon: Icon(CupertinoIcons.bag_fill),
          ),
        ],
        selectedIndex: _selectedTab,
        onTabSelected: (index) {
          setState(() {
            _selectedTab = index;
          });
        },
      ),
    );
  }
}
