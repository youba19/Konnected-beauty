import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/translations/app_translations.dart';
import '../../../../core/bloc/language/language_bloc.dart';
import '../../../../core/bloc/salon_services/salon_services_bloc.dart';
import '../../../../core/bloc/auth/auth_bloc.dart';
import '../../../../core/bloc/influencers/influencers_bloc.dart';
import '../../../../core/services/storage/token_storage_service.dart';
import '../../../../core/services/api/salon_services_service.dart';
import '../../../../widgets/common/top_notification_banner.dart';

import '../../../auth/presentation/pages/welcome_screen.dart';
import 'salon_home_screen.dart';
import 'create_service_screen.dart';
import 'service_details_screen.dart';
import 'edit_service_screen.dart';
import 'service_filter_screen.dart';
import 'influencers_screen.dart';
import 'campaigns_screen.dart';
import 'salon_settings_screen.dart';

class SalonMainWrapper extends StatefulWidget {
  final bool showDeleteSuccess;

  const SalonMainWrapper({super.key, this.showDeleteSuccess = false});

  @override
  State<SalonMainWrapper> createState() => _SalonMainWrapperState();
}

class _SalonMainWrapperState extends State<SalonMainWrapper> {
  int selectedIndex = 0; // Services tab is selected by default
  bool _showDeleteSuccess = false;
  int? _currentMinPrice;
  int? _currentMaxPrice;
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

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [
            Color(0xFF3B3B3B),
            Color(0xFF1F1E1E),
          ],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: IndexedStack(
          index: selectedIndex,
          children: [
            // Services Tab
            SalonHomeScreen(
              showDeleteSuccess: _showDeleteSuccess,
            ),
            // Campaigns Tab
            const CampaignsScreen(),
            // Wallet Tab
            const Center(
              child: Text(
                'Wallet Screen - Coming Soon',
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
            ),
            // Influencers Tab
            const InfluencersScreen(),
            // Settings Tab
            const SalonSettingsScreen(),
          ],
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
                  child: _buildNavItem(1, LucideIcons.trendingUp,
                      AppTranslations.getString(context, 'campaigns'))),
              Expanded(
                  child: _buildNavItem(2, LucideIcons.wallet,
                      AppTranslations.getString(context, 'wallet'))),
              Expanded(
                  child: _buildNavItem(3, LucideIcons.users,
                      AppTranslations.getString(context, 'influencers'))),
              Expanded(
                  child: _buildNavItem(4, LucideIcons.settings,
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
        setState(() {
          selectedIndex = index;
        });
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
          Text(
            label,
            style: TextStyle(
              color: isSelected
                  ? AppTheme.textPrimaryColor
                  : AppTheme.navBartextColor,
              fontSize: 10,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingActionButton() {
    // Show different FAB based on selected tab
    if (selectedIndex == 0) {
      // Services tab - QR Scanner
      return Container(
        margin: const EdgeInsets.only(bottom: 0),
        child: FloatingActionButton(
          onPressed: () {
            _scanQRCode();
          },
          backgroundColor: Colors.transparent,
          foregroundColor: AppTheme.textPrimaryColor,
          elevation: 0,
          shape: const CircleBorder(),
          child: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppTheme.textPrimaryColor.withOpacity(0.15),
              shape: BoxShape.circle,
              border: Border.all(
                color: AppTheme.textPrimaryColor.withOpacity(0.4),
                width: 1.5,
              ),
            ),
            child: const Icon(
              LucideIcons.qrCode,
              size: 32,
            ),
          ),
        ),
      );
    } else if (selectedIndex == 1) {
      // Campaigns tab - No FAB
      return const SizedBox.shrink();
    } else {
      // Other tabs - no FAB
      return const SizedBox.shrink();
    }
  }

  void _scanQRCode() {
    // TODO: Implement QR code scanning functionality
    TopNotificationService.showInfo(
      context: context,
      message: AppTranslations.getString(context, 'qr_scanning_coming_soon'),
    );
  }
}
