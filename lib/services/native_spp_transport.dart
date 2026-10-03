import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'bluetooth_transport.dart';

class NativeSppTransport implements BluetoothTransport {
  static const MethodChannel _methodChannel = MethodChannel('com.example.pds_weight_machine/bt');
  static const EventChannel _eventChannel = EventChannel('com.example.pds_weight_machine/bt_events');

  final _radioStateController = StreamController<BluetoothRadioState>.broadcast();
  final _connectionStateController = StreamController<BluetoothConnectionState>.broadcast();
  final _receivedDataController = StreamController<List<int>>.broadcast();

  StreamSubscription? _eventSubscription;

  NativeSppTransport() {
    _eventSubscription = _eventChannel.receiveBroadcastStream().listen((dynamic event) {
      if (event is Map) {
        final type = event['type'] as String?;
        final data = event['data'];
        
        switch (type) {
          case 'status':
          case 'state_changed':
            _handleStateChanged(data as String);
            break;
          case 'data_received':
            if (data is List) {
              final bytes = data.map((e) => e as int).toList();
              debugPrint('Bytes received: $bytes');
              _receivedDataController.add(bytes);
            }
            break;
          case 'error':
            debugPrint('Socket error: $data');
            break;
        }
      }
    }, onError: (error) {
      debugPrint('Event channel error: $error');
    });

    // Check initial state
    _checkInitialState();
  }

  Future<void> _checkInitialState() async {
    try {
      final isEnabled = await _methodChannel.invokeMethod<bool>('isBluetoothEnabled');
      if (isEnabled == true) {
        _radioStateController.add(BluetoothRadioState.on);
        _startServer(); // Auto-start server if bluetooth is enabled
      } else {
        _radioStateController.add(BluetoothRadioState.off);
      }
    } catch (e) {
      debugPrint('Failed to check initial state: $e');
    }
  }

  void _handleStateChanged(String state) {
    switch (state) {
      case 'bluetooth_disabled':
        debugPrint('Bluetooth state changed: OFF');
        _radioStateController.add(BluetoothRadioState.off);
        _connectionStateController.add(BluetoothConnectionState.disconnected);
        break;
      case 'bluetooth_enabled':
        debugPrint('Bluetooth state changed: ON');
        _radioStateController.add(BluetoothRadioState.on);
        _startServer(); // Start server when bluetooth becomes enabled
        break;
      case 'waiting':
        debugPrint('Connection state: WAITING (SPP server started/listening)');
        _connectionStateController.add(BluetoothConnectionState.disconnected);
        break;
      case 'connected':
        debugPrint('Connection state: CONNECTED');
        _connectionStateController.add(BluetoothConnectionState.connected);
        break;
      case 'disconnected':
        debugPrint('Connection state: DISCONNECTED');
        _connectionStateController.add(BluetoothConnectionState.disconnected);
        break;
    }
  }

  Future<void> _startServer() async {
    debugPrint('SPP server starting...');
    try {
      await _methodChannel.invokeMethod('startBluetoothServer');
    } catch (e) {
      debugPrint('Failed to start server: $e');
    }
  }

  @override
  Stream<BluetoothRadioState> get radioState => _radioStateController.stream;

  @override
  Stream<BluetoothConnectionState> get connectionState => _connectionStateController.stream;

  @override
  Stream<List<int>> get receivedData => _receivedDataController.stream;

  @override
  Future<void> requestEnable() async {
    // Request standard permissions
    Map<Permission, PermissionStatus> statuses = await [
      Permission.bluetooth,
      Permission.bluetoothConnect,
      Permission.bluetoothAdvertise,
    ].request();

    if ((statuses[Permission.bluetoothConnect]?.isDenied ?? false) ||
        (statuses[Permission.bluetoothAdvertise]?.isDenied ?? false)) {
      debugPrint('Bluetooth permission denied');
      _radioStateController.add(BluetoothRadioState.unavailable);
      return;
    }
    
    debugPrint('Bluetooth permission granted');

    // On modern Android, apps cannot enable Bluetooth implicitly without user interaction.
    // If it's disabled, we might have to use an Intent or the user has to enable it manually.
    // We will just report if it's off.
    final isEnabled = await _methodChannel.invokeMethod<bool>('isBluetoothEnabled');
    if (isEnabled != true) {
      debugPrint('Bluetooth is disabled, requesting native enable intent');
      try {
        await _methodChannel.invokeMethod('requestEnableBluetooth');
      } catch (e) {
        debugPrint('Failed to request Bluetooth enable: $e');
      }
      // The BroadcastReceiver will update the state to ON when enabled
    } else {
      _radioStateController.add(BluetoothRadioState.on);
      _startServer();
    }
  }

  @override
  Future<void> connect(String deviceId) async {
    // As a SERVER, we do NOT connect to devices. We WAIT for devices to connect to us.
    debugPrint('NativeSppTransport acts as a Server. Ignored connect() request.');
  }

  @override
  Future<void> disconnect() async {
    debugPrint('Disconnecting active client...');
    try {
      await _methodChannel.invokeMethod('disconnect');
    } catch (e) {
      debugPrint('Failed to disconnect: $e');
    }
  }

  @override
  Future<void> sendBytes(List<int> data) async {
    try {
      debugPrint('Bytes sent: $data');
      await _methodChannel.invokeMethod('sendData', {'bytes': Uint8List.fromList(data)});
    } catch (e) {
      debugPrint('Failed to send data: $e');
    }
  }

  @override
  void dispose() {
    try {
      _methodChannel.invokeMethod('stopBluetoothServer');
      debugPrint('SPP server stopped');
    } catch (e) {
      // ignore
    }
    _eventSubscription?.cancel();
    _radioStateController.close();
    _connectionStateController.close();
    _receivedDataController.close();
  }
}
