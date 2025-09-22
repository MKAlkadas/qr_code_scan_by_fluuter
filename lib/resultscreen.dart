import 'package:flutter/material.dart';

class ResultScreen extends StatelessWidget {
  final String qrResult;
  final VoidCallback onBack;

  const ResultScreen({
    Key? key,
    required this.qrResult,
    required this.onBack,
  }) : super(key: key);

  bool _isUrl(String text) {
    try {
      Uri.parse(text);
      return true;
    } catch (e) {
      return false;
    }
  }

  bool _isEmail(String text) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(text);
  }

  bool _isPhoneNumber(String text) {
    return RegExp(r'^[\+]?[(]?[0-9]{3}[)]?[-\s\.]?[0-9]{3}[-\s\.]?[0-9]{4,6}$')
        .hasMatch(text);
  }

  void _handleAction(BuildContext context) {
    if (_isUrl(qrResult)) {
      // Open URL
      _launchUrl(qrResult);
    } else if (_isEmail(qrResult)) {
      // Open email composer
      _launchEmail(qrResult);
    } else if (_isPhoneNumber(qrResult)) {
      // Make phone call
      _makePhoneCall(qrResult);
    } else {
      // Show copy option for text
      _copyToClipboard(context);
    }
  }

  Future<void> _launchUrl(String url) async {
    final uri =
        Uri.parse(url.startsWith(RegExp(r'https?://')) ? url : 'https://$url');
    // You can use url_launcher package for this
    // await launchUrl(uri);
    print('Launching URL: $uri');
  }

  Future<void> _launchEmail(String email) async {
    final uri = Uri.parse('mailto:$email');
    // await launchUrl(uri);
    print('Launching email: $uri');
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final uri = Uri.parse('tel:$phoneNumber');
    // await launchUrl(uri);
    print('Making call to: $phoneNumber');
  }

  Future<void> _copyToClipboard(BuildContext context) async {
    // You can use clipboard package for this
    // await Clipboard.setData(ClipboardData(text: qrResult));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Copied to clipboard')),
    );
  }

  IconData _getResultIcon() {
    if (_isUrl(qrResult)) return Icons.link;
    if (_isEmail(qrResult)) return Icons.email;
    if (_isPhoneNumber(qrResult)) return Icons.phone;
    return Icons.text_snippet;
  }

  String _getResultType() {
    if (_isUrl(qrResult)) return 'URL';
    if (_isEmail(qrResult)) return 'Email';
    if (_isPhoneNumber(qrResult)) return 'Phone Number';
    return 'Text';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Scan Result'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: onBack,
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    Icon(
                      _getResultIcon(),
                      size: 64,
                      color: Colors.blue,
                    ),
                    SizedBox(height: 16),
                    Text(
                      _getResultType(),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 20),
            Text(
              'Scanned Content:',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: SelectableText(
                qrResult,
                style: TextStyle(fontSize: 16),
              ),
            ),
            SizedBox(height: 30),
            Center(
              child: ElevatedButton.icon(
                onPressed: () => _handleAction(context),
                icon: Icon(Icons.open_in_new),
                label: Text('Take Action'),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                ),
              ),
            ),
            SizedBox(height: 15),
            Center(
              child: TextButton.icon(
                onPressed: onBack,
                icon: Icon(Icons.camera_alt),
                label: Text('Scan Again'),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _copyToClipboard(context),
        child: Icon(Icons.copy),
        tooltip: 'Copy to Clipboard',
      ),
    );
  }
}
