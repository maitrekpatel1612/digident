import 'dart:async';
import 'package:flutter/material.dart';
import 'package:wifi_scan/wifi_scan.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:app_settings/app_settings.dart';
import 'camera_view_screen.dart';
import 'server_settings_screen.dart';
import '../widgets/app_logo.dart';

class WiFiConnectionScreen extends StatefulWidget {
  final VoidCallback toggleTheme;

  const WiFiConnectionScreen({
    super.key,
    required this.toggleTheme,
  });

  @override
  State<WiFiConnectionScreen> createState() => _WiFiConnectionScreenState();
}

class _WiFiConnectionScreenState extends State<WiFiConnectionScreen> {
  List<WiFiAccessPoint> _accessPoints = [];
  bool _isScanning = false;
  bool _isConnecting = false;
  String? _connectionError;
  String? _connectionSuccess;
  final String _targetSSID = 'Digident';
  
  @override
  void initState() {
    super.initState();
    _initializeWiFi();
  }
  
  @override
  void dispose() {
    super.dispose();
  }
  
  Future<void> _initializeWiFi() async {
    // Request location permission (required for WiFi scanning)
    var status = await Permission.location.request();
    if (!status.isGranted) {
      setState(() {
        _connectionError = 'Location permission is required to scan for WiFi networks';
      });
      return;
    }
    
    // Check if WiFi is enabled
    var canScan = await WiFiScan.instance.canStartScan();
    if (canScan != CanStartScan.yes) {
      setState(() {
        _connectionError = 'Please enable WiFi to continue';
      });
      return;
    }
    
    // Start scanning for WiFi networks
    _startScan();
  }
  
  Future<void> _startScan() async {
    setState(() {
      _isScanning = true;
      _connectionError = null;
      _connectionSuccess = null;
    });
    
    try {
      // Start scan
      var canScan = await WiFiScan.instance.canStartScan();
      if (canScan != CanStartScan.yes) {
        setState(() {
          _connectionError = 'Cannot scan for WiFi networks: $canScan';
          _isScanning = false;
        });
        return;
      }
      
      // Start scan and get results
      await WiFiScan.instance.startScan();
      
      // Wait a bit for the scan to complete
      await Future.delayed(const Duration(seconds: 2));
      
      // Get scan results
      final results = await WiFiScan.instance.getScannedResults();
      
      setState(() {
        _accessPoints = results;
        _isScanning = false;
      });
      
      // Check if our target network is in the list
      _checkForTargetNetwork();
      
    } catch (e) {
      setState(() {
        _connectionError = 'Error scanning for WiFi networks: $e';
        _isScanning = false;
      });
    }
  }
  
  void _checkForTargetNetwork() {
    // Check if our target network is in the list
    final targetNetwork = _accessPoints.where((ap) => ap.ssid == _targetSSID).toList();
    if (targetNetwork.isEmpty) {
      setState(() {
        _connectionError = 'Digident WiFi network not found. Make sure the server is running.';
      });
    }
  }
  
  Future<void> _connectToWiFi(String ssid) async {
    setState(() {
      _isConnecting = true;
      _connectionError = null;
      _connectionSuccess = null;
    });
    
    try {
      // Open WiFi settings
      await AppSettings.openAppSettings(type: AppSettingsType.wifi);
      
      // Wait a bit for the user to connect
      await Future.delayed(const Duration(seconds: 2));
      
      // Check if we're connected to the right network
      final info = NetworkInfo();
      String? connectedSSID = await info.getWifiName();
      
      // Remove quotes if present
      if (connectedSSID != null && connectedSSID.startsWith('"') && connectedSSID.endsWith('"')) {
        connectedSSID = connectedSSID.substring(1, connectedSSID.length - 1);
      }
      
      if (connectedSSID == ssid) {
        setState(() {
          _isConnecting = false;
          _connectionSuccess = 'Successfully connected to Digident WiFi';
        });
      } else {
        setState(() {
          _connectionError = 'Please connect to the Digident WiFi network in your WiFi settings.';
          _isConnecting = false;
        });
      }
    } catch (e) {
      setState(() {
        _connectionError = 'Error connecting to WiFi: $e';
        _isConnecting = false;
      });
    }
  }
  
  Widget _buildNetworkItem(WiFiAccessPoint ap) {
    final bool isTargetNetwork = ap.ssid == _targetSSID;
    
    // Determine signal strength icon
    IconData signalIcon;
    if (ap.level > -50) {
      signalIcon = Icons.signal_wifi_4_bar;
    } else if (ap.level > -70) {
      signalIcon = Icons.network_wifi;
    } else {
      signalIcon = Icons.signal_wifi_0_bar;
    }
    
    return Card(
      elevation: isTargetNetwork ? 4 : 1,
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      color: isTargetNetwork ? Colors.blue.shade900 : Colors.grey[850],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isTargetNetwork 
            ? BorderSide(color: Colors.blue, width: 1.5) 
            : BorderSide.none,
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Icon(
          signalIcon,
          color: isTargetNetwork ? Colors.blue : Colors.white70,
          size: 28,
        ),
        title: Text(
          ap.ssid,
          style: TextStyle(
            fontWeight: isTargetNetwork ? FontWeight.bold : FontWeight.normal,
            fontSize: isTargetNetwork ? 16 : 14,
            color: isTargetNetwork ? Colors.blue : Colors.white,
          ),
        ),
        subtitle: isTargetNetwork 
            ? const Text(
                'Digident Camera Server',
                style: TextStyle(
                  fontStyle: FontStyle.italic,
                  color: Colors.white70,
                ),
              ) 
            : null,
        trailing: isTargetNetwork 
            ? ElevatedButton(
                onPressed: () async {
                  await AppSettings.openAppSettings(type: AppSettingsType.wifi);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Connect'),
              )
            : null,
        onTap: isTargetNetwork 
            ? () async {
                await AppSettings.openAppSettings(type: AppSettingsType.wifi);
              }
            : null,
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const AppLogo(useLightModeColor: false),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ServerSettingsScreen(
                    toggleTheme: widget.toggleTheme,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: Colors.grey[850],
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                const Text(
                  'Connect to WiFi',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Please connect to the Digident WiFi network to access the camera server.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
          
          // Success message
          if (_connectionSuccess != null)
            Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.green[700], size: 24),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _connectionSuccess!,
                          style: TextStyle(
                            color: Colors.green[700],
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CameraViewScreen(
                              toggleTheme: widget.toggleTheme,
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.camera_alt),
                      label: const Text('Go to Camera'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          
          // Error message
          if (_connectionError != null)
            Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.error_outline, color: Colors.red[700], size: 24),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _connectionError!,
                          style: TextStyle(
                            color: Colors.red[700],
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        await AppSettings.openAppSettings(type: AppSettingsType.wifi);
                      },
                      icon: const Icon(Icons.wifi),
                      label: const Text('Open WiFi Settings'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red[700],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          
          // Loading indicator
          if (_isScanning || _isConnecting)
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(width: 16),
                  Text(_isScanning 
                      ? 'Scanning for WiFi networks...' 
                      : 'Connecting to WiFi...',
                      style: const TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ),
          
          // Network list
          Expanded(
            child: _accessPoints.isEmpty && !_isScanning
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.wifi_find,
                          size: 64,
                          color: Colors.white30,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No WiFi networks found',
                          style: TextStyle(
                            color: Colors.white70,
                          ),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: _startScan,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Scan Again'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue.shade800,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _startScan,
                    child: ListView.builder(
                      itemCount: _accessPoints.length,
                      itemBuilder: (context, index) => _buildNetworkItem(_accessPoints[index]),
                    ),
                  ),
          ),
          
          // Check connection button
          if (!_isScanning && !_isConnecting && _connectionSuccess == null)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton.icon(
                onPressed: () => _connectToWiFi(_targetSSID),
                icon: const Icon(Icons.check_circle),
                label: const Text('Check Connection', style: TextStyle(fontSize: 16)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade800,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24.0,
                    vertical: 16.0,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 3,
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _startScan,
        tooltip: 'Scan for WiFi networks',
        backgroundColor: Colors.blue.shade800,
        foregroundColor: Colors.white,
        child: const Icon(Icons.refresh),
      ),
    );
  }
} 