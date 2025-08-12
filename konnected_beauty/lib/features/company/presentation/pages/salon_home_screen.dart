import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/translations/app_translations.dart';
import '../../../../core/bloc/language/language_bloc.dart';
import '../../../../core/bloc/salon_services/salon_services_bloc.dart';
import '../../../../core/services/storage/token_storage_service.dart';
import 'create_service_screen.dart';
import 'service_details_screen.dart';
import 'edit_service_screen.dart';
import 'service_filter_screen.dart';

class SalonHomeScreen extends StatefulWidget {
  final bool showDeleteSuccess;

  const SalonHomeScreen({super.key, this.showDeleteSuccess = false});

  @override
  State<SalonHomeScreen> createState() => _SalonHomeScreenState();
}

class _SalonHomeScreenState extends State<SalonHomeScreen> {
  final TextEditingController searchController = TextEditingController();
  int selectedIndex = 0; // Services tab is selected by default
  bool _showDeleteSuccess = false;
  int? _currentMinPrice;
  int? _currentMaxPrice;

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

    // Load salon services
    context.read<SalonServicesBloc>().add(LoadSalonServices());

    // Add search listener
    searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    searchController.removeListener(_onSearchChanged);
    searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final searchQuery = searchController.text.trim();
    print('🔍 === SEARCH CHANGED ===');
    print('📝 Search Query: "$searchQuery"');
    print('📝 Search Query Length: ${searchQuery.length}');

    // Debounce search to avoid too many API calls
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted && searchController.text.trim() == searchQuery) {
        print('🔍 === EXECUTING SEARCH ===');
        print('📝 Final Search Query: "$searchQuery"');

        if (searchQuery.isEmpty) {
          print('🔄 Loading all services (empty search)');
          // If search is empty, load all services
          context.read<SalonServicesBloc>().add(LoadSalonServices());
        } else {
          print('🔍 Performing search with query: "$searchQuery"');
          // Perform search
          context.read<SalonServicesBloc>().add(SearchSalonServices(
                searchQuery: searchQuery,
              ));
        }
      } else {
        print('❌ Search cancelled - query changed or widget unmounted');
      }
    });
  }

  void _showFilterScreen() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      enableDrag: true,
      isDismissible: true,
      useSafeArea: true,
      builder: (context) => BlocProvider.value(
        value: context.read<SalonServicesBloc>(),
        child: ServiceFilterScreen(
          currentMinPrice: _currentMinPrice,
          currentMaxPrice: _currentMaxPrice,
          onFilterApplied: (minPrice, maxPrice) {
            setState(() {
              _currentMinPrice = minPrice;
              _currentMaxPrice = maxPrice;
            });
          },
        ),
      ),
    );
  }

  void _clearFilters() {
    setState(() {
      _currentMinPrice = null;
      _currentMaxPrice = null;
    });
    // Clear search
    searchController.clear();
    // Reload services without filters
    context.read<SalonServicesBloc>().add(LoadSalonServices());
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<SalonServicesBloc, SalonServicesState>(
        listener: (context, state) {
      if (state is SalonServicesLoaded) {
        // Update current filter values when services are loaded
        // This will be updated when filters are applied
      }
    }, child: BlocBuilder<LanguageBloc, LanguageState>(
      builder: (context, languageState) {
        return Scaffold(
          backgroundColor: AppTheme.primaryColor,
          body: SafeArea(
            child: Column(
              children: [
                // Success Banner (if needed)
                if (_showDeleteSuccess) _buildDeleteSuccessBanner(),

                // Header Section
                _buildHeader(),

                // Main Content
                Expanded(
                  child: _buildMainContent(),
                ),
              ],
            ),
          ),
          bottomNavigationBar: _buildBottomNavigation(),
          floatingActionButton: _buildFloatingActionButton(),
        );
      },
    ));
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title and Debug Button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  AppTranslations.getString(context, 'services'),
                  style: const TextStyle(
                    color: AppTheme.textPrimaryColor,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              // Debug button to show tokens
            ],
          ),
          const SizedBox(height: 20),

          // Search Bar and Filter
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppTheme.secondaryColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppTheme.borderColor,
                      width: 1,
                    ),
                  ),
                  child: TextField(
                    controller: searchController,
                    style: const TextStyle(
                      color: AppTheme.textPrimaryColor,
                      fontSize: 16,
                    ),
                    decoration: InputDecoration(
                      hintText: AppTranslations.getString(context, 'search'),
                      hintStyle: TextStyle(
                        color: AppTheme.textSecondaryColor,
                        fontSize: 16,
                      ),
                      prefixIcon: const Icon(
                        Icons.search,
                        color: AppTheme.textSecondaryColor,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: (_currentMinPrice != null || _currentMaxPrice != null)
                      ? AppTheme.textPrimaryColor
                      : AppTheme.secondaryColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppTheme.textPrimaryColor.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: IconButton(
                  icon: Icon(
                    Icons.filter_list,
                    color:
                        (_currentMinPrice != null || _currentMaxPrice != null)
                            ? AppTheme.primaryColor
                            : AppTheme.textPrimaryColor,
                  ),
                  onPressed: () {
                    _showFilterScreen();
                  },
                ),
              ),
              if (_currentMinPrice != null || _currentMaxPrice != null) ...[
                const SizedBox(width: 8),
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.red.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: IconButton(
                    icon: const Icon(
                      Icons.clear,
                      color: Colors.red,
                    ),
                    onPressed: _clearFilters,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDeleteSuccessBanner() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(16.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.green,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.check_circle,
            color: Colors.white,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              AppTranslations.getString(context, 'service_deleted'),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent() {
    return RefreshIndicator(
      onRefresh: () async {
        context.read<SalonServicesBloc>().add(RefreshSalonServices());
      },
      color: AppTheme.textPrimaryColor,
      backgroundColor: AppTheme.primaryColor,
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          children: [
            // Create New Service Button
            _buildCreateServiceButton(),
            const SizedBox(height: 24),

            // Service Cards
            _buildServiceCards(),
          ],
        ),
      ),
    );
  }

  Widget _buildCreateServiceButton() {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => const CreateServiceScreen(),
          ),
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        decoration: BoxDecoration(
          color: AppTheme.textPrimaryColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppTheme.textPrimaryColor.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              AppTranslations.getString(context, 'create_new_service'),
              style: const TextStyle(
                color: AppTheme.primaryColor,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.add,
                color: AppTheme.textPrimaryColor,
                size: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceCards() {
    return BlocBuilder<SalonServicesBloc, SalonServicesState>(
      builder: (context, state) {
        if (state is SalonServicesLoading) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(32.0),
              child: CircularProgressIndicator(
                color: AppTheme.textPrimaryColor,
              ),
            ),
          );
        } else if (state is SalonServicesLoaded) {
          if (state.services.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  children: [
                    Icon(
                      Icons.spa_outlined,
                      size: 64,
                      color: AppTheme.textSecondaryColor,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      AppTranslations.getString(context, 'no_services_found'),
                      style: const TextStyle(
                        color: AppTheme.textSecondaryColor,
                        fontSize: 16,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }

          return Column(
            children: state.services.asMap().entries.map((entry) {
              final index = entry.key;
              final service = entry.value as Map<String, dynamic>;

              // Debug: Print service details
              print('🆔 === SERVICE ${index + 1} ===');
              print('🆔 Service ID: ${service['id']}');
              print('📝 Service Name: ${service['name']}');
              print('💰 Service Price: ${service['price']}');
              print('📄 Service Description: ${service['description']}');

              return Column(
                children: [
                  if (index > 0) const SizedBox(height: 16),
                  _buildServiceCard(
                    title: service['name'] ?? 'Service',
                    price: '${service['price'] ?? 0} €',
                    description:
                        service['description'] ?? 'No description available',
                    serviceId: service['id'],
                  ),
                ],
              );
            }).toList(),
          );
        } else if (state is SalonServicesError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.red,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    state.message,
                    style: const TextStyle(
                      color: Colors.red,
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      context
                          .read<SalonServicesBloc>()
                          .add(LoadSalonServices());
                    },
                    child: Text(AppTranslations.getString(context, 'retry')),
                  ),
                ],
              ),
            ),
          );
        }

        // Default state - show loading
        return const Center(
          child: Padding(
            padding: EdgeInsets.all(32.0),
            child: CircularProgressIndicator(
              color: AppTheme.textPrimaryColor,
            ),
          ),
        );
      },
    );
  }

  Widget _buildServiceCard({
    required String title,
    required String price,
    required String description,
    String? serviceId,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.secondaryColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.textPrimaryColor.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title and Price
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: AppTheme.textPrimaryColor,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Text(
                price,
                style: const TextStyle(
                  color: AppTheme.textPrimaryColor,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Description
          Text(
            description,
            style: const TextStyle(
              color: AppTheme.textSecondaryColor,
              fontSize: 14,
              height: 1.4,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),

          // See more link
          GestureDetector(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => BlocProvider.value(
                    value: context.read<SalonServicesBloc>(),
                    child: ServiceDetailsScreen(
                      serviceId: serviceId ?? '',
                      serviceName: title,
                      servicePrice: price,
                      serviceDescription: description,
                    ),
                  ),
                ),
              );
            },
            child: Text(
              AppTranslations.getString(context, 'see_more'),
              style: const TextStyle(
                color: AppTheme.accentColor,
                fontSize: 14,
                fontWeight: FontWeight.w600,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Action Buttons
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => BlocProvider.value(
                            value: context.read<SalonServicesBloc>(),
                            child: ServiceDetailsScreen(
                              serviceId: serviceId ?? '',
                              serviceName: title,
                              servicePrice: price.replaceAll(' €', ''),
                              serviceDescription: description,
                              showSuccessMessage: false,
                            ),
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      foregroundColor: AppTheme.textPrimaryColor,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: AppTheme.textPrimaryColor.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                    ),
                    child: Text(
                      AppTranslations.getString(context, 'view_details'),
                      style: const TextStyle(
                        color: AppTheme.textPrimaryColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () {
                      print('🆔 === NAVIGATING TO EDIT SERVICE ===');
                      print('🆔 Service ID: $serviceId');
                      print('📝 Service Name: $title');
                      print('💰 Service Price: $price');
                      print('📄 Service Description: $description');

                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => BlocProvider.value(
                            value: context.read<SalonServicesBloc>(),
                            child: EditServiceScreen(
                              serviceId: serviceId ?? '',
                              serviceName: title,
                              servicePrice: price,
                              serviceDescription: description,
                            ),
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      foregroundColor: AppTheme.textPrimaryColor,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: AppTheme.textPrimaryColor.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                    ),
                    child: Text(
                      AppTranslations.getString(context, 'edit'),
                      style: const TextStyle(
                        color: AppTheme.textPrimaryColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavigation() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.secondaryColor.withOpacity(0.95),
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
                  child: _buildNavItem(0, Icons.list_alt,
                      AppTranslations.getString(context, 'services'))),
              Expanded(
                  child: _buildNavItem(1, Icons.campaign,
                      AppTranslations.getString(context, 'campaigns'))),
              Expanded(
                  child: _buildNavItem(2, Icons.account_balance_wallet,
                      AppTranslations.getString(context, 'wallet'))),
              Expanded(
                  child: _buildNavItem(3, Icons.people,
                      AppTranslations.getString(context, 'influencers'))),
              Expanded(
                  child: _buildNavItem(4, Icons.settings,
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
        // TODO: Navigate to different screens based on index
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: isSelected
                ? AppTheme.textPrimaryColor
                : AppTheme.textSecondaryColor,
            size: 22,
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: TextStyle(
              color: isSelected
                  ? AppTheme.textPrimaryColor
                  : AppTheme.textSecondaryColor,
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
    return Container(
      margin: const EdgeInsets.only(
          bottom: 0), // Position exactly at top of nav bar
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
            Icons.qr_code_scanner,
            size: 32,
          ),
        ),
      ),
    );
  }

  void _scanQRCode() {
    // TODO: Implement QR code scanning functionality
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content:
            Text(AppTranslations.getString(context, 'qr_scanning_coming_soon')),
        backgroundColor: AppTheme.textPrimaryColor,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
      ),
    );
  }
}
