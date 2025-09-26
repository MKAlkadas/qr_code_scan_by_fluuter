import 'package:flutter/material.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

import 'resultscreen.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'QR Code Scanner',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: QRScannerScreen(),
    );
  }
}

class QRScannerScreen extends StatefulWidget {
  @override
  _QRScannerScreenState createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  QRViewController? controller;
  bool hasPermission = false;
  bool isFlashOn = false;
  List<ScanResult> scanHistory = [];
  final ImagePicker _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _checkCameraPermission();
    _loadScanHistory();
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  Future<void> _checkCameraPermission() async {
    final status = await Permission.camera.status;
    if (status.isGranted) {
      setState(() {
        hasPermission = true;
      });
    } else {
      final result = await Permission.camera.request();
      setState(() {
        hasPermission = result.isGranted;
      });
    }
  }

  void _onQRViewCreated(QRViewController controller) {
    this.controller = controller;
    controller.scannedDataStream.listen((scanData) {
      if (scanData.code != null) {
        controller.pauseCamera();
        _saveScanResult(scanData.code!);
        _navigateToResultScreen(scanData.code!);
      }
    });
  }

  void _saveScanResult(String result) {
    setState(() {
      scanHistory.insert(
          0,
          ScanResult(
              result: result, timestamp: DateTime.now(), type: 'Camera Scan'));
    });
    _saveScanHistory();
  }

  void _saveScanHistory() async {
    // هنا يمكنك حفظ السجل في SharedPreferences أو قاعدة بيانات
    // مثال: await SharedPreferences.getInstance().then((prefs) {...});
    print('Scan history saved: ${scanHistory.length} items');
  }

  void _loadScanHistory() async {
    // هنا يمكنك تحميل السجل من SharedPreferences أو قاعدة بيانات
    // مثال: await SharedPreferences.getInstance().then((prefs) {...});
    setState(() {
      // بيانات تجريبية للعرض
      scanHistory = [
        ScanResult(
            result: 'https://example.com',
            timestamp: DateTime.now().subtract(Duration(hours: 1)),
            type: 'Camera Scan'),
        ScanResult(
            result: 'TEL:0123456789',
            timestamp: DateTime.now().subtract(Duration(days: 1)),
            type: 'Gallery Scan'),
      ];
    });
  }

  void _navigateToResultScreen(String result) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ResultScreen(
          qrResult: result,
          onBack: () {
            controller?.resumeCamera();
            Navigator.pop(context);
          },
        ),
      ),
    );
  }

  Future<void> _toggleFlash() async {
    await controller?.toggleFlash();
    setState(() {
      isFlashOn = !isFlashOn;
    });
  }

  Future<void> _scanFromGallery() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
      );

      if (image != null) {
        // هنا يمكنك استخدام مكتبة لقراءة QR من الصورة
        // مثل: qr_code_scanner يمكنها قراءة QR من الصور
        String? result = await _readQRFromImage(File(image.path));

        if (result != null) {
          _saveScanResult(result);
          _navigateToResultScreen(result);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('No QR code found in the image')),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error selecting image: $e')),
      );
    }
  }

  Future<String?> _readQRFromImage(File image) async {
    // هذه وظيفة افتراضية - تحتاج إلى تطبيق حقيقي لقراءة QR من الصورة
    // يمكن استخدام مكتبة مثل: qr_code_tools
    return 'QR Code from image: ${image.path}'; // نموذج تجريبي
  }

  void _showScanHistory() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => ScanHistoryBottomSheet(
        scanHistory: scanHistory,
        onClearHistory: _clearScanHistory,
      ),
    );
  }

  void _clearScanHistory() {
    setState(() {
      scanHistory.clear();
    });
    _saveScanHistory();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Scan history cleared')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('QR Code Scanner'),
        backgroundColor: Colors.black,
        actions: [
          IconButton(
            icon: Icon(isFlashOn ? Icons.flash_on : Icons.flash_off),
            onPressed: _toggleFlash,
            tooltip: 'Toggle Flash',
          ),
        ],
      ),
      body: _buildBody(),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildBody() {
    if (!hasPermission) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.camera_alt, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Camera permission required',
              style: TextStyle(fontSize: 18),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _checkCameraPermission,
              child: Text('Grant Permission'),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        Expanded(
          flex: 5,
          child: QRView(
            key: qrKey,
            onQRViewCreated: _onQRViewCreated,
            overlay: QrScannerOverlayShape(
              borderColor: Colors.blue,
              borderRadius: 10,
              borderLength: 30,
              borderWidth: 10,
              cutOutSize: 250,
            ),
          ),
        ),
        Expanded(
          flex: 1,
          child: Container(
            color: Colors.black,
            child: Center(
              child: Text(
                'Align QR code within the frame to scan',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomNavigationBar() {
    return Container(
      height: 80,
      color: Colors.black,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // أيقونة فتح الصور من المعرض
          _buildBottomIcon(
            icon: Icons.photo_library,
            label: 'Gallery',
            onTap: _scanFromGallery,
          ),

          // أيقونة سجل العمليات
          _buildBottomIcon(
            icon: Icons.history,
            label: 'History',
            onTap: _showScanHistory,
            badgeCount: scanHistory.length,
          ),

          // أيقونة الفلاش
          _buildBottomIcon(
            icon: isFlashOn ? Icons.flash_on : Icons.flash_off,
            label: 'Flash',
            onTap: _toggleFlash,
          ),
        ],
      ),
    );
  }

  Widget _buildBottomIcon({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    int badgeCount = 0,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              children: [
                Icon(icon, color: Colors.white, size: 30),
                if (badgeCount > 0)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      constraints: BoxConstraints(
                        minWidth: 12,
                        minHeight: 12,
                      ),
                      child: Text(
                        badgeCount > 9 ? '9+' : '$badgeCount',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(color: Colors.white, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

class ScanResult {
  final String result;
  final DateTime timestamp;
  final String type;

  ScanResult({
    required this.result,
    required this.timestamp,
    required this.type,
  });
}

class ScanHistoryBottomSheet extends StatelessWidget {
  final List<ScanResult> scanHistory;
  final VoidCallback onClearHistory;

  const ScanHistoryBottomSheet({
    Key? key,
    required this.scanHistory,
    required this.onClearHistory,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Scan History',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              if (scanHistory.isNotEmpty)
                TextButton(
                  onPressed: onClearHistory,
                  child: Text('Clear All'),
                ),
            ],
          ),
          SizedBox(height: 16),
          Expanded(
            child: scanHistory.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.history, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text('No scan history yet'),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: scanHistory.length,
                    itemBuilder: (context, index) {
                      final result = scanHistory[index];
                      return Card(
                        margin: EdgeInsets.symmetric(vertical: 4),
                        child: ListTile(
                          leading: Icon(Icons.qr_code),
                          title: Text(
                            result.result.length > 50
                                ? '${result.result.substring(0, 50)}...'
                                : result.result,
                            style: TextStyle(fontSize: 14),
                          ),
                          subtitle: Text(
                            '${result.type} • ${_formatDate(result.timestamp)}',
                            style: TextStyle(fontSize: 12),
                          ),
                          trailing: Icon(Icons.chevron_right),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ResultScreen(
                                  qrResult: result.result,
                                  onBack: () => Navigator.pop(context),
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}
