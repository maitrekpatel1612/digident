import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import '../config/app_config.dart';

class UDPService {
  RawDatagramSocket? _socket;
  Timer? _heartbeatTimer;
  Timer? _connectionTimeoutTimer;
  bool _isConnected = false;

  final List<List<int>> _chunks = [];
  int _expectedChunks = 0;

  // Functions to be declared by the caller
  Function(Uint8List)? onFrameReceived;
  Function(bool)? onConnectionStateChanged;
  Function(String)? onError;

  Future<void> initialize() async {
    try {
      await dispose();

      _socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4,
          AppConfig.SERVER_PORT); // Listen to all IPS at the port 12345
      _setupSocketListeners();
      _startHeartbeat();
      _sendConnectMessage();
      print("UDP Service, lookin good!");
    } catch (e) {
      onError?.call('Failed to initialize UDP service: $e');
      rethrow;
    }
  }

  void _setupSocketListeners() {
    _socket?.listen(
      (RawSocketEvent event) {
        if (event == RawSocketEvent.read) {
          _handleDatagramReceived();
        }
      },
      onError: (error) {
        onError?.call('Socket error: $error');
        _updateConnectionState(false);
      },
      onDone: () {
        onError?.call('Socket connection closed');
        _updateConnectionState(false);
      },
    );
  }

  void _handleDatagramReceived() {
    try {
      final datagram = _socket?.receive();
      if (datagram == null) return;

      _resetConnectionTimeout();

      if (!_isConnected) {
        _updateConnectionState(true);
      }

      _processPacket(datagram.data);
    } catch (e) {
      onError?.call('Error processing datagram: $e');
    }
  }

  void _processPacket(Uint8List data) {
    int incomingSize = -1;
    if (data.length == 4) {
      // _expectedChunks = data.buffer.asByteData().getInt32(0, Endian.little);
      incomingSize = data.buffer.asByteData().getInt32(0, Endian.little);
      print("Incoming $incomingSize bytes!");
      _expectedChunks = (incomingSize / AppConfig.MAX_BUFFER_SIZE)
          .ceil(); // 1562 / 1024 = (1.52).ceil() = 2

      _chunks.clear();
      // _chunks.addAll(List.filled(_expectedChunks, [])); // Useful when each packet has a chunk number in the beginning of it
      return;
    }

    /*In the next packets, the chunk numbers are not really specified. So we can skip this following thing!*/

    // final chunkNumber = data.buffer.asByteData().getInt32(0, Endian.little);
    // if (chunkNumber < 0 || chunkNumber >= _expectedChunks) {
    //   // onError?.call('Invalid chunk index: $chunkNumber');
    //   return;
    // }
    // final chunkData = data.sublist(4);

    final chunkData = data;
    // _chunks[chunkNumber] = chunkData;
    _chunks.add(chunkData);

    if (_isFrameComplete()) {
      _assembleAndDeliverFrame();
    }
  }

  bool _isFrameComplete() {
    // return _chunks.every((chunk) => chunk.isNotEmpty); // Useful when each packet has a chunk number in the beginning of it
    return _chunks.length == _expectedChunks;
  }

  void _assembleAndDeliverFrame() {
    try {
      final completeImage = _chunks
          .expand((chunk) => chunk)
          .toList(); // Convert [[x,y,z], [a,b,c]] to [x,y,z,a,b,c]
      onFrameReceived?.call(Uint8List.fromList(completeImage));
    } catch (e) {
      onError?.call('Error assembling frame: $e');
    } finally {
      _chunks.clear();
      _expectedChunks = 0;
    }
  }

  void _sendConnectMessage() {
    try {
      _socket?.send(
        'START'.codeUnits,
        InternetAddress(AppConfig.SERVER_IP),
        AppConfig.SERVER_PORT,
      );
    } catch (e) {
      onError?.call('Failed to send connect message: $e');
    }
  }

  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(
      const Duration(seconds: 5),
      (_) => _sendConnectMessage(),
    );
  }

  void _resetConnectionTimeout() {
    _connectionTimeoutTimer?.cancel();
    _connectionTimeoutTimer = Timer(
      const Duration(seconds: 10),
      () => _updateConnectionState(false),
    );
  }

  void _updateConnectionState(bool connected) {
    if (_isConnected != connected) {
      _isConnected = connected;
      onConnectionStateChanged?.call(connected);
    }
  }

  Future<void> dispose() async {
    _heartbeatTimer?.cancel();
    _connectionTimeoutTimer?.cancel();
    _socket?.close();
    _socket = null;
    _updateConnectionState(false);
  }
}
