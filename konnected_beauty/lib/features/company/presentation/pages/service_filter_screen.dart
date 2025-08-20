import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/translations/app_translations.dart';
import '../../../../core/bloc/salon_services/salon_services_bloc.dart';
import '../../../../widgets/forms/custom_text_field.dart';

class ServiceFilterScreen extends StatefulWidget {
  final int? currentMinPrice;
  final int? currentMaxPrice;
  final Function(int? minPrice, int? maxPrice)? onFilterApplied;

  const ServiceFilterScreen({
    super.key,
    this.currentMinPrice,
    this.currentMaxPrice,
    this.onFilterApplied,
  });

  @override
  State<ServiceFilterScreen> createState() => _ServiceFilterScreenState();
}

class _ServiceFilterScreenState extends State<ServiceFilterScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController minPriceController = TextEditingController();
  final TextEditingController maxPriceController = TextEditingController();
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;

  @override
  void initState() {
    super.initState();

    // Initialize controllers with current values
    minPriceController.text = widget.currentMinPrice?.toString() ?? '0';
    maxPriceController.text = widget.currentMaxPrice?.toString() ?? '1000';

    // Setup animation
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _slideAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    // Start animation
    _animationController.forward();
  }

  @override
  void dispose() {
    minPriceController.dispose();
    maxPriceController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _applyFilter() {
    final minPrice = int.tryParse(minPriceController.text);
    final maxPrice = int.tryParse(maxPriceController.text);

    if (minPrice == null || maxPrice == null) {
      // Show error for invalid input
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter valid prices'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (minPrice > maxPrice) {
      // Show error for invalid range
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Min price cannot be greater than max price'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Apply filter
    context.read<SalonServicesBloc>().add(FilterSalonServices(
          minPrice: minPrice,
          maxPrice: maxPrice,
        ));

    // Update parent widget with filter values
    widget.onFilterApplied?.call(minPrice, maxPrice);

    // Close the filter screen
    Navigator.of(context).pop();
  }

  void _cancelFilter() {
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _slideAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(
              0, MediaQuery.of(context).size.height * _slideAnimation.value),
          child: Container(
            width: double.infinity,
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.8,
              minHeight: MediaQuery.of(context).size.height * 0.33,
            ),
            decoration: const BoxDecoration(
              color: AppTheme.secondaryColor,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Padding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Handle bar
                    Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(top: 12, bottom: 8),
                      decoration: BoxDecoration(
                        color: AppTheme.textSecondaryColor.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),

                    // Title
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24.0, vertical: 16.0),
                      child: Text(
                        AppTranslations.getString(context, 'filter'),
                        style: const TextStyle(
                          color: AppTheme.textPrimaryColor,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                    // Filter content
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16.0), // Reduced from 24.0
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Service Price Section
                          Text(
                            AppTranslations.getString(context, 'service_price'),
                            style: const TextStyle(
                              color: AppTheme.textPrimaryColor,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),

                          const SizedBox(height: 12),

                          // Min/Max Price Inputs
                          Row(
                            children: [
                              // Min Price
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      AppTranslations.getString(context, 'min'),
                                      style: const TextStyle(
                                        color: AppTheme.textSecondaryColor,
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Container(
                                      decoration: BoxDecoration(
                                        color: AppTheme.secondaryColor,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: AppTheme.borderColor,
                                          width: 1,
                                        ),
                                      ),
                                      child: TextField(
                                        controller: minPriceController,
                                        keyboardType: TextInputType.number,
                                        inputFormatters: [
                                          FilteringTextInputFormatter.allow(
                                              RegExp(r'[0-9]')),
                                        ],
                                        style: const TextStyle(
                                          color: AppTheme.textPrimaryColor,
                                          fontSize: 16,
                                        ),
                                        decoration: const InputDecoration(
                                          hintText: '0',
                                          hintStyle: TextStyle(
                                            color: AppTheme.textSecondaryColor,
                                            fontSize: 16,
                                          ),
                                          border: InputBorder.none,
                                          contentPadding: EdgeInsets.symmetric(
                                            horizontal: 12, // Reduced padding
                                            vertical: 12, // Reduced padding
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(width: 8), // Reduced spacing

                              // Max Price
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      AppTranslations.getString(context, 'max'),
                                      style: const TextStyle(
                                        color: AppTheme.textSecondaryColor,
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Container(
                                      decoration: BoxDecoration(
                                        color: AppTheme.secondaryColor,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: AppTheme.borderColor,
                                          width: 1,
                                        ),
                                      ),
                                      child: TextField(
                                        controller: maxPriceController,
                                        keyboardType: TextInputType.number,
                                        inputFormatters: [
                                          FilteringTextInputFormatter.allow(
                                              RegExp(r'[0-9]')),
                                        ],
                                        style: const TextStyle(
                                          color: AppTheme.textPrimaryColor,
                                          fontSize: 16,
                                        ),
                                        decoration: const InputDecoration(
                                          hintText: '1000',
                                          hintStyle: TextStyle(
                                            color: AppTheme.textSecondaryColor,
                                            fontSize: 16,
                                          ),
                                          border: InputBorder.none,
                                          contentPadding: EdgeInsets.symmetric(
                                            horizontal: 12, // Reduced padding
                                            vertical: 12, // Reduced padding
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 24),

                          // Action Buttons
                          Row(
                            children: [
                              // Cancel Button
                              Expanded(
                                child: SizedBox(
                                  height: 48,
                                  child: ElevatedButton(
                                    onPressed: _cancelFilter,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.transparent,
                                      foregroundColor:
                                          AppTheme.textPrimaryColor,
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        side: BorderSide(
                                          color: AppTheme.textPrimaryColor
                                              .withOpacity(0.3),
                                          width: 1,
                                        ),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8), // Reduced padding
                                    ),
                                    child: Text(
                                      AppTranslations.getString(
                                          context, 'cancel'),
                                      style: const TextStyle(
                                        color: AppTheme.textPrimaryColor,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                ),
                              ),

                              const SizedBox(width: 8), // Reduced spacing

                              // Apply Filter Button
                              Expanded(
                                child: SizedBox(
                                  height: 48,
                                  child: ElevatedButton(
                                    onPressed: _applyFilter,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppTheme.accentColor,
                                      foregroundColor: AppTheme.primaryColor,
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 12), // Compact padding
                                    ),
                                    child: Text(
                                      AppTranslations.getString(
                                          context, 'apply_filter'),
                                      style: const TextStyle(
                                        color: AppTheme.primaryColor,
                                        fontSize: 14, // Compact font size
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
