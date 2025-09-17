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
    // Load initial saloons
    context.read<SaloonsBloc>().add(LoadSaloons());

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
    if (_scrollController.hasClients) {
      final position = _scrollController.position;
      final currentState = context.read<SaloonsBloc>().state;

      if (currentState is SaloonsLoaded &&
          currentState.hasMore &&
          !_isLoadingMore) {
        final isNearBottom = position.pixels >= position.maxScrollExtent - 100;
        final isNotScrollable = position.maxScrollExtent <= 0;

        if (isNearBottom || isNotScrollable) {
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
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: Stack(
        children: [
          // TOP GREEN GLOW
          Positioned(
            top: -140,
            left: -60,
            right: -60,
            child: IgnorePointer(
              child: Container(
                height: 300,
                decoration: BoxDecoration(
                  // soft radial green halo like the screenshot
                  gradient: RadialGradient(
                    center: const Alignment(0, -0.6),
                    radius: 0.9,
                    colors: [
                      const Color(0xFF22C55E).withOpacity(0.55),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 1.0],
                  ),
                ),
              ),
            ),
          ),

          // CONTENT
          SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                Expanded(
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
              ],
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
            style: AppTheme.headingStyle.copyWith(fontSize: 32),
          ),
          const SizedBox(height: 16),
          // Search bar and filter button
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppTheme.transparentBackground,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.textPrimaryColor),
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: _onSearchChanged,
                    style: AppTheme.applyPoppins(
                        const TextStyle(color: AppTheme.textPrimaryColor)),
                    decoration: InputDecoration(
                      hintText: AppTranslations.getString(
                          context, 'search_placeholder'),
                      hintStyle: AppTheme.applyPoppins(
                          const TextStyle(color: AppTheme.textSecondaryColor)),
                      suffixIcon: Icon(
                        Icons.search,
                        color: AppTheme.textSecondaryColor,
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
              const SizedBox(width: 12),
              // Filter button
              GestureDetector(
                onTap: () {
                  // TODO: Implement filter functionality
                },
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppTheme.transparentBackground,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.border2),
                  ),
                  child: Icon(
                    Icons.filter_list,
                    color: AppTheme.textPrimaryColor,
                    size: 20,
                  ),
                ),
              ),
            ],
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
            ));
      },
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: state.saloons.length + (state.hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == state.saloons.length) {
            return Padding(
              padding: const EdgeInsets.all(16),
              child: state.hasMore
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: AppTheme.accentColor,
                        strokeWidth: 2,
                      ),
                    )
                  : Center(
                      child: Text(
                        AppTranslations.getString(context, 'no_more_saloons'),
                        style: AppTheme.applyPoppins(const TextStyle(
                          color: AppTheme.textSecondaryColor,
                          fontSize: 14,
                        )),
                      ),
                    ),
            );
          }
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: _buildSaloonCard(state.saloons[index]),
          );
        },
      ),
    );
  }

  Widget _buildSaloonsListWithLoading(SaloonsLoadingMore state) {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: state.saloons.length + 1,
      itemBuilder: (context, index) {
        if (index == state.saloons.length) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(
              child: CircularProgressIndicator(
                color: AppTheme.accentColor,
                strokeWidth: 2,
              ),
            ),
          );
        }
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: _buildSaloonCard(state.saloons[index]),
        );
      },
    );
  }

  Widget _buildSaloonCard(Map<String, dynamic> saloon) {
    // Extract saloon data with fallbacks
    final name = saloon['name'] ??
        AppTranslations.getString(context, 'saloon_name_default');
    final domain = saloon['domain'] ??
        AppTranslations.getString(context, 'saloon_domain_default');

    // Extract real services from API response
    final servicesData = saloon['services'] as List<dynamic>? ?? [];
    final services = servicesData
        .map((service) => service['name'] as String? ?? 'Unknown Service')
        .toList();

    // Debug: Print services data
    print('🔍 === SALON CARD DEBUG ===');
    print('🔍 Salon: ${saloon['name']}');
    print('🔍 Services Data: $servicesData');
    print('🔍 Services Count: ${servicesData.length}');
    print('🔍 Parsed Services: $services');
    print('🔍 Services Empty: ${services.isEmpty}');
    print('🔍 === END SALON CARD DEBUG ===');

    // Use a simple metric (could be based on opening hours or other data)
    final metric = 12; // Fixed metric as shown in the image

    return GestureDetector(
      onTap: () {
        // Navigate to salon details screen
        final salonId = saloon['id'] as String?;
        final salonName = saloon['name'] as String?;
        final salonDomain = saloon['domain'] as String?;
        final salonAddress = saloon['address'] as String?;

        if (salonId != null) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => BlocProvider(
                create: (context) => SalonDetailsBloc(),
                child: SalonDetailsScreen(
                  salonId: salonId,
                  salonName: salonName,
                  salonDomain: salonDomain,
                  salonAddress: salonAddress,
                ),
              ),
            ),
          );
        }
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.secondaryColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.navBartextColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Saloon name
            Text(
              name,
              style: AppTheme.applyPoppins(const TextStyle(
                color: AppTheme.textPrimaryColor,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              )),
            ),
            const SizedBox(height: 4),
            // Domain and metric row
            Row(
              children: [
                Expanded(
                  child: Text(
                    domain,
                    style: AppTheme.applyPoppins(const TextStyle(
                      color: AppTheme.textSecondaryColor,
                      fontSize: 14,
                    )),
                  ),
                ),
                // Metric with trending up icon
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      metric.toString(),
                      style: AppTheme.applyPoppins(const TextStyle(
                        color: AppTheme.textPrimaryColor,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      )),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      LucideIcons.ticket,
                      color: AppTheme.accentColor,
                      size: 16,
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Services row
            services.isEmpty
                ? Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.border2,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      AppTranslations.getString(
                          context, 'no_services_available'),
                      style: AppTheme.applyPoppins(const TextStyle(
                        color: AppTheme.textSecondaryColor,
                        fontSize: 12,
                      )),
                    ),
                  )
                : SizedBox(
                    height: 32, // Fixed height for horizontal scroll
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: services.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(width: 8),
                      itemBuilder: (context, index) {
                        final serviceName = services[index];
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.border2,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            serviceName,
                            style: AppTheme.applyPoppins(const TextStyle(
                              color: AppTheme.textPrimaryColor,
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

  Widget _buildLoadingState() {
    return const Center(
      child: CircularProgressIndicator(
        color: AppTheme.accentColor,
      ),
    );
  }

  Widget _buildErrorState(SaloonsError state) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: AppTheme.errorColor,
            ),
            const SizedBox(height: 16),
            Text(
              AppTranslations.getString(context, 'error_loading_saloons'),
              style: AppTheme.applyPoppins(const TextStyle(
                color: AppTheme.textPrimaryColor,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              )),
            ),
            const SizedBox(height: 8),
            Text(
              state.message,
              style: AppTheme.applyPoppins(const TextStyle(
                color: AppTheme.textSecondaryColor,
                fontSize: 14,
              )),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                context.read<SaloonsBloc>().add(LoadSaloons());
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accentColor,
                foregroundColor: Colors.white,
              ),
              child: Text(AppTranslations.getString(context, 'retry')),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoSaloonsState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.storefront_outlined,
              size: 64,
              color: AppTheme.textSecondaryColor,
            ),
            const SizedBox(height: 16),
            Text(
              AppTranslations.getString(context, 'no_saloons_found'),
              style: AppTheme.applyPoppins(TextStyle(
                color: AppTheme.textPrimaryColor,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              )),
            ),
            const SizedBox(height: 8),
            Text(
              AppTranslations.getString(context, 'no_saloons_message'),
              style: AppTheme.applyPoppins(TextStyle(
                color: AppTheme.textSecondaryColor,
                fontSize: 14,
              )),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInitialState() {
    return const Center(
      child: CircularProgressIndicator(
        color: AppTheme.accentColor,
      ),
    );
  }
}
