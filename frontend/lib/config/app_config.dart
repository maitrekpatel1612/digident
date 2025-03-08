import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'dart:developer' as developer;

class AppConfig {
  // Default server settings
  static const String defaultServerIp = '192.168.137.1';
  static const int defaultServerPort = 5000;
  
  // Keys for shared preferences
  static const String serverIpKey = 'server_ip';
  static const String serverPortKey = 'server_port';
  
  // Singleton instance
  static final AppConfig _instance = AppConfig._internal();
  
  // Factory constructor
  factory AppConfig() => _instance;
  
  // Internal constructor
  AppConfig._internal();
  
  // Server settings
  String _serverIp = defaultServerIp;
  int _serverPort = defaultServerPort;
  
  // Getters
  String get serverIp => _serverIp;
  int get serverPort => _serverPort;
  String get serverUrl => 'http://$_serverIp:$_serverPort';
  
  // Initialize config from shared preferences
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Try to read server info from file first
    bool fileFound = await tryReadServerInfoFile();
    
    // If file not found or reading failed, use shared preferences
    if (!fileFound) {
      _serverIp = prefs.getString(serverIpKey) ?? defaultServerIp;
      _serverPort = prefs.getInt(serverPortKey) ?? defaultServerPort;
    } else {
      // Save the values from file to shared preferences for future use
      await prefs.setString(serverIpKey, _serverIp);
      await prefs.setInt(serverPortKey, _serverPort);
    }
  }
  
  // Try to read server information from a file
  Future<bool> tryReadServerInfoFile() async {
    try {
      // Get the application documents directory
      final directory = await getApplicationDocumentsDirectory();
      final serverInfoPath = '${directory.path}/server_info.txt';
      final file = File(serverInfoPath);
      
      // Check if the file exists
      if (!await file.exists()) {
        developer.log('Server info file not found');
        return false;
      }
      
      // Read the file
      final contents = await file.readAsString();
      final lines = contents.split('\n');
      
      // Parse the contents
      for (var line in lines) {
        if (line.startsWith('HOST=')) {
          _serverIp = line.substring(5).trim();
        } else if (line.startsWith('PORT=')) {
          _serverPort = int.tryParse(line.substring(5).trim()) ?? defaultServerPort;
        }
      }
      
      developer.log('Server info read from file: $_serverIp:$_serverPort');
      return true;
    } catch (e) {
      developer.log('Error reading server info file: $e');
      return false;
    }
  }
  
  // Save server IP
  Future<void> setServerIp(String ip) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(serverIpKey, ip);
    _serverIp = ip;
  }
  
  // Save server port
  Future<void> setServerPort(int port) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(serverPortKey, port);
    _serverPort = port;
  }
  
  // Reset to defaults
  Future<void> resetToDefaults() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(serverIpKey, defaultServerIp);
    await prefs.setInt(serverPortKey, defaultServerPort);
    _serverIp = defaultServerIp;
    _serverPort = defaultServerPort;
  }
}