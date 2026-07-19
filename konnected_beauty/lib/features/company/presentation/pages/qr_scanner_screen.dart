import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/salon_ui_theme.dart';
import '../../../../core/translations/app_translations.dart';
import '../../../../core/services/api/qr_scan_service.dart';
import '../../../../widgets/common/top_notification_banner.dart';
import 'order_detail_screen.dart';

abstract final class _QrScannerUi {
  static const double buttonSize = 48;
  static const double buttonRadius = 14;
}

class QRScannerScreen extends StatefulWidget {
  const QRScannerScreen({super.key});

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  QRViewController? controller;
  bool _isScanning = true;
  bool _isProcessing = false;
  bool _cameraWorking = false;
  String _status = '';

  @override
  void initState() {
    super.initState();
    print('🔍 === QR SCANNER SCREEN INITIALIZED ===');
    // Ultra force camera access immediately
    _ultraForceCameraAccess();
  }

  Future<void> _ultraForceCameraAccess() async {
    print('🔍 === ULTRA FORCE CAMERA ACCESS ===');

    setState(() {
      _status = AppTranslations.getString(context, 'opening_qr_scanner');
      _cameraWorking = true; // Directly enable QR scanner
    });

    // Just open QR scanner directly - no double camera opening
    print('📷 ULTRA FORCE: Opening QR scanner directly...');
  }

  Future<void> _retryCamera() async {
    await _ultraForceCameraAccess();
  }

  /// Shows the scan result dialog with the API response message and optional availableDate.
  Future<void> _showScanResultDialog({
    required String message,
    String? availableDate,
  }) async {
    final ui = SalonUiTheme.of(context);
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext ctx) {
        return AlertDialog(
          backgroundColor: ui.isDark ? AppTheme.primaryColor : ui.card,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: ui.isDark
                ? BorderSide.none
                : BorderSide(color: ui.cardBorder, width: 1),
          ),
          title: Text(
            message,
            style: TextStyle(
              color: ui.isDark ? Colors.white : Colors.black,
              fontSize: 18,
            ),
            textAlign: TextAlign.center,
          ),
          content: availableDate != null && availableDate.isNotEmpty
              ? Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${AppTranslations.getString(context, "qr_scan_available_date")}: $availableDate',
                      style: TextStyle(
                        color: ui.isDark ? Colors.white70 : Colors.black,
                        fontSize: 14,
                      ),
                    ),
                  ],
                )
              : null,
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(
                'OK',
                style: TextStyle(
                  color: ui.isDark ? AppTheme.greenColor : SalonUiTheme.accentBlue,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  void _onQRViewCreated(QRViewController controller) {
    this.controller = controller;
    controller.scannedDataStream.listen((scanData) {
      if (_isScanning && !_isProcessing) {
        _processQRCode(scanData.code);
      }
    });
  }

  Future<void> _processQRCode(String? qrCode) async {
    if (qrCode == null || qrCode.isEmpty) return;

    setState(() {
      _isScanning = false;
      _isProcessing = true;
    });

    // Stop the camera
    await controller?.pauseCamera();

    print('🔍 === PROCESSING QR CODE ===');
    print('📱 QR Code: $qrCode');

    try {
      // Call the API to scan the voucher
      final result = await QRScanService.scanVoucher(qrCode);

      if (result['success'] == true) {
        // Map API response to design messages: 200 → "Success", 201 → "Order completed and transfers scheduled"
        final statusCode = result['statusCode'] as int?;
        final apiMessage = result['message'] as String?;
        String displayMessage;
        if (statusCode == 201 ||
            (apiMessage != null &&
                apiMessage.toLowerCase().contains('transfers scheduled'))) {
          displayMessage = AppTranslations.getString(
              context, 'qr_scan_response_order_completed');
        } else {
          displayMessage = AppTranslations.getString(
              context, 'qr_scan_response_success');
        }

        final data = result['data'] as Map<String, dynamic>?;
        final availableDate = data?['availableDate'];

        // Show response in a dialog (message + optional availableDate), then navigate
        if (mounted) {
          await _showScanResultDialog(
            message: displayMessage,
            availableDate: availableDate?.toString(),
          );
        }

        TopNotificationService.showSuccess(
          context: context,
          message: displayMessage,
        );

        // Navigate to order details if we have orderId
        if (result['data'] != null && result['data']['orderId'] != null) {
          final orderId = result['data']['orderId'];
          print('🔍 QR Scan successful, orderId: $orderId');

          if (mounted) {
            final orderData = {'id': orderId};
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (context) => OrderDetailScreen(order: orderData),
              ),
            );
          }
        } else {
          // If no orderId, show error and resume scanning
          TopNotificationService.showError(
            context: context,
            message: AppTranslations.getString(context, 'order_id_not_found'),
          );

          Future.delayed(const Duration(seconds: 2), () {
            if (mounted) {
              setState(() {
                _isScanning = true;
                _isProcessing = false;
              });
              controller?.resumeCamera();
            }
          });
        }
      } else {
        // Show error message
        TopNotificationService.showError(
          context: context,
          message: result['message'] ??
              AppTranslations.getString(context, 'failed_to_scan_voucher'),
        );

        // Resume scanning after a delay
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            setState(() {
              _isScanning = true;
              _isProcessing = false;
            });
            controller?.resumeCamera();
          }
        });
      }
    } catch (e) {
      print('❌ Error processing QR code: $e');
      TopNotificationService.showError(
        context: context,
        message: AppTranslations.getString(context, 'error_processing_qr_code'),
      );

      // Resume scanning after a delay
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          setState(() {
            _isScanning = true;
            _isProcessing = false;
          });
          controller?.resumeCamera();
        }
      });
    }
  }

  Widget _buildBackButton(SalonUiTheme ui) {
    return GestureDetector(
      onTap: () => Navigator.of(context).pop(),
      child: Container(
        width: _QrScannerUi.buttonSize,
        height: _QrScannerUi.buttonSize,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [ui.buttonFillTop, ui.buttonFillBottom],
          ),
          borderRadius: BorderRadius.circular(_QrScannerUi.buttonRadius),
          border: ui.isDark
              ? null
              : Border.all(color: ui.cardBorder, width: 1),
        ),
        alignment: Alignment.center,
        child: Icon(
          LucideIcons.arrowLeft,
          color: ui.buttonIcon,
          size: 22,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ui = SalonUiTheme.of(context);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: ui.systemOverlay,
      child: Scaffold(
        backgroundColor: ui.isDark ? Colors.black : ui.bg,
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: Row(
                  children: [
                    _buildBackButton(ui),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        AppTranslations.getString(context, 'scan_qr_code'),
                        style: TextStyle(
                          color: ui.isDark ? Colors.white : Colors.black,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ClipRRect(
                  borderRadius: ui.isDark
                      ? BorderRadius.zero
                      : const BorderRadius.vertical(top: Radius.circular(20)),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // QR Scanner View (only show if camera working)
                      if (_cameraWorking)
                        QRView(
                          key: qrKey,
                          onQRViewCreated: _onQRViewCreated,
                          overlay: QrScannerOverlayShape(
                            borderColor: ui.isDark
                                ? AppTheme.greenColor
                                : SalonUiTheme.accentBlue,
                            borderRadius: 10,
                            borderLength: 30,
                            borderWidth: 10,
                            cutOutSize: 250,
                          ),
                        )
                      else
                        // Camera not working overlay
                        Container(
                          color: ui.isDark ? Colors.black : ui.bg,
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.camera_alt,
                                  size: 80,
                                  color: ui.isDark
                                      ? Colors.white
                                      : Colors.black,
                                ),
                                const SizedBox(height: 20),
                                Text(
                                  AppTranslations.getString(
                                      context, 'initializing_camera'),
                                  style: TextStyle(
                                    color: ui.isDark
                                        ? Colors.white
                                        : Colors.black,
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  _status,
                                  style: TextStyle(
                                    color: ui.isDark
                                        ? Colors.white70
                                        : Colors.black,
                                    fontSize: 16,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 30),
                                ElevatedButton(
                                  onPressed: _retryCamera,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: ui.isDark
                                        ? AppTheme.greenColor
                                        : SalonUiTheme.accentBlue,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 30,
                                      vertical: 15,
                                    ),
                                  ),
                                  child: Text(
                                    AppTranslations.getString(
                                        context, 'open_camera_directly'),
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                TextButton(
                                  onPressed: () =>
                                      Navigator.of(context).pop(),
                                  child: Text(
                                    AppTranslations.getString(
                                        context, 'go_back'),
                                    style: TextStyle(
                                      color: ui.isDark
                                          ? Colors.white70
                                          : Colors.black,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                      // Processing overlay
                      if (_isProcessing)
                        Container(
                          color: (ui.isDark ? Colors.black : Colors.white)
                              .withValues(alpha: 0.75),
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                CircularProgressIndicator(
                                  color: ui.isDark
                                      ? AppTheme.greenColor
                                      : SalonUiTheme.accentBlue,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  AppTranslations.getString(
                                      context, 'processing_voucher'),
                                  style: TextStyle(
                                    color: ui.isDark
                                        ? Colors.white
                                        : Colors.black,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                      // Instructions (only show if camera working)
                      if (_cameraWorking)
                        Positioned(
                          bottom: 50,
                          left: 20,
                          right: 20,
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: ui.isDark
                                  ? Colors.black.withValues(alpha: 0.7)
                                  : Colors.white.withValues(alpha: 0.95),
                              borderRadius: BorderRadius.circular(12),
                              border: ui.isDark
                                  ? null
                                  : Border.all(
                                      color: ui.cardBorder, width: 1),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.qr_code_scanner,
                                  color: ui.isDark
                                      ? AppTheme.greenColor
                                      : SalonUiTheme.accentBlue,
                                  size: 32,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  AppTranslations.getString(
                                      context, 'scan_instructions'),
                                  style: TextStyle(
                                    color: ui.isDark
                                        ? Colors.white
                                        : Colors.black,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  AppTranslations.getString(
                                      context, 'scan_instructions_detail'),
                                  style: TextStyle(
                                    color: ui.isDark
                                        ? Colors.white70
                                        : Colors.black,
                                    fontSize: 14,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
