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

class SaloonsScreen extends StatefulWidget {
  const SaloonsScreen({super.key});

  @override
  State<SaloonsScreen> createState() => _SaloonsScreenState();
}

class _SaloonsScreenState extends State<SaloonsScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isLoadingMore = false;

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
    // Debounce search
    Future.delayed(const Duration(milliseconds: 500), () {
      if (_searchController.text == value) {
        context.read<SaloonsBloc>().add(SearchSaloons(value));
      }
    });
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
          // Search bar
          Container(
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
                hintText:
                    AppTranslations.getString(context, 'search_placeholder'),
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
          SizedBox(height: 16),
          MotivationalBanner(
            text: AppTranslations.getString(context, 'invite_saloons_hint'),
          ),
        ],
      ),
    );
  }

  Widget _buildSaloonsList(SaloonsLoaded state) {
    return RefreshIndicator(
      onRefresh: () async {
        context.read<SaloonsBloc>().add(RefreshSaloons(
              search: state.currentSearch,
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
                if (index == state.saloons.length) {
                  if (state.hasMore) {
                    return SizedBox(height: 32);
                  }
                  return _buildListFooter(
                    loaded: state.saloons.length,
                    total: state.total,
                  );
                }
                return Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: _buildSaloonCard(state.saloons[index]),
                );
              },
              childCount: state.saloons.length + 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSaloonsListWithLoading(SaloonsLoadingMore state) {
    return RefreshIndicator(
      onRefresh: () async {
        context.read<SaloonsBloc>().add(RefreshSaloons(
              search: _searchController.text.isEmpty
                  ? null
                  : _searchController.text,
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
                if (index == state.saloons.length) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Center(
                      child: CircularProgressIndicator(
                        color: AppTheme.greenPrimary,
                      ),
                    ),
                  );
                }
                return Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: _buildSaloonCard(state.saloons[index]),
                );
              },
              childCount: state.saloons.length + 1,
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
    final domain = salonInfo['domain'] as String? ??
        AppTranslations.getString(context, 'saloon_domain_default');
    final description = salonProfile['description'] as String? ?? '';

    // Extract pictures from salonProfile
    final picturesData = salonProfile['pictures'] as List<dynamic>? ?? [];
    final pictures = picturesData
        .map((pic) => pic['url'] as String? ?? '')
        .where((url) => url.isNotEmpty)
        .toList();

    // Extract services from API response
    final servicesData = saloon['services'] as List<dynamic>? ?? [];
    final services = servicesData
        .map((service) => service['name'] as String? ?? 'Unknown Service')
        .toList();

    final serviceCount = services.length;
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
        padding: const EdgeInsets.all(16),
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
            // Images row (horizontally scrollable)
            SizedBox(
              height: 120,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: pictures.length > 0 ? pictures.length : 3,
                separatorBuilder: (context, index) => SizedBox(width: 8),
                itemBuilder: (context, index) {
                  return SizedBox(
                    width: 129, // Fixed width for each image
                    child: _buildSalonImage(
                      index < pictures.length ? pictures[index] : null,
                      index: index,
                    ),
                  );
                },
              ),
            ),
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

            // Domain and service count row
            Row(
              children: [
                Expanded(
                  child: Text(
                    domain,
                    style: AppTheme.applyPoppins(TextStyle(
                      color: AppTheme.getTextPrimaryColor(
                          Theme.of(context).brightness),
                      fontSize: 14,
                    )),
                  ),
                ),
                // Service count with icon
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$serviceCount',
                      style: AppTheme.applyPoppins(TextStyle(
                        color: AppTheme.getTextPrimaryColor(
                            Theme.of(context).brightness),
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      )),
                    ),
                    SizedBox(width: 4),
                    Icon(
                      LucideIcons.zap,
                      color: AppTheme.getTextPrimaryColor(
                          Theme.of(context).brightness),
                      size: 16,
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: 12),

            // Service tags (dark grey rounded rectangles) - horizontally scrollable
            if (services.isNotEmpty)
              SizedBox(
                height: 32,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: services.length,
                  separatorBuilder: (context, index) => SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final serviceName = services[index];
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.getCardBackground(Theme.of(context)
                            .brightness), // Dark grey background
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        serviceName,
                        style: AppTheme.applyPoppins(TextStyle(
                          color: AppTheme.getTextPrimaryColor(
                              Theme.of(context).brightness),
                          fontSize: 12,
                        )),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSalonImage(String? imageUrl, {required int index}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: imageUrl != null && imageUrl.isNotEmpty
          ? Image.network(
              imageUrl,
              height: 120,
              width: 129,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  height: 120,
                  width: 129,
                  color:
                      AppTheme.getCardBackground(Theme.of(context).brightness),
                  child: Icon(
                    Icons.image_outlined,
                    color: AppTheme.getTextSecondaryColor(
                        Theme.of(context).brightness),
                    size: 30,
                  ),
                );
              },
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Container(
                  height: 120,
                  width: 129,
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
              height: 120,
              width: 129,
              color: AppTheme.getCardBackground(Theme.of(context).brightness),
              child: Icon(
                Icons.image_outlined,
                color: AppTheme.getTextSecondaryColor(
                    Theme.of(context).brightness),
                size: 30,
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
