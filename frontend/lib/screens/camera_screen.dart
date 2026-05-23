import 'package:flutter/material.dart';
import 'package:camera/camera.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  bool _isReady = false;

  @override
  void initState() {
    super.initState();
    _setupCamera();
  }

  Future<void> _setupCamera() async {
    _cameras = await availableCameras();
    if (_cameras != null && _cameras!.isNotEmpty) {
      _controller = CameraController(
        _cameras![0],
        ResolutionPreset.medium,
        enableAudio: false,
      );
      await _controller!.initialize();
      if (mounted) {
        setState(() {
          _isReady = true;
        });
      }
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isReady || _controller == null) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 1. Real-time Camera Feed
          Transform.scale(
            scale: 1 / (_controller!.value.aspectRatio * MediaQuery.of(context).size.aspectRatio),
            child: Center(
              child: CameraPreview(_controller!),
            ),
          ),

          // 2. Monitoring Overlay (DSLR Style)
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Top Bar: Status & Time
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildIndicator('REC', Colors.red, isDot: true),
                      StreamBuilder(
                        stream: Stream.periodic(const Duration(seconds: 1)),
                        builder: (context, snapshot) {
                          final now = DateTime.now();
                          return Text(
                            '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}',
                            style: const TextStyle(color: Colors.white, fontFamily: 'monospace', fontWeight: FontWeight.bold, fontSize: 18),
                          );
                        },
                      ),
                      const Icon(Icons.battery_full, color: Colors.white, size: 24),
                    ],
                  ),

                  // Middle: Focus Marks
                  Expanded(
                    child: Center(
                      child: Container(
                        width: 250,
                        height: 250,
                        child: Stack(
                          children: [
                            _buildCorner(Alignment.topLeft),
                            _buildCorner(Alignment.topRight),
                            _buildCorner(Alignment.bottomLeft),
                            _buildCorner(Alignment.bottomRight),
                            Center(child: Container(width: 20, height: 1, color: Colors.white54)),
                            Center(child: Container(width: 1, height: 20, color: Colors.white54)),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Bottom Bar: Controls
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.close_rounded, color: Colors.white, size: 40),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const SizedBox(width: 40),
                      _buildCaptureButton(),
                      const SizedBox(width: 40),
                      IconButton(
                        icon: const Icon(Icons.flip_camera_android_rounded, color: Colors.white, size: 40),
                        onPressed: _switchCamera,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCorner(Alignment alignment) {
    return Align(
      alignment: alignment,
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          border: Border(
            top: alignment == Alignment.topLeft || alignment == Alignment.topRight ? const BorderSide(color: Colors.white, width: 2) : BorderSide.none,
            bottom: alignment == Alignment.bottomLeft || alignment == Alignment.bottomRight ? const BorderSide(color: Colors.white, width: 2) : BorderSide.none,
            left: alignment == Alignment.topLeft || alignment == Alignment.bottomLeft ? const BorderSide(color: Colors.white, width: 2) : BorderSide.none,
            right: alignment == Alignment.topRight || alignment == Alignment.bottomRight ? const BorderSide(color: Colors.white, width: 2) : BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _buildIndicator(String text, Color color, {bool isDot = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: Colors.black38, borderRadius: BorderRadius.circular(4)),
      child: Row(
        children: [
          if (isDot) ...[
            Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
            const SizedBox(width: 6),
          ],
          Text(text, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildCaptureButton() {
    return GestureDetector(
      onTap: () async {
        try {
          final XFile photo = await _controller!.takePicture();
          Navigator.pop(context, photo);
        } catch (e) {
          debugPrint('Error: $e');
        }
      },
      child: Container(
        height: 85,
        width: 85,
        decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.white70, width: 5)),
        padding: const EdgeInsets.all(5),
        child: Container(
          decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
          child: const Icon(Icons.camera_rounded, color: Colors.black, size: 35),
        ),
      ),
    );
  }

  void _switchCamera() async {
    if (_cameras == null || _cameras!.length < 2) return;
    int index = _cameras!.indexOf(_controller!.description);
    index = (index + 1) % _cameras!.length;
    
    await _controller!.dispose();
    _setupWithCamera(_cameras![index]);
  }

  Future<void> _setupWithCamera(CameraDescription camera) async {
    _controller = CameraController(camera, ResolutionPreset.high, enableAudio: false);
    await _controller!.initialize();
    if (mounted) setState(() {});
  }
}
