import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/translations/app_translations.dart';
import '../../../../core/bloc/salon_services/salon_services_bloc.dart';
import '../../../../core/bloc/campaigns/campaigns_bloc.dart';
import '../../../../core/bloc/campaigns/campaigns_event.dart';
import '../../../../core/bloc/influencers/influencers_bloc.dart';
import '../../../../core/services/storage/token_storage_service.dart';
import 'salon_home_screen.dart';
import 'influencers_screen.dart';
import 'campaigns_screen.dart';
import 'salon_settings_screen.dart';
import 'salon_wallet_screen.dart';
import 'qr_scanner_screen.dart';

class SalonMainWrapper extends StatefulWidget {
  final bool showDeleteSuccess;

  const SalonMainWrapper({super.key, this.showDeleteSuccess = false});

  @override
  State<SalonMainWrapper> createState() => _SalonMainWrapperState();
}

class _SalonMainWrapperState extends State<SalonMainWrapper> {
  int selectedIndex = 0; // Services tab is selected by default
  bool _showDeleteSuccess = false;
  bool _isLoadingMore = false;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _showDeleteSuccess = widget.showDeleteSuccess;

    // Auto-hide the success message after 3 seconds
    if (_showDeleteSuccess) {
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          setState(() {
            _showDeleteSuccess = false;
          });
        }
      });
    }

    // Print stored tokens to console
    TokenStorageService.printStoredTokens();

    // Load salon services on app start
    print('🔄 === LOADING SERVICES ON APP START ===');
    context.read<SalonServicesBloc>().add(LoadSalonServices());

    // Start a timer to periodically check for more data after refresh
    _refreshTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (mounted) {
        _checkAndLoadMoreData();
      } else {
        timer.cancel();
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Always refresh services when returning to this screen to ensure fresh data
    print('🔄 === REFRESHING SERVICES ON SCREEN RETURN ===');
    context.read<SalonServicesBloc>().add(LoadSalonServices());
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  void _checkAndLoadMoreData() {
    final state = context.read<SalonServicesBloc>().state;
    if (state is SalonServicesLoaded && state.hasMoreData && !_isLoadingMore) {
      context.read<SalonServicesBloc>().add(LoadMoreSalonServices(
            page: state.currentPage + 1,
          ));
    }
  }

  void _refreshCurrentTab(int tabIndex) {
    print('🔄 === REFRESHING TAB $tabIndex ===');

    switch (tabIndex) {
      case 0: // Services Tab
        print('🔄 Refreshing Services...');
        context.read<SalonServicesBloc>().add(RefreshSalonServices());
        break;
      case 1: // Campaigns Tab
        print('🔄 Refreshing Campaigns...');
        context.read<CampaignsBloc>().add(RefreshCampaigns(
              status: null, // Load all campaigns
              limit: 10,
            ));
        break;
      case 2: // Wallet Tab
        print('🔄 Refreshing Wallet...');
        // Wallet screen has its own RefreshIndicator, so we don't need to do anything here
        // The wallet screen will refresh when it becomes visible
        break;
      case 3: // Influencers Tab
        print('🔄 Refreshing Influencers...');
        context.read<InfluencersBloc>().add(RefreshInfluencers());
        break;
      case 4: // Settings Tab
        print('🔄 Refreshing Settings...');
        // Settings screen will refresh when it becomes visible
        // The settings screen loads data in initState
        break;
      default:
        print('🔄 Unknown tab index: $tabIndex');
    }

    print('🔄 === END REFRESH TAB $tabIndex ===');
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return Container(
      decoration: brightness == Brightness.dark
          ? const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  Color(0xFF3B3B3B),
                  Color(0xFF1F1E1E),
                ],
              ),
            )
          : BoxDecoration(
              color: AppTheme.getScaffoldBackground(brightness),
            ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Builder(
          builder: (context) {
            print('🏗️ === INDEXED STACK BUILD ===');
            print('🏗️ Selected Index: $selectedIndex');
            print('🏗️ Timestamp: ${DateTime.now().millisecondsSinceEpoch}');

            // Force rebuild of the InfluencersScreen when index changes to 3
            if (selectedIndex == 3) {
              print('🎯 === FORCING INFLUENCERS SCREEN REBUILD ===');
              return const InfluencersScreen();
            }

            return IndexedStack(
              index: selectedIndex,
              children: [
                // Services Tab
                SalonHomeScreen(
                  showDeleteSuccess: _showDeleteSuccess,
                ),
                // Campaigns Tab
                CampaignsScreen(
                  onNavigateToInfluencers: () {
                    setState(() {
                      selectedIndex = 3; // Navigate to Influencers tab
                    });
                  },
                ),
                // Wallet Tab
                const SalonWalletScreen(),
                // Influencers Tab
                const InfluencersScreen(),
                // Settings Tab
                const SalonSettingsScreen(),
              ],
            );
          },
        ),
        bottomNavigationBar: _buildBottomNavigation(),
        floatingActionButton: _buildFloatingActionButton(),
      ),
    );
  }

  Widget _buildBottomNavigation() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.navBarColor,
        border: Border(
          top: BorderSide(
            color: AppTheme.textPrimaryColor.withOpacity(0.1),
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            children: [
              Expanded(
                  child: _buildNavItem(0, LucideIcons.clipboardList,
                      AppTranslations.getString(context, 'services'))),
              Expanded(
                  child: _buildNavItem(1, LucideIcons.badgePercent,
                      AppTranslations.getString(context, 'campaigns'))),
              Expanded(
                  child: _buildNavItem(2, LucideIcons.wallet,
                      AppTranslations.getString(context, 'wallet'))),
              Expanded(
                  child: _buildNavItem(3, LucideIcons.users,
                      AppTranslations.getString(context, 'influencers'))),
              Expanded(
                  child: _buildNavItem(4, LucideIcons.settings2,
                      AppTranslations.getString(context, 'settings'))),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = selectedIndex == index;
    return GestureDetector(
      onTap: () {
        print('🎯 === NAVIGATION TAP ===');
        print('🎯 Tapped on tab: $label (index: $index)');
        print('🎯 Previous selected index: $selectedIndex');
        setState(() {
          selectedIndex = index;
        });
        print('🎯 New selected index: $selectedIndex');

        // Refresh data when navigating to different tabs
        _refreshCurrentTab(index);

        print('🎯 === END NAVIGATION TAP ===');
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: isSelected
                ? AppTheme.textPrimaryColor
                : AppTheme.navBartextColor,
            size: 22,
          ),
          const SizedBox(height: 3),
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                color: isSelected
                    ? AppTheme.textPrimaryColor
                    : AppTheme.navBartextColor,
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingActionButton() {
    // Show QR button for all screens
    return Container(
      margin: const EdgeInsets.only(bottom: 0),
      child: _buildLiquidGlassButton(),
    );
  }

  Widget _buildLiquidGlassButton() {
    return GestureDetector(
      onTap: () {
        _scanQRCode();
      },
      child: ClipOval(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.15),
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
                width: 1.2,
              ),
              boxShadow: [
                // Outer glow for depth
                BoxShadow(
                  color: Colors.white.withOpacity(0.1),
                  blurRadius: 20,
                  spreadRadius: 0,
                  offset: const Offset(0, 0),
                ),
                // Drop shadow for depth
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 15,
                  spreadRadius: 0,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Stack(
              children: [
                // Liquid glass highlight - main
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        center: const Alignment(-0.3, -0.3),
                        radius: 1.0,
                        colors: [
                          Colors.white.withOpacity(0.6),
                          Colors.white.withOpacity(0.2),
                          Colors.transparent,
                        ],
                        stops: const [0.0, 0.5, 1.0],
                      ),
                    ),
                  ),
                ),
                // Secondary liquid highlight
                Positioned(
                  top: 15,
                  left: 15,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          Colors.white.withOpacity(0.4),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
                // Main content
                const Center(
                  child: Icon(
                    LucideIcons.qrCode,
                    size: 32,
                    color: Colors.white,
                    shadows: [
                      Shadow(
                        color: Colors.black26,
                        blurRadius: 4,
                        offset: Offset(0, 2),
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

  Future<void> _scanQRCode() async {
    print('🔍 === QR SCAN BUTTON TAPPED - ULTRA FORCE ===');

    // Ultra force: Open QR scanner directly without permission checks
    print('📷 ULTRA FORCE: Opening QR scanner directly...');

    if (mounted) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => const QRScannerScreen(),
        ),
      );
    }
  }
}
