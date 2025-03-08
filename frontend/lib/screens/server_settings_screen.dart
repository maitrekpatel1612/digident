import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../config/app_config.dart';
import '../widgets/app_logo.dart';

class ServerSettingsScreen extends StatefulWidget {
  final VoidCallback toggleTheme;

  const ServerSettingsScreen({
    super.key,
    required this.toggleTheme,
  });

  @override
  State<ServerSettingsScreen> createState() => _ServerSettingsScreenState();
}

class _ServerSettingsScreenState extends State<ServerSettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _ipController = TextEditingController();
  final _portController = TextEditingController();
  bool _isLoading = true;
  final AppConfig _appConfig = AppConfig();

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    _ipController.dispose();
    _portController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    await _appConfig.init();
    setState(() {
      _ipController.text = _appConfig.serverIp;
      _portController.text = _appConfig.serverPort.toString();
      _isLoading = false;
    });
  }

  Future<void> _saveSettings() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      await _appConfig.setServerIp(_ipController.text);
      await _appConfig.setServerPort(int.parse(_portController.text));

      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Settings saved successfully')),
        );
      }
    }
  }

  Future<void> _resetToDefaults() async {
    setState(() {
      _isLoading = true;
    });

    await _appConfig.resetToDefaults();
    _ipController.text = _appConfig.serverIp;
    _portController.text = _appConfig.serverPort.toString();

    setState(() {
      _isLoading = false;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Settings reset to defaults')),
      );
    }
  }

  Future<void> _scanForServerInfo() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Try to read server info from file
      final found = await _appConfig.tryReadServerInfoFile();
      
      if (found) {
        // Update text fields
        _ipController.text = _appConfig.serverIp;
        _portController.text = _appConfig.serverPort.toString();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Server information found and loaded')),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No server information file found')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error scanning for server info: $e')),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const AppLogo(useLightModeColor: false),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey[850],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: [
                          const Text(
                            'Server Connection Settings',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Configure the IP address and port of the Digident camera server.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Auto-detect button
                    ElevatedButton.icon(
                      onPressed: _scanForServerInfo,
                      icon: const Icon(Icons.search),
                      label: const Text('Scan for Server Information'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // IP Address field
                    TextFormField(
                      controller: _ipController,
                      decoration: const InputDecoration(
                        labelText: 'Server IP Address',
                        hintText: 'e.g., 192.168.1.100',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.computer),
                        labelStyle: TextStyle(color: Colors.white70),
                        hintStyle: TextStyle(color: Colors.white30),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.grey),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.blue),
                        ),
                      ),
                      style: const TextStyle(color: Colors.white),
                      keyboardType: TextInputType.text,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter an IP address';
                        }
                        // Simple IP address validation
                        final ipRegex = RegExp(
                            r'^((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$');
                        if (!ipRegex.hasMatch(value)) {
                          return 'Please enter a valid IP address';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Port field
                    TextFormField(
                      controller: _portController,
                      decoration: const InputDecoration(
                        labelText: 'Server Port',
                        hintText: 'e.g., 5000',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.settings_ethernet),
                        labelStyle: TextStyle(color: Colors.white70),
                        hintStyle: TextStyle(color: Colors.white30),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.grey),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.blue),
                        ),
                      ),
                      style: const TextStyle(color: Colors.white),
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a port number';
                        }
                        final port = int.tryParse(value);
                        if (port == null || port < 1 || port > 65535) {
                          return 'Port must be between 1 and 65535';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),

                    // Save button
                    ElevatedButton.icon(
                      onPressed: _saveSettings,
                      icon: const Icon(Icons.save),
                      label: const Text('Save Settings'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        backgroundColor: Colors.blue.shade800,
                        foregroundColor: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Reset button
                    OutlinedButton.icon(
                      onPressed: _resetToDefaults,
                      icon: const Icon(Icons.restore),
                      label: const Text('Reset to Defaults'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        foregroundColor: Colors.blue,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Connection info
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey[800],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.grey[700]!,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Connection Information',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Current Server URL: ${_appConfig.serverUrl}',
                            style: TextStyle(
                              fontFamily: 'monospace',
                              color: Colors.blue[200],
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Troubleshooting Tips:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            '• Make sure your phone is connected to the same WiFi network as the server',
                            style: TextStyle(fontSize: 13, color: Colors.white70),
                          ),
                          const Text(
                            '• Check that the server is running and accessible',
                            style: TextStyle(fontSize: 13, color: Colors.white70),
                          ),
                          const Text(
                            '• Try pinging the server IP from another device',
                            style: TextStyle(fontSize: 13, color: Colors.white70),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
} 