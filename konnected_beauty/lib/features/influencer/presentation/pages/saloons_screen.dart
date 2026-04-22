import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/translations/app_translations.dart';
import '../../../../core/bloc/saloons/saloons_bloc.dart';
import '../../../../core/bloc/saloons/saloons_event.dart';
import '../../../../core/bloc/saloons/saloons_state.dart';
import '../../../../core/bloc/salon_details/salon_details_bloc.dart';
import 'salon_details_screen.dart';
import '../../../../widgets/common/motivational_banner.dart';
import '../../../../core/utils/validators.dart';
import '../../../../widgets/forms/custom_dropdown.dart';

class SaloonsScreen extends StatefulWidget {
  const SaloonsScreen({super.key});

  @override
  State<SaloonsScreen> createState() => _SaloonsScreenState();
}

class _SaloonsScreenState extends State<SaloonsScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isLoadingMore = false;
  String? _selectedDomainFilter; // Selected domain for filtering
  String _nameSearchQuery = ''; // Name search query for client-side filtering

  @override
  void initState() {
    super.initState();
    // Load initial saloons with proper pagination (same as campaigns)
    context.read<SaloonsBloc>().add(LoadSaloons(
          page: 1,
          limit: 50, // Use higher limit like campaigns
        ));

    // Setup scroll listener for pagination
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    // Check if we can load more data on any scroll movement (same logic as campaigns)
    if (_scrollController.hasClients) {
      final position = _scrollController.position;
      final currentState = context.read<SaloonsBloc>().state;

      if (currentState is SaloonsLoaded &&
          currentState.hasMore &&
          !_isLoadingMore) {
        // If we're near bottom or list is not scrollable, load more
        final isNearBottom = position.pixels >= position.maxScrollExtent - 100;
        final isNotScrollable = position.maxScrollExtent <= 0;

        if (isNearBottom || isNotScrollable) {
          print('📄 === LOADING MORE SALOONS ===');
          print('📄 Current Page: ${currentState.currentPage}');
          print('📄 Total Pages: ${currentState.totalPages}');
          print('📄 Current Saloons: ${currentState.saloons.length}');
          print('📄 Total Available: ${currentState.total}');
          print('📄 Has More: ${currentState.hasMore}');

          _isLoadingMore = true;
          context.read<SaloonsBloc>().add(LoadMoreSaloons(
                page: currentState.currentPage + 1,
                search: currentState.currentSearch,
              ));
        }
      }
    }
  }

  void _onSearchChanged(String value) {
    // Update name search query for client-side filtering
    setState(() {
      _nameSearchQuery = value.toLowerCase().trim();
    });

    // Debounce - reload salons with domain filter, then filter by name client-side
    Future.delayed(const Duration(milliseconds: 500), () {
      if (_searchController.text == value) {
        // Reload with domain filter (if any), name filtering is done client-side
        final domainKey = _selectedDomainFilter != null
            ? DomainUtils.getDomainKeyFromText(_selectedDomainFilter!, context)
            : null;
        context.read<SaloonsBloc>().add(LoadSaloons(
              search: domainKey,
              page: 1,
              limit: 50,
            ));
      }
    });
  }

  void _onDomainFilterChanged(String? value) {
    setState(() {
      _selectedDomainFilter = value;
    });

    // Convert selected domain text to domain key for API
    final domainKey =
        value != null ? DomainUtils.getDomainKeyFromText(value, context) : null;

    // Don't clear search - keep search text and apply domain filter
    // Load salons with domain filter (search by name is handled separately)
    context.read<SaloonsBloc>().add(LoadSaloons(
          search: domainKey,
          page: 1,
          limit: 50,
        ));
  }

  void _showDomainFilterMenu(BuildContext context) {
    String? tempSelectedDomain = _selectedDomainFilter;

    final brightness = Theme.of(context).brightness;
    final isLightMode = brightness == Brightness.light;
    final textColor = isLightMode ? Colors.black : Colors.white;
    final borderColor = isLightMode ? Colors.black : Colors.white;
    final backgroundColor =
        isLightMode ? Colors.white : AppTheme.getCardBackground(brightness);
    final buttonBgColor = isLightMode ? Colors.black : Colors.white;
    final buttonTextColor = isLightMode ? Colors.white : Colors.black;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: backgroundColor,
      enableDrag: true,
      isDismissible: true,
      builder: (bottomSheetContext) => StatefulBuilder(
        builder: (context, setModalState) {
          final domainOptions = DomainUtils.domainKeys
              .map((key) => AppTranslations.getString(context, key))
              .toList();
          final allDomainsText =
              AppTranslations.getString(context, 'all_domains');
          final allOptions = [allDomainsText, ...domainOptions];

          return Container(
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
            ),
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Handle bar
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: borderColor.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  // Title
                  Text(
                    AppTranslations.getString(context, 'filter_by_domain'),
                    style: TextStyle(
                      color: textColor,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Domain Dropdown
                  CustomDropdown(
                    label:
                        AppTranslations.getString(context, 'activity_domain'),
                    placeholder: allDomainsText,
                    items: allOptions,
                    selectedValue: tempSelectedDomain,
                    onChanged: (String? value) {
                      setModalState(() {
                        tempSelectedDomain = value;
                      });
                    },
                    textColor: textColor,
                    borderColor: borderColor,
                  ),
                  const SizedBox(height: 32),
                  // Buttons Row
                  Row(
                    children: [
                      // Cancel Button
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            side: BorderSide(
                              color: borderColor,
                              width: 1,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: Text(
                            AppTranslations.getString(context, 'cancel'),
                            style: TextStyle(
                              color: textColor,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Filter Button
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                            if (tempSelectedDomain == allDomainsText ||
                                tempSelectedDomain == null) {
                              // Clear filter
                              _onDomainFilterChanged(null);
                            } else {
                              // Apply filter
                              _onDomainFilterChanged(tempSelectedDomain);
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: buttonBgColor,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: Text(
                            AppTranslations.getString(context, 'filter'),
                            style: TextStyle(
                              color: buttonTextColor,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return Scaffold(
      backgroundColor: AppTheme.getScaffoldBackground(brightness),
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          Positioned(
            top: -120,
            left: -60,
            right: -60,
            child: IgnorePointer(
              child: Container(
                height: 280,
                decoration: BoxDecoration(
                  // soft radial green halo like the screenshot
                  gradient: RadialGradient(
                    center: const Alignment(0, -0.6),
                    radius: 0.8,
                    colors: [
                      AppTheme.greenPrimary.withOpacity(0.35),
                      brightness == Brightness.dark
                          ? AppTheme.transparentBackground
                          : AppTheme.textWhite54,
                    ],
                    stops: const [0.0, 1.0],
                  ),
                ),
              ),
            ),
          ),

          // CONTENT
          SafeArea(
            child: GestureDetector(
              onTap: () {
                // Close keyboard when tapping outside text fields
                FocusScope.of(context).unfocus();
              },
              child: BlocListener<SaloonsBloc, SaloonsState>(
                listener: (context, state) {
                  if (state is SaloonsLoaded) {
                    _isLoadingMore = false;
                  } else if (state is SaloonsError) {
                    _isLoadingMore = false;
                  }
                },
                child: BlocBuilder<SaloonsBloc, SaloonsState>(
                  builder: (context, state) {
                    if (state is SaloonsLoading) {
                      return _buildLoadingState();
                    } else if (state is SaloonsError) {
                      return _buildErrorState(state);
                    } else if (state is SaloonsLoaded) {
                      if (state.saloons.isEmpty) {
                        return _buildNoSaloonsState();
                      } else {
                        return _buildSaloonsList(state);
                      }
                    } else if (state is SaloonsLoadingMore) {
                      if (state.saloons.isEmpty) {
                        return _buildNoSaloonsState();
                      } else {
                        return _buildSaloonsListWithLoading(state);
                      }
                    } else {
                      return _buildInitialState();
                    }
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          Text(
            AppTranslations.getString(context, 'saloons_title'),
            style: TextStyle(
              color: AppTheme.getTextPrimaryColor(Theme.of(context).brightness),
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 16),
          // Search bar and Filter button row
          Row(
            children: [
              // Search bar (takes most of the space)
              Expanded(
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? AppTheme.transparentBackground
                        : AppTheme.textWhite54,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: AppTheme.getTextPrimaryColor(
                            Theme.of(context).brightness)),
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: _onSearchChanged,
                    style: AppTheme.applyPoppins(TextStyle(
                        color: AppTheme.getTextPrimaryColor(
                            Theme.of(context).brightness))),
                    decoration: InputDecoration(
                      hintText: AppTranslations.getString(
                          context, 'search_placeholder'),
                      hintStyle: AppTheme.applyPoppins(TextStyle(
                          color: AppTheme.getTextSecondaryColor(
                              Theme.of(context).brightness))),
                      suffixIcon: Icon(
                        Icons.search,
                        color: AppTheme.getTextSecondaryColor(
                            Theme.of(context).brightness),
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(width: 12),
              // Filter button
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? AppTheme.transparentBackground
                      : AppTheme.textWhite54,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: AppTheme.getTextPrimaryColor(
                          Theme.of(context).brightness)),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => _showDomainFilterMenu(context),
                    child: Icon(
                      Icons.filter_list,
                      color: AppTheme.getTextPrimaryColor(
                          Theme.of(context).brightness),
                    ),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          MotivationalBanner(
            text: AppTranslations.getString(context, 'invite_saloons_hint'),
          ),
        ],
      ),
    );
  }

  Widget _buildSaloonsList(SaloonsLoaded state) {
    // Filter salons by name if search query exists
    final filteredSaloons = _nameSearchQuery.isEmpty
        ? state.saloons
        : state.saloons.where((salon) {
            final salonInfo = salon['salonInfo'] as Map<String, dynamic>? ?? {};
            final name = (salonInfo['name'] as String? ?? '').toLowerCase();
            return name.contains(_nameSearchQuery);
          }).toList();

    return RefreshIndicator(
      onRefresh: () async {
        final domainKey = _selectedDomainFilter != null
            ? DomainUtils.getDomainKeyFromText(_selectedDomainFilter!, context)
            : null;
        context.read<SaloonsBloc>().add(RefreshSaloons(
              search: domainKey,
              limit: 50,
            ));
      },
      child: CustomScrollView(
        controller: _scrollController,
        slivers: [
          SliverToBoxAdapter(child: _buildHeader()),
          if (filteredSaloons.isEmpty && _nameSearchQuery.isNotEmpty)
            SliverFillRemaining(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.search_off,
                        size: 64,
                        color: AppTheme.getTextSecondaryColor(
                            Theme.of(context).brightness),
                      ),
                      SizedBox(height: 16),
                      Text(
                        AppTranslations.getString(context, 'no_saloons_found'),
                        style: AppTheme.applyPoppins(TextStyle(
                          color: AppTheme.getTextPrimaryColor(
                              Theme.of(context).brightness),
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        )),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  if (index == filteredSaloons.length) {
                    if (state.hasMore && _nameSearchQuery.isEmpty) {
                      return SizedBox(height: 32);
                    }
                    return _buildListFooter(
                      loaded: filteredSaloons.length,
                      total: _nameSearchQuery.isEmpty
                          ? state.total
                          : filteredSaloons.length,
                    );
                  }
                  return Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        child: _buildSaloonCard(filteredSaloons[index]),
                      ),
                      if (index < filteredSaloons.length - 1)
                        Divider(
                          height: 1,
                          thickness: 1,
                          indent: 16,
                          endIndent: 16,
                          color: Theme.of(context).brightness == Brightness.dark
                              ? AppTheme.border2
                              : AppTheme.lightBannerBackground,
                        ),
                    ],
                  );
                },
                childCount: filteredSaloons.length + 1,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSaloonsListWithLoading(SaloonsLoadingMore state) {
    // Filter salons by name if search query exists
    final filteredSaloons = _nameSearchQuery.isEmpty
        ? state.saloons
        : state.saloons.where((salon) {
            final salonInfo = salon['salonInfo'] as Map<String, dynamic>? ?? {};
            final name = (salonInfo['name'] as String? ?? '').toLowerCase();
            return name.contains(_nameSearchQuery);
          }).toList();

    return RefreshIndicator(
      onRefresh: () async {
        final domainKey = _selectedDomainFilter != null
            ? DomainUtils.getDomainKeyFromText(_selectedDomainFilter!, context)
            : null;
        context.read<SaloonsBloc>().add(RefreshSaloons(
              search: domainKey,
              limit: 50,
            ));
      },
      child: CustomScrollView(
        controller: _scrollController,
        slivers: [
          SliverToBoxAdapter(child: _buildHeader()),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                if (index == filteredSaloons.length) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Center(
                      child: CircularProgressIndicator(
                        color: AppTheme.greenPrimary,
                      ),
                    ),
                  );
                }
                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: _buildSaloonCard(filteredSaloons[index]),
                    ),
                    if (index < filteredSaloons.length - 1)
                      Divider(
                        height: 1,
                        thickness: 1,
                        indent: 16,
                        endIndent: 16,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? AppTheme.border2
                            : AppTheme.lightBannerBackground,
                      ),
                  ],
                );
              },
              childCount: filteredSaloons.length + 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListFooter({required int loaded, required int total}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Column(
        children: [
          Text(
            AppTranslations.getString(context, 'no_more_saloons'),
            style: TextStyle(
              color:
                  AppTheme.getTextSecondaryColor(Theme.of(context).brightness),
              fontSize: 14,
            ),
          ),
          SizedBox(height: 12),
          Text(
            AppTranslations.getString(
              context,
              'saloons_loaded_count',
            ).replaceAll('{loaded}', loaded.toString()).replaceAll(
                  '{total}',
                  total.toString(),
                ),
            style: TextStyle(
              color:
                  AppTheme.getTextSecondaryColor(Theme.of(context).brightness),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSaloonCard(Map<String, dynamic> saloon) {
    // Extract saloon data from new API structure
    final salonInfo = saloon['salonInfo'] as Map<String, dynamic>? ?? {};
    final salonProfile = saloon['salonProfile'] as Map<String, dynamic>? ?? {};

    final name = salonInfo['name'] as String? ??
        AppTranslations.getString(context, 'saloon_name_default');
    final address = salonInfo['address'] as String?;
    // Get domain and translate it if it's a key
    final domainRaw = salonInfo['domain'] as String?;
    final domain = domainRaw != null && domainRaw.isNotEmpty
        ? DomainUtils.getDomainTextFromKey(domainRaw, context)
        : AppTranslations.getString(context, 'saloon_domain_default');
    final description = salonProfile['description'] as String? ?? '';

    // Extract pictures from salonProfile
    final picturesData = salonProfile['pictures'] as List<dynamic>? ?? [];
    final pictures = picturesData
        .map((pic) => pic['url'] as String? ?? '')
        .where((url) => url.isNotEmpty)
        .toList();

    final salonId = saloon['id'] as String?;

    return GestureDetector(
      onTap: () {
        // Navigate to salon details screen
        if (salonId != null) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => BlocProvider(
                create: (context) => SalonDetailsBloc(),
                child: SalonDetailsScreen(
                  salonId: salonId,
                  salonName: name,
                  salonDomain: domain,
                  salonAddress: salonInfo['address'] as String?,
                ),
              ),
            ),
          );
        }
      },
      child: Container(
        padding: const EdgeInsets.only(top: 16),
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? AppTheme.transparentBackground
              : AppTheme.textWhite54,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Images row (horizontally scrollable, full width) with indicators
            _buildImageCarousel(pictures),
            SizedBox(height: 12),

            // Saloon name (large, bold white text)
            Text(
              name,
              style: AppTheme.applyPoppins(TextStyle(
                color:
                    AppTheme.getTextPrimaryColor(Theme.of(context).brightness),
                fontSize: 20,
                fontWeight: FontWeight.bold,
              )),
            ),
            SizedBox(height: 8),

            // Address (white in dark mode, black in light mode)
            if (address != null && address.isNotEmpty)
              Row(
                children: [
                  Icon(
                    LucideIcons.mapPin,
                    size: 16,
                    color: AppTheme.greenPrimary,
                  ),
                  SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      address,
                      style: AppTheme.applyPoppins(TextStyle(
                        color: Theme.of(context).brightness == Brightness.light
                            ? AppTheme.lightTextPrimaryColor
                            : AppTheme.getTextPrimaryColor(
                                Theme.of(context).brightness),
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      )),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            if (address != null && address.isNotEmpty) SizedBox(height: 8),

            // Description (max 1 line)
            if (description.isNotEmpty)
              SizedBox(
                width: double.infinity,
                child: Text(
                  description,
                  style: AppTheme.applyPoppins(TextStyle(
                    color: AppTheme.getTextPrimaryColor(
                        Theme.of(context).brightness),
                    fontSize: 14,
                    height: 1.4,
                  )),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            if (description.isNotEmpty) SizedBox(height: 8),

            // Domain
            Text(
              domain,
              style: AppTheme.applyPoppins(TextStyle(
                color:
                    AppTheme.getTextPrimaryColor(Theme.of(context).brightness),
                fontSize: 14,
              )),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageCarousel(List<String> pictures) {
    if (pictures.isEmpty) {
      // Show placeholder if no images
      return SizedBox(
        height: 174,
        child: _buildSalonImage(null, index: 0),
      );
    }

    // If only one image, no need for carousel
    if (pictures.length == 1) {
      final screenWidth = MediaQuery.of(context).size.width;
      final cardWidth = screenWidth - 32 - 32;
      return Column(
        children: [
          SizedBox(
            height: 174,
            child: SizedBox(
              width: cardWidth,
              child: _buildSalonImage(pictures[0], index: 0),
            ),
          ),
        ],
      );
    }

    // Multiple images - use PageView with indicators
    return _SalonImageCarousel(
      pictures: pictures,
      onImageTap: () {
        // Handle image tap if needed
      },
    );
  }

  Widget _buildSalonImage(String? imageUrl, {required int index}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: imageUrl != null && imageUrl.isNotEmpty
          ? Image.network(
              imageUrl,
              height: 200,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  height: 200,
                  color:
                      AppTheme.getCardBackground(Theme.of(context).brightness),
                  child: Icon(
                    Icons.image_outlined,
                    color: AppTheme.getTextSecondaryColor(
                        Theme.of(context).brightness),
                    size: 40,
                  ),
                );
              },
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Container(
                  height: 200,
                  color:
                      AppTheme.getCardBackground(Theme.of(context).brightness),
                  child: Center(
                    child: CircularProgressIndicator(
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded /
                              loadingProgress.expectedTotalBytes!
                          : null,
                      strokeWidth: 2,
                      color: AppTheme.accentColor,
                    ),
                  ),
                );
              },
            )
          : Container(
              height: 200,
              color: AppTheme.getCardBackground(Theme.of(context).brightness),
              child: Icon(
                Icons.image_outlined,
                color: AppTheme.getTextSecondaryColor(
                    Theme.of(context).brightness),
                size: 40,
              ),
            ),
    );
  }

  Widget _buildLoadingState() {
    return _buildScrollableStateWrapper(
      Center(
        child: CircularProgressIndicator(
          color: AppTheme.greenPrimary,
        ),
      ),
    );
  }

  Widget _buildErrorState(SaloonsError state) {
    // Check if it's a 403 status code
    final isAccountNotActive = state.statusCode == 403;

    return _buildScrollableStateWrapper(
      Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isAccountNotActive
                    ? Icons.account_circle_outlined
                    : Icons.error_outline,
                size: 64,
                color: AppTheme.greenColor,
              ),
              SizedBox(height: 16),
              Text(
                isAccountNotActive
                    ? AppTranslations.getString(context, 'account_not_active')
                    : AppTranslations.getString(
                        context, 'error_loading_saloons'),
                style: AppTheme.applyPoppins(TextStyle(
                  color: AppTheme.getTextPrimaryColor(
                      Theme.of(context).brightness),
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                )),
              ),
              SizedBox(height: 8),
              Text(
                isAccountNotActive
                    ? AppTranslations.getString(context, 'account_not_active')
                    : state.message,
                style: AppTheme.applyPoppins(TextStyle(
                  color: AppTheme.greenColor,
                  fontSize: 14,
                )),
                textAlign: TextAlign.center,
              ),
              if (!isAccountNotActive) ...[
                SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    context.read<SaloonsBloc>().add(LoadSaloons(
                          page: 1,
                          limit: 10,
                        ));
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.accentColor,
                    foregroundColor: AppTheme.getTextPrimaryColor(
                        Theme.of(context).brightness),
                  ),
                  child: Text(AppTranslations.getString(context, 'retry')),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNoSaloonsState() {
    return _buildScrollableStateWrapper(
      Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.storefront_outlined,
                size: 64,
                color: AppTheme.getTextSecondaryColor(
                    Theme.of(context).brightness),
              ),
              SizedBox(height: 16),
              Text(
                AppTranslations.getString(context, 'no_saloons_found'),
                style: AppTheme.applyPoppins(TextStyle(
                  color: AppTheme.getTextPrimaryColor(
                      Theme.of(context).brightness),
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                )),
              ),
              SizedBox(height: 8),
              Text(
                AppTranslations.getString(context, 'no_saloons_message'),
                style: AppTheme.applyPoppins(TextStyle(
                  color: AppTheme.getTextSecondaryColor(
                      Theme.of(context).brightness),
                  fontSize: 14,
                )),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInitialState() {
    return _buildScrollableStateWrapper(
      Center(
        child: CircularProgressIndicator(
          color: AppTheme.accentColor,
        ),
      ),
    );
  }

  Widget _buildScrollableStateWrapper(Widget child) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(child: _buildHeader()),
        SliverFillRemaining(
          hasScrollBody: false,
          child: child,
        ),
      ],
    );
  }
}

// Image carousel widget with page indicators
class _SalonImageCarousel extends StatefulWidget {
  final List<String> pictures;
  final VoidCallback? onImageTap;

  const _SalonImageCarousel({
    required this.pictures,
    this.onImageTap,
  });

  @override
  State<_SalonImageCarousel> createState() => _SalonImageCarouselState();
}

class _SalonImageCarouselState extends State<_SalonImageCarousel> {
  late PageController _pageController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final cardWidth =
        screenWidth - 32 - 32; // Screen width - padding - card padding

    return SizedBox(
      height: 174,
      child: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentPage = index;
              });
            },
            itemCount: widget.pictures.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: EdgeInsets.only(
                  right: index < widget.pictures.length - 1 ? 12 : 0,
                ),
                child: SizedBox(
                  width: cardWidth,
                  child: _buildCarouselImage(widget.pictures[index], index),
                ),
              );
            },
          ),
          // Page indicators overlay at the bottom of the image
          if (widget.pictures.length > 1)
            Positioned(
              bottom: 12,
              left: 0,
              right: 0,
              child: _buildPageIndicators(widget.pictures.length),
            ),
        ],
      ),
    );
  }

  Widget _buildCarouselImage(String imageUrl, int index) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: imageUrl.isNotEmpty
          ? Image.network(
              imageUrl,
              height: 174,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  height: 174,
                  color:
                      AppTheme.getCardBackground(Theme.of(context).brightness),
                  child: Icon(
                    Icons.image_outlined,
                    color: AppTheme.getTextSecondaryColor(
                        Theme.of(context).brightness),
                    size: 40,
                  ),
                );
              },
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Container(
                  height: 174,
                  color:
                      AppTheme.getCardBackground(Theme.of(context).brightness),
                  child: Center(
                    child: CircularProgressIndicator(
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded /
                              loadingProgress.expectedTotalBytes!
                          : null,
                      strokeWidth: 2,
                      color: AppTheme.accentColor,
                    ),
                  ),
                );
              },
            )
          : Container(
              height: 174,
              color: AppTheme.getCardBackground(Theme.of(context).brightness),
              child: Icon(
                Icons.image_outlined,
                color: AppTheme.getTextSecondaryColor(
                    Theme.of(context).brightness),
                size: 40,
              ),
            ),
    );
  }

  Widget _buildPageIndicators(int totalPages) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        totalPages,
        (index) => Container(
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: _currentPage == index ? 8 : 6,
          height: 6,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(3),
            color: _currentPage == index
                ? AppTheme.greenPrimary
                : Colors.white.withOpacity(0.5),
          ),
        ),
      ),
    );
  }
}
