import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/theme/salon_ui_theme.dart';
import '../../../../core/bloc/theme/theme_bloc.dart';
import '../../../../core/translations/app_translations.dart';
import '../../../../core/bloc/salon_services/salon_services_bloc.dart';
import '../../../../widgets/common/top_notification_banner.dart';
import 'edit_service_screen.dart';

abstract final class _ServiceDetailsUi {
  static const double horizontalPadding = 16;
  static const double imageRadius = 16;
  static const double buttonSize = 48;
  static const double buttonRadius = 14;
}

class ServiceDetailsScreen extends StatefulWidget {
  final String serviceId;
  final String serviceName;
  final String servicePrice;
  final String serviceDescription;
  final bool showSuccessMessage;

  const ServiceDetailsScreen({
    super.key,
    required this.serviceId,
    required this.serviceName,
    required this.servicePrice,
    required this.serviceDescription,
    this.showSuccessMessage = false,
  });

  @override
  State<ServiceDetailsScreen> createState() => _ServiceDetailsScreenState();
}

class _ServiceDetailsScreenState extends State<ServiceDetailsScreen> {
  @override
  void initState() {
    super.initState();
    context.read<SalonServicesBloc>().add(LoadSalonServices());
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeBloc, ThemeState>(
      builder: (context, themeState) {
        final ui = SalonUiTheme.from(themeState.brightness);

        return BlocListener<SalonServicesBloc, SalonServicesState>(
          listener: (context, state) {
            if (state is SalonServiceDeleted) {
              TopNotificationService.showSuccess(
                context: context,
                message:
                    '${AppTranslations.getString(context, 'service_deleted')} - ${widget.serviceName}',
              );
              Navigator.of(context).pop();
            } else if (state is SalonServiceUpdated) {
              TopNotificationService.showSuccess(
                context: context,
                message: AppTranslations.getString(context, 'service_updated'),
              );
              setState(() {});
            } else if (state is SalonServicesError) {
              TopNotificationService.showError(
                context: context,
                message: state.message,
              );
            }
          },
          child: AnnotatedRegion<SystemUiOverlayStyle>(
            value: ui.systemOverlay,
            child: ColoredBox(
              color: ui.bg,
              child: Scaffold(
                backgroundColor: Colors.transparent,
                body: SafeArea(
                  top: false,
                  child: BlocBuilder<SalonServicesBloc, SalonServicesState>(
                    builder: (context, state) {
                      final serviceData = _resolveServiceData(state);
                      final topInset = MediaQuery.paddingOf(context).top;
                      final isDeleting = state is SalonServiceDeleting;

                      return Stack(
                        children: [
                          Positioned(
                            top: 0,
                            left: 0,
                            right: 0,
                            height: topInset + 168,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: ui.headerGradient,
                                  stops: ui.headerStops,
                                ),
                              ),
                            ),
                          ),
                          SingleChildScrollView(
                            padding: EdgeInsets.fromLTRB(
                              _ServiceDetailsUi.horizontalPadding,
                              topInset + 8,
                              _ServiceDetailsUi.horizontalPadding,
                              24,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildTopBar(
                                  ui: ui,
                                  isDeleting: isDeleting,
                                  onEdit: () => _navigateToEdit(serviceData),
                                  onDelete: () => _showDeleteConfirmation(ui),
                                ),
                                if (serviceData.imageUrls.isNotEmpty) ...[
                                  const SizedBox(height: 14),
                                  _buildPicturesCarousel(
                                    ui,
                                    serviceData.imageUrls,
                                  ),
                                ],
                                const SizedBox(height: 18),
                                Text(
                                  serviceData.name,
                                  style: TextStyle(
                                    color: ui.textPrimary,
                                    fontSize: 24,
                                    fontWeight: FontWeight.w700,
                                    height: 1.15,
                                    letterSpacing: -0.2,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  serviceData.price,
                                  style: TextStyle(
                                    color: ui.textPrimary,
                                    fontSize: 17,
                                    fontWeight: FontWeight.w400,
                                    height: 1.2,
                                  ),
                                ),
                                if (serviceData.description
                                    .trim()
                                    .isNotEmpty) ...[
                                  const SizedBox(height: 16),
                                  _buildDescriptionContent(
                                    ui,
                                    serviceData.description,
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  _ServiceViewData _resolveServiceData(SalonServicesState state) {
    var name = widget.serviceName;
    var price = _formatPrice(widget.servicePrice);
    var description = widget.serviceDescription;
    var imageUrls = <String>[];

    if (state is SalonServicesLoaded) {
      final updatedService = state.services.firstWhere(
        (service) => service['id'] == widget.serviceId,
        orElse: () => {
          'name': widget.serviceName,
          'price': widget.servicePrice,
          'description': widget.serviceDescription,
        },
      );

      name = updatedService['name']?.toString() ?? widget.serviceName;
      final rawPrice = updatedService['price'];
      if (rawPrice != null && rawPrice.toString().isNotEmpty) {
        price = _formatPrice(rawPrice.toString());
      }
      description =
          updatedService['description']?.toString() ?? widget.serviceDescription;

      final pictures = updatedService['pictures'] as List<dynamic>? ?? [];
      imageUrls = pictures
          .map((pic) => (pic['url'] ?? pic['imageUrl'] ?? '').toString())
          .where((url) => url.isNotEmpty)
          .toList();
    }

    return _ServiceViewData(
      name: name,
      price: price,
      description: description,
      imageUrls: imageUrls,
    );
  }

  String _formatPrice(String raw) {
    final cleaned = raw
        .replaceAll(' EURO (TTC)', '')
        .replaceAll(' EUR (TTC)', '')
        .replaceAll('(TTC)', '')
        .trim();
    if (cleaned.contains('€')) return cleaned;
    return '$cleaned €';
  }

  Widget _buildTopBar({
    required SalonUiTheme ui,
    required bool isDeleting,
    required VoidCallback onEdit,
    required VoidCallback onDelete,
  }) {
    return Row(
      children: [
        _actionIconButton(
          ui: ui,
          icon: LucideIcons.arrowLeft,
          onTap: () => Navigator.of(context).pop(),
        ),
        const Spacer(),
        _actionIconButton(
          ui: ui,
          icon: LucideIcons.pencil,
          onTap: onEdit,
        ),
        const SizedBox(width: 10),
        _actionIconButton(
          ui: ui,
          icon: LucideIcons.trash2,
          onTap: isDeleting ? null : onDelete,
          isLoading: isDeleting,
        ),
      ],
    );
  }

  Widget _actionIconButton({
    required SalonUiTheme ui,
    required IconData icon,
    required VoidCallback? onTap,
    bool isLoading = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: _ServiceDetailsUi.buttonSize,
        height: _ServiceDetailsUi.buttonSize,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [ui.buttonFillTop, ui.buttonFillBottom],
          ),
          borderRadius: BorderRadius.circular(_ServiceDetailsUi.buttonRadius),
          border: ui.isDark
              ? null
              : Border.all(color: ui.cardBorder, width: 1),
        ),
        alignment: Alignment.center,
        child: isLoading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Icon(
                icon,
                color: ui.buttonIcon,
                size: 22,
              ),
      ),
    );
  }

  void _navigateToEdit(_ServiceViewData data) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => BlocProvider.value(
          value: context.read<SalonServicesBloc>(),
          child: EditServiceScreen(
            serviceId: widget.serviceId,
            serviceName: data.name,
            servicePrice: data.price,
            serviceDescription: data.description,
          ),
        ),
      ),
    );
  }

  Widget _buildPicturesCarousel(SalonUiTheme ui, List<String> imageUrls) {
    final placeholder = ui.isDark
        ? const Color(0xFF1A1A1A)
        : const Color(0xFFE5E7EB);
    final iconColor = ui.isDark ? Colors.white54 : ui.textMuted;

    return SizedBox(
      height: 115,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: imageUrls.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          return ClipRRect(
            borderRadius: BorderRadius.circular(_ServiceDetailsUi.imageRadius),
            child: SizedBox(
              width: 115,
              height: 115,
              child: Image.network(
                imageUrls[index],
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return ColoredBox(
                    color: placeholder,
                    child: Center(
                      child: Icon(
                        Icons.image,
                        color: iconColor,
                        size: 28,
                      ),
                    ),
                  );
                },
                loadingBuilder: (context, child, progress) {
                  if (progress == null) return child;
                  return ColoredBox(
                    color: placeholder,
                    child: Center(
                      child: SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: ui.textMuted,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDescriptionContent(SalonUiTheme ui, String description) {
    final lines = description
        .split(RegExp(r'\r?\n'))
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();

    if (lines.isEmpty) return const SizedBox.shrink();

    final widgets = <Widget>[];
    var inBulletSection = false;

    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      final isSubheading = line.endsWith(':');
      final isExplicitBullet = _isExplicitBullet(line);

      if (isSubheading) {
        inBulletSection = true;
        if (widgets.isNotEmpty) widgets.add(const SizedBox(height: 12));
        widgets.add(_buildSubheading(ui, line));
        continue;
      }

      if (isExplicitBullet || (inBulletSection && _looksLikeBullet(line))) {
        inBulletSection = true;
        widgets.add(_buildBullet(ui, _stripBulletPrefix(line)));
        continue;
      }

      inBulletSection = false;
      if (widgets.isNotEmpty) widgets.add(const SizedBox(height: 12));
      widgets.add(_buildParagraph(ui, line));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widgets,
    );
  }

  bool _isExplicitBullet(String line) {
    return line.startsWith('•') ||
        line.startsWith('- ') ||
        line.startsWith('* ') ||
        RegExp(r'^\d+\.\s').hasMatch(line);
  }

  bool _looksLikeBullet(String line) {
    if (line.startsWith('(')) return false;
    return line.length <= 90;
  }

  String _stripBulletPrefix(String line) {
    return line
        .replaceFirst(RegExp(r'^[•\-*]\s*'), '')
        .replaceFirst(RegExp(r'^\d+\.\s*'), '')
        .trim();
  }

  Widget _buildParagraph(SalonUiTheme ui, String text) {
    return Text(
      text,
      style: TextStyle(
        color: ui.textSecondary,
        fontSize: 15,
        fontWeight: FontWeight.w400,
        height: 1.55,
      ),
    );
  }

  Widget _buildSubheading(SalonUiTheme ui, String text) {
    return Text(
      text,
      style: TextStyle(
        color: ui.textPrimary,
        fontSize: 15,
        fontWeight: FontWeight.w600,
        height: 1.45,
      ),
    );
  }

  Widget _buildBullet(SalonUiTheme ui, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 8, right: 10),
            child: Container(
              width: 5,
              height: 5,
              decoration: BoxDecoration(
                color: ui.textPrimary,
                shape: BoxShape.circle,
              ),
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: ui.textSecondary,
                fontSize: 15,
                fontWeight: FontWeight.w400,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(SalonUiTheme ui) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (BuildContext sheetContext) {
        final bottomSafe = MediaQuery.paddingOf(sheetContext).bottom;

        return Container(
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
                height: 160,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(24),
                    ),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: ui.sheetHeaderGradient,
                      stops: const [0.0, 0.35, 0.7, 1.0],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(20, 28, 20, 18 + bottomSafe),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppTranslations.getString(
                        sheetContext,
                        'delete_service',
                      ),
                      style: TextStyle(
                        color: ui.textPrimary,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '${AppTranslations.getString(sheetContext, 'delete_service_confirmation')} "${widget.serviceName}"?',
                      style: TextStyle(
                        color: ui.textSecondary,
                        fontSize: 15,
                        fontWeight: FontWeight.w400,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 28),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(sheetContext).pop();
                          context.read<SalonServicesBloc>().add(
                                DeleteSalonService(
                                  serviceId: widget.serviceId,
                                  serviceName: widget.serviceName,
                                ),
                              );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: ui.primaryButtonBg,
                          foregroundColor: ui.primaryButtonFg,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Text(
                          AppTranslations.getString(sheetContext, 'delete'),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(sheetContext).pop(),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: ui.textPrimary,
                          side: BorderSide(color: ui.borderSubtle, width: 1),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Text(
                          AppTranslations.getString(sheetContext, 'cancel'),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ServiceViewData {
  final String name;
  final String price;
  final String description;
  final List<String> imageUrls;

  const _ServiceViewData({
    required this.name,
    required this.price,
    required this.description,
    required this.imageUrls,
  });
}
