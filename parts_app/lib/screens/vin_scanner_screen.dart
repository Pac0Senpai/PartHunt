import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:permission_handler/permission_handler.dart';

class VinScannerScreen extends StatefulWidget {
  const VinScannerScreen({Key? key}) : super(key: key);

  @override
  State<VinScannerScreen> createState() => _VinScannerScreenState();
}

class _VinScannerScreenState extends State<VinScannerScreen> {
  CameraController? _cameraController;
  bool _isPermissionGranted = false;
  bool _isProcessing = false;
  bool _isReadyToScan = false;
  final TextRecognizer _textRecognizer = TextRecognizer(
    script: TextRecognitionScript.latin,
  );

  @override
  void initState() {
    super.initState();
    _requestCameraPermission();
  }

  Future<void> _requestCameraPermission() async {
    final status = await Permission.camera.request();
    setState(() {
      _isPermissionGranted = status.isGranted;
    });
    if (_isPermissionGranted) {
      _initializeCamera();
    }
  }

  Future<void> _initializeCamera() async {
    final cameras = await availableCameras();
    if (cameras.isEmpty) {
      debugPrint("Δεν βρέθηκαν διαθέσιμες κάμερες.");
      return;
    }

    final firstCamera = cameras.first;

    _cameraController = CameraController(
      firstCamera,
      ResolutionPreset.medium,
      enableAudio: false,
    );

    await _cameraController?.initialize();
    if (!mounted) return;

    setState(() {});

    // Καθυστέρηση 1 δευτερολέπτου για να καθαρίσει το παλιό καρέ
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        _isReadyToScan = true;
      }
    });

    _cameraController?.startImageStream((image) {
      if (!_isProcessing && _isReadyToScan) {
        _isProcessing = true;
        _processCameraImage(image);
      }
    });
  }

  Future<void> _processCameraImage(CameraImage image) async {
    try {
      final inputImage = _inputImageFromCameraImage(image);
      if (inputImage == null) {
        _isProcessing = false;
        return;
      }

      final RecognizedText recognizedText = await _textRecognizer.processImage(
        inputImage,
      );

      final rawText = recognizedText.text.trim();

      if (rawText.isNotEmpty) {
        debugPrint("CAMERA FRAME READ: '$rawText'");

        final words = rawText.toUpperCase().split(RegExp(r'\s+'));
        final vinRegEx = RegExp(r'^[A-HJ-NPR-Z0-9]{17}$');

        for (String word in words) {
          final cleanWord = word.replaceAll(RegExp(r'[^A-Z0-9]'), '');

          if (vinRegEx.hasMatch(cleanWord)) {
            debugPrint("ΕΠΙΤΥΧΙΑ! Βρέθηκε VIN: $cleanWord");
            if (mounted) {
              _cameraController?.stopImageStream();
              Navigator.pop(context, cleanWord);
              return;
            }
          }
        }
      }
    } catch (e) {
      debugPrint("Σφάλμα κατά το OCR processing: $e");
    } finally {
      await Future.delayed(const Duration(milliseconds: 600));
      _isProcessing = false;
    }
  }

  InputImage? _inputImageFromCameraImage(CameraImage image) {
    final camera = _cameraController?.description;
    if (camera == null) return null;

    final rotation = InputImageRotationValue.fromRawValue(
      camera.sensorOrientation,
    );
    if (rotation == null) {
      debugPrint("Ακυρο sensor orientation: ${camera.sensorOrientation}");
      return null;
    }

    final format = InputImageFormatValue.fromRawValue(image.format.raw);
    if (format == null) {
      debugPrint("Ακυρο image format raw value: ${image.format.raw}");
      return null;
    }

    Uint8List bytes;
    InputImageFormat inputFormat = format;
    int bytesPerRow = image.planes.first.bytesPerRow;

    if (defaultTargetPlatform == TargetPlatform.android &&
        image.format.raw == 35) {
      bytes = _convertYUV420ToNV21(image);
      inputFormat = InputImageFormat.nv21;
      bytesPerRow = image.width;
    } else {
      final WriteBuffer allBytes = WriteBuffer();
      for (final plane in image.planes) {
        allBytes.putUint8List(plane.bytes);
      }
      bytes = allBytes.done().buffer.asUint8List();
    }

    return InputImage.fromBytes(
      bytes: bytes,
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation,
        format: inputFormat,
        bytesPerRow: bytesPerRow,
      ),
    );
  }

  Uint8List _convertYUV420ToNV21(CameraImage image) {
    final int width = image.width;
    final int height = image.height;

    final Plane yPlane = image.planes[0];
    final Plane uPlane = image.planes[1];
    final Plane vPlane = image.planes[2];

    final Uint8List yBuffer = yPlane.bytes;
    final Uint8List uBuffer = uPlane.bytes;
    final Uint8List vBuffer = vPlane.bytes;

    final int yRowStride = yPlane.bytesPerRow;
    final int yPixelStride = yPlane.bytesPerPixel ?? 1;

    final int uvRowStride = uPlane.bytesPerRow;
    final int uvPixelStride = uPlane.bytesPerPixel ?? 2;

    final Uint8List nv21 = Uint8List((width * height * 1.5).toInt());
    int nv21Index = 0;

    for (int y = 0; y < height; y++) {
      int yRowStart = y * yRowStride;
      for (int x = 0; x < width; x++) {
        nv21[nv21Index++] = yBuffer[yRowStart + (x * yPixelStride)];
      }
    }

    final int uvHeight = height ~/ 2;
    final int uvWidth = width ~/ 2;

    for (int y = 0; y < uvHeight; y++) {
      int uvRowStart = y * uvRowStride;
      for (int x = 0; x < uvWidth; x++) {
        int uIndex = uvRowStart + (x * uvPixelStride);
        int vIndex = uvRowStart + (x * uvPixelStride);

        nv21[nv21Index++] = vBuffer[vIndex];
        nv21[nv21Index++] = uBuffer[uIndex];
      }
    }

    return nv21;
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _textRecognizer.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Σάρωση VIN')),
      body: !_isPermissionGranted
          ? const Center(
              child: Text(
                'Απαιτείται άδεια κάμερας για τη σάρωση.',
                style: TextStyle(color: Colors.white),
              ),
            )
          : (_cameraController == null ||
                !_cameraController!.value.isInitialized)
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                CameraPreview(_cameraController!),
                Center(
                  child: Container(
                    width: 300,
                    height: 100,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.tealAccent, width: 2),
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.black12,
                    ),
                    child: const Center(
                      child: Text(
                        'Τοποθετήστε το VIN εδώ',
                        style: TextStyle(
                          color: Colors.tealAccent,
                          fontWeight: FontWeight.bold,
                          backgroundColor: Colors.black54,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
