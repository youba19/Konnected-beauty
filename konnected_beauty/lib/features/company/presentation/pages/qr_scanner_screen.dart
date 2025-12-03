import 'package:flutter/material.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/translations/app_translations.dart';
import '../../../../core/services/api/qr_scan_service.dart';
import '../../../../widgets/common/top_notification_banner.dart';
import 'order_detail_screen.dart';

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
        // Show success message
        TopNotificationService.showSuccess(
          context: context,
          message: result['message'] ??
              AppTranslations.getString(
                  context, 'voucher_scanned_successfully'),
        );

        // Navigate to order details if we have orderId
        if (result['data'] != null && result['data']['orderId'] != null) {
          final orderId = result['data']['orderId'];
          print('🔍 QR Scan successful, orderId: $orderId');

          if (mounted) {
            // Create a minimal order object with just the ID for navigation
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          AppTranslations.getString(context, 'scan_qr_code'),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          // QR Scanner View (only show if camera working)
          if (_cameraWorking)
            QRView(
              key: qrKey,
              onQRViewCreated: _onQRViewCreated,
              overlay: QrScannerOverlayShape(
                borderColor: AppTheme.greenColor,
                borderRadius: 10,
                borderLength: 30,
                borderWidth: 10,
                cutOutSize: 250,
              ),
            )
          else
            // Camera not working overlay
            Container(
              color: Colors.black,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.camera_alt,
                      size: 80,
                      color: Colors.white,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      AppTranslations.getString(context, 'initializing_camera'),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _status,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 30),
                    ElevatedButton(
                      onPressed: _retryCamera,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.greenColor,
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
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(
                        AppTranslations.getString(context, 'go_back'),
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Processing overlay
          if (_isProcessing)
            Container(
              color: Colors.black.withOpacity(0.7),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(
                      color: AppTheme.greenColor,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      AppTranslations.getString(context, 'processing_voucher'),
                      style: const TextStyle(
                        color: Colors.white,
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
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.qr_code_scanner,
                      color: AppTheme.greenColor,
                      size: 32,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      AppTranslations.getString(context, 'scan_instructions'),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      AppTranslations.getString(
                          context, 'scan_instructions_detail'),
                      style: const TextStyle(
                        color: Colors.white70,
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
    );
  }
}
