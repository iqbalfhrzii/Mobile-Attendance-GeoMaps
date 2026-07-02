import 'dart:io';

import 'package:camera/camera.dart';
import 'package:path_provider/path_provider.dart';

/// Service for camera operations (front camera selfie).
class CameraService {
  CameraController? _controller;
  List<CameraDescription>? _cameras;

  /// The active camera controller.
  CameraController? get controller => _controller;

  /// Whether the controller is initialized and ready.
  bool get isReady => _controller?.value.isInitialized ?? false;

  /// Initialize the front camera.
  /// Returns the [CameraController] for the widget to use.
  Future<CameraController> initFrontCamera() async {
    _cameras ??= await availableCameras();

    // Find front camera
    final frontCamera = _cameras!.firstWhere(
      (c) => c.lensDirection == CameraLensDirection.front,
      orElse: () => _cameras!.first,
    );

    _controller = CameraController(
      frontCamera,
      ResolutionPreset.medium,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );

    await _controller!.initialize();
    return _controller!;
  }

  /// Take a photo and save to app directory.
  /// Returns the saved file path.
  Future<String> takePhoto() async {
    if (_controller == null || !_controller!.value.isInitialized) {
      throw Exception('Kamera belum diinisialisasi');
    }

    final xFile = await _controller!.takePicture();

    // Save to app directory
    final dir = await getApplicationDocumentsDirectory();
    final photoDir = Directory('${dir.path}/attendance_photos');
    if (!await photoDir.exists()) {
      await photoDir.create(recursive: true);
    }

    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final savedPath = '${photoDir.path}/selfie_$timestamp.jpg';
    final savedFile = await File(xFile.path).copy(savedPath);

    return savedFile.path;
  }

  /// Dispose the camera controller.
  void dispose() {
    _controller?.dispose();
    _controller = null;
  }
}
