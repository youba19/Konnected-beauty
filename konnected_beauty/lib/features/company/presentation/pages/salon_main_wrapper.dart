import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/translations/app_translations.dart';
import '../../../../core/bloc/theme/theme_bloc.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/salon_ui_theme.dart';
import '../../../../core/bloc/salon_services/salon_services_bloc.dart';
import '../../../../core/bloc/campaigns/campaigns_bloc.dart';
import '../../../../core/bloc/campaigns/campaigns_event.dart';
import '../../../../core/bloc/influencers/influencers_bloc.dart';
import '../../../../core/services/storage/token_storage_service.dart';
import 'salon_home_screen.dart';
import 'influencers_screen.dart';
import 'campaigns_screen.dart';
import 'salon_wallet_screen.dart';
import 'qr_scanner_screen.dart';

class SalonMainWrapper extends StatefulWidget {
  final bool showDeleteSuccess;

  const SalonMainWrapper({super.key, this.showDeleteSuccess = false});

  @override
  State<SalonMainWrapper> createState() => _SalonMainWrapperState();
}

class _SalonMainWrapperState extends State<SalonMainWrapper> {
  int selectedIndex = 0;
  bool _showDeleteSuccess = false;
  bool _isLoadingMore = false;
  Timer? _refreshTimer;

  static const double _bottomNavHorizontalPadding = 18;
  static const double _bottomNavBottomPadding = 12;
  static const double _bottomNavEstimatedHeight = 72;
  static const double _fabExtraBottomGap = 22;

  @override
  void initState() {
    super.initState();
    _showDeleteSuccess = widget.showDeleteSuccess;

    if (_showDeleteSuccess) {
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          setState(() {
            _showDeleteSuccess = false;
          });
        }
      });
    }

    TokenStorageService.printStoredTokens();

    print('🔄 === LOADING SERVICES ON APP START ===');
    context.read<SalonServicesBloc>().add(LoadSalonServices());

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
    switch (tabIndex) {
      case 0:
        context.read<SalonServicesBloc>().add(RefreshSalonServices());
        break;
      case 1:
        context.read<CampaignsBloc>().add(RefreshCampaigns(
              status: null,
              limit: 10,
            ));
        break;
      case 2:
        break;
      case 3:
        context.read<InfluencersBloc>().add(RefreshInfluencers());
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeBloc, ThemeState>(
      builder: (context, themeState) {
        final brightness = themeState.brightness;
        final ui = SalonUiTheme.from(brightness);
        final baseTheme = AppTheme.getThemeData(brightness);

        return Theme(
          data: baseTheme.copyWith(
            textTheme: GoogleFonts.montserratTextTheme(baseTheme.textTheme),
            primaryTextTheme:
                GoogleFonts.montserratTextTheme(baseTheme.primaryTextTheme),
          ),
          child: ColoredBox(
            color: ui.bg,
            child: Scaffold(
              backgroundColor: Colors.transparent,
              body: Builder(
                builder: (context) {
                  final bottomInset = MediaQuery.paddingOf(context).bottom;

                  return Stack(
                    fit: StackFit.expand,
                    children: [
                      IndexedStack(
                        index: selectedIndex,
                        children: [
                          SalonHomeScreen(
                            showDeleteSuccess: _showDeleteSuccess,
                          ),
                          CampaignsScreen(
                            onNavigateToInfluencers: () {
                              setState(() {
                                selectedIndex = 3;
                              });
                            },
                          ),
                          const SalonWalletScreen(),
                          const InfluencersScreen(),
                        ],
                      ),
                      Positioned(
                        left: _bottomNavHorizontalPadding,
                        right: _bottomNavHorizontalPadding,
                        bottom: bottomInset + _bottomNavBottomPadding,
                        child: _buildBottomNavigation(ui),
                      ),
                      Positioned(
                        right: 16,
                        bottom: bottomInset +
                            _bottomNavBottomPadding +
                            _bottomNavEstimatedHeight +
                            _fabExtraBottomGap,
                        child: _buildFloatingActionButton(ui),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBottomNavigation(SalonUiTheme ui) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 16, 14, 12),
      decoration: BoxDecoration(
        color: ui.navBar,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: ui.isDark ? 0.35 : 0.12),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildNavItem(
              0,
              LucideIcons.clipboardList,
              AppTranslations.getString(context, 'services'),
              ui,
            ),
          ),
          Expanded(
            child: _buildNavItem(
              1,
              LucideIcons.ticket,
              AppTranslations.getString(context, 'campaigns'),
              ui,
            ),
          ),
          Expanded(
            child: _buildNavItem(
              2,
              LucideIcons.wallet,
              AppTranslations.getString(context, 'revenue'),
              ui,
            ),
          ),
          Expanded(
            child: _buildNavItem(
              3,
              LucideIcons.users,
              AppTranslations.getString(context, 'influencers'),
              ui,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(
    int index,
    IconData icon,
    String label,
    SalonUiTheme ui,
  ) {
    final isSelected = selectedIndex == index;
    final color = isSelected ? ui.navSelected : ui.navUnselected;
    return GestureDetector(
      onTap: () {
        setState(() => selectedIndex = index);
        _refreshCurrentTab(index);
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingActionButton(SalonUiTheme ui) {
    return FloatingActionButton(
      onPressed: _scanQRCode,
      backgroundColor: ui.fabBg,
      elevation: 4,
      shape: CircleBorder(
        side: BorderSide(color: ui.fabBorder, width: 1),
      ),
      child: Icon(
        LucideIcons.scanLine,
        color: ui.textPrimary,
        size: 26,
      ),
    );
  }

  Future<void> _scanQRCode() async {
    if (mounted) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => const QRScannerScreen(),
        ),
      );
    }
  }
}
