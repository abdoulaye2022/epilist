import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'dart:async';

class BarcodeScannerScreen extends StatefulWidget {
  final int listId;

  const BarcodeScannerScreen({
    super.key,
    required this.listId,
  });

  @override
  State<BarcodeScannerScreen> createState() => _BarcodeScannerScreenState();
}

class _BarcodeScannerScreenState extends State<BarcodeScannerScreen>
    with SingleTickerProviderStateMixin {
  late MobileScannerController controller;
  bool isProcessing = false;
  String? scannedCode;
  late AnimationController _animationController;
  late Animation<double> _scanLineAnimation;
  bool _isTorchOn = false;

  @override
  void initState() {
    super.initState();
    controller = MobileScannerController(
      detectionSpeed: DetectionSpeed.noDuplicates,
      facing: CameraFacing.back,
      torchEnabled: false,
    );

    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _scanLineAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) async {
    if (isProcessing) return;

    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final barcode = barcodes.first;
    final code = barcode.rawValue;

    if (code == null || code.isEmpty) return;

    setState(() {
      isProcessing = true;
      scannedCode = code;
    });

    // Haptic feedback
    await controller.stop();

    // Attendre un peu pour l'animation
    await Future.delayed(const Duration(milliseconds: 500));

    if (mounted) {
      // Retourner le code scanné
      Navigator.pop(context, code);
    }
  }

  void _toggleTorch() async {
    await controller.toggleTorch();
    setState(() {
      _isTorchOn = !_isTorchOn;
    });
  }

  void _switchCamera() async {
    await controller.switchCamera();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Camera preview
          MobileScanner(
            controller: controller,
            onDetect: _onDetect,
          ),

          // Overlay avec zone de scan
          CustomPaint(
            painter: ScannerOverlayPainter(
              scanLineAnimation: _scanLineAnimation,
              isScanning: !isProcessing,
            ),
            child: Container(),
          ),

          // Top bar
          SafeArea(
            child: Column(
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withOpacity(0.7),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Scanner le code-barres',
                              style: theme.textTheme.titleLarge?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Alignez le code-barres dans le cadre',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const Spacer(),

                // Instructions au centre
                if (!isProcessing)
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 32),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.qr_code_scanner,
                          color: Colors.white,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Flexible(
                          child: Text(
                            'Positionnez le code-barres dans la zone de scan',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: Colors.white,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  ),

                // Processing indicator
                if (isProcessing)
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.0, end: 1.0),
                    duration: const Duration(milliseconds: 500),
                    builder: (context, value, child) {
                      return Transform.scale(
                        scale: value,
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 32),
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.9),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.green.withOpacity(0.3),
                                blurRadius: 20,
                                spreadRadius: 5,
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.check_circle,
                                color: Colors.white,
                                size: 48,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Code détecté!',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (scannedCode != null) ...[
                                const SizedBox(height: 8),
                                Text(
                                  scannedCode!,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: Colors.white70,
                                    fontFamily: 'monospace',
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  ),

                const Spacer(),

                // Bottom controls
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.black.withOpacity(0.7),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Torch button
                      _buildControlButton(
                        icon: _isTorchOn ? Icons.flash_on : Icons.flash_off,
                        label: 'Flash',
                        onTap: _toggleTorch,
                        isActive: _isTorchOn,
                      ),

                      // Manual entry button
                      _buildControlButton(
                        icon: Icons.keyboard,
                        label: 'Saisie manuelle',
                        onTap: () {
                          Navigator.pop(context);
                        },
                      ),

                      // Switch camera button
                      _buildControlButton(
                        icon: Icons.flip_camera_android,
                        label: 'Changer',
                        onTap: _switchCamera,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isActive = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isActive
              ? Colors.green.withOpacity(0.3)
              : Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isActive ? Colors.green : Colors.white.withOpacity(0.3),
            width: 1.5,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isActive ? Colors.green : Colors.white,
              size: 28,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isActive ? Colors.green : Colors.white,
                fontSize: 12,
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Custom painter pour l'overlay de scan
class ScannerOverlayPainter extends CustomPainter {
  final Animation<double> scanLineAnimation;
  final bool isScanning;

  ScannerOverlayPainter({
    required this.scanLineAnimation,
    required this.isScanning,
  }) : super(repaint: scanLineAnimation);

  @override
  void paint(Canvas canvas, Size size) {
    final double scanAreaSize = size.width * 0.7;
    final double left = (size.width - scanAreaSize) / 2;
    final double top = (size.height - scanAreaSize) / 2;
    final Rect scanRect = Rect.fromLTWH(left, top, scanAreaSize, scanAreaSize);

    // Draw dark overlay
    final Paint overlayPaint = Paint()
      ..color = Colors.black.withOpacity(0.5);

    canvas.drawPath(
      Path.combine(
        PathOperation.difference,
        Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height)),
        Path()
          ..addRRect(
            RRect.fromRectAndRadius(scanRect, const Radius.circular(24)),
          ),
      ),
      overlayPaint,
    );

    // Draw corner brackets
    final Paint cornerPaint = Paint()
      ..color = Colors.green
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final double cornerLength = 30;

    // Top-left corner
    canvas.drawPath(
      Path()
        ..moveTo(left + cornerLength, top)
        ..lineTo(left, top)
        ..lineTo(left, top + cornerLength),
      cornerPaint,
    );

    // Top-right corner
    canvas.drawPath(
      Path()
        ..moveTo(left + scanAreaSize - cornerLength, top)
        ..lineTo(left + scanAreaSize, top)
        ..lineTo(left + scanAreaSize, top + cornerLength),
      cornerPaint,
    );

    // Bottom-left corner
    canvas.drawPath(
      Path()
        ..moveTo(left, top + scanAreaSize - cornerLength)
        ..lineTo(left, top + scanAreaSize)
        ..lineTo(left + cornerLength, top + scanAreaSize),
      cornerPaint,
    );

    // Bottom-right corner
    canvas.drawPath(
      Path()
        ..moveTo(left + scanAreaSize - cornerLength, top + scanAreaSize)
        ..lineTo(left + scanAreaSize, top + scanAreaSize)
        ..lineTo(left + scanAreaSize, top + scanAreaSize - cornerLength),
      cornerPaint,
    );

    // Draw scanning line
    if (isScanning) {
      final double lineY =
          top + (scanAreaSize * scanLineAnimation.value);
      final Paint linePaint = Paint()
        ..shader = LinearGradient(
          colors: [
            Colors.transparent,
            Colors.green.withOpacity(0.8),
            Colors.transparent,
          ],
        ).createShader(Rect.fromLTWH(left, lineY - 2, scanAreaSize, 4))
        ..strokeWidth = 2;

      canvas.drawLine(
        Offset(left + 20, lineY),
        Offset(left + scanAreaSize - 20, lineY),
        linePaint,
      );

      // Glow effect
      final Paint glowPaint = Paint()
        ..shader = LinearGradient(
          colors: [
            Colors.transparent,
            Colors.green.withOpacity(0.3),
            Colors.transparent,
          ],
        ).createShader(Rect.fromLTWH(left, lineY - 10, scanAreaSize, 20))
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);

      canvas.drawLine(
        Offset(left + 20, lineY),
        Offset(left + scanAreaSize - 20, lineY),
        glowPaint,
      );
    }
  }

  @override
  bool shouldRepaint(ScannerOverlayPainter oldDelegate) {
    return scanLineAnimation != oldDelegate.scanLineAnimation ||
        isScanning != oldDelegate.isScanning;
  }
}
