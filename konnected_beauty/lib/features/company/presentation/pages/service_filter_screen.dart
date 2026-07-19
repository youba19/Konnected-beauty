import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/theme/salon_ui_theme.dart';
import '../../../../core/bloc/theme/theme_bloc.dart';
import '../../../../core/translations/app_translations.dart';
import '../../../../core/bloc/salon_services/salon_services_bloc.dart';
import '../../../../widgets/common/top_notification_banner.dart';

abstract final class _ServiceFilterUi {
  static const double radius = 16;
  static const double buttonRadius = 14;
}

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

class _ServiceFilterScreenState extends State<ServiceFilterScreen> {
  final TextEditingController minPriceController = TextEditingController();
  final TextEditingController maxPriceController = TextEditingController();

  @override
  void initState() {
    super.initState();
    minPriceController.text = widget.currentMinPrice?.toString() ?? '0';
    maxPriceController.text = widget.currentMaxPrice?.toString() ?? '1000';
  }

  @override
  void dispose() {
    minPriceController.dispose();
    maxPriceController.dispose();
    super.dispose();
  }

  void _applyFilter() {
    final minPrice = int.tryParse(minPriceController.text);
    final maxPrice = int.tryParse(maxPriceController.text);

    if (minPrice == null || maxPrice == null) {
      TopNotificationService.showError(
        context: context,
        message: AppTranslations.getString(context, 'please_enter_valid_number'),
      );
      return;
    }

    if (minPrice > maxPrice) {
      TopNotificationService.showError(
        context: context,
        message: AppTranslations.getString(
          context,
          'min_price_cannot_be_greater',
        ),
      );
      return;
    }

    context.read<SalonServicesBloc>().add(
          FilterSalonServices(
            minPrice: minPrice,
            maxPrice: maxPrice,
          ),
        );

    widget.onFilterApplied?.call(minPrice, maxPrice);
    Navigator.of(context).pop();
  }

  void _clearAndClose() {
    widget.onFilterApplied?.call(null, null);
    context.read<SalonServicesBloc>().add(LoadSalonServices());
    Navigator.of(context).pop();
  }

  InputDecoration _inputDecoration({
    required String hintText,
    required SalonUiTheme ui,
  }) {
    final textColor = ui.isDark ? Colors.white : Colors.black;
    final hintColor = ui.isDark ? Colors.white54 : Colors.black;
    final borderColor = ui.isDark ? ui.borderSubtle : Colors.black;

    return InputDecoration(
      hintText: hintText,
      hintStyle: TextStyle(
        color: hintColor,
        fontSize: 16,
      ),
      filled: true,
      fillColor: Colors.transparent,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(_ServiceFilterUi.radius),
        borderSide: BorderSide(color: borderColor, width: 1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(_ServiceFilterUi.radius),
        borderSide: BorderSide(color: borderColor, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(_ServiceFilterUi.radius),
        borderSide: BorderSide(color: textColor, width: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ui = SalonUiTheme.from(context.read<ThemeBloc>().state.brightness);
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final textColor = ui.isDark ? Colors.white : Colors.black;
    final secondaryColor = ui.isDark ? Colors.white70 : Colors.black;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        decoration: BoxDecoration(
          color: ui.bg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Stack(
          children: [
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 170,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(24)),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: ui.sheetHeaderGradient,
                    stops: const [0.0, 0.35, 0.7, 1.0],
                  ),
                ),
              ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 18),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            AppTranslations.getString(
                              context,
                              'filter_services',
                            ),
                            style: TextStyle(
                              color: textColor,
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () => Navigator.of(context).pop(),
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: ui.sheetOverlayButton,
                              borderRadius: BorderRadius.circular(
                                _ServiceFilterUi.buttonRadius,
                              ),
                              border: Border.all(
                                color: ui.isDark ? ui.cardBorder : Colors.black,
                                width: 1,
                              ),
                            ),
                            child: Icon(
                              LucideIcons.x,
                              color: textColor,
                              size: 18,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Text(
                      AppTranslations.getString(context, 'service_price'),
                      style: TextStyle(
                        color: textColor,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                AppTranslations.getString(context, 'min'),
                                style: TextStyle(
                                  color: secondaryColor,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextField(
                                controller: minPriceController,
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                ],
                                style: TextStyle(color: textColor),
                                cursorColor: textColor,
                                decoration: _inputDecoration(
                                  hintText: '0',
                                  ui: ui,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                AppTranslations.getString(context, 'max'),
                                style: TextStyle(
                                  color: secondaryColor,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextField(
                                controller: maxPriceController,
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                ],
                                style: TextStyle(color: textColor),
                                cursorColor: textColor,
                                decoration: _inputDecoration(
                                  hintText: '1000',
                                  ui: ui,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _clearAndClose,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: textColor,
                              side: BorderSide(
                                color: ui.isDark
                                    ? ui.outlinedButtonBorder
                                    : Colors.black,
                                width: 1,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  _ServiceFilterUi.radius,
                                ),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            child: Text(
                              AppTranslations.getString(context, 'clear'),
                              style: TextStyle(
                                color: textColor,
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _applyFilter,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: ui.primaryButtonBg,
                              foregroundColor: ui.primaryButtonFg,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  _ServiceFilterUi.radius,
                                ),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            child: Text(
                              AppTranslations.getString(context, 'apply'),
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
