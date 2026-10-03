import 'dart:async';
import 'package:flutter/foundation.dart';
import 'bluetooth_transport.dart';
import 'native_spp_transport.dart';

class BluetoothService extends ChangeNotifier {
  late final BluetoothTransport _transport;
  
  BluetoothRadioState _radioState = BluetoothRadioState.off;
  BluetoothConnectionState _connectionState = BluetoothConnectionState.disconnected;

  BluetoothRadioState get radioState => _radioState;
  BluetoothConnectionState get connectionState => _connectionState;

  StreamSubscription? _radioSub;
  StreamSubscription? _connSub;

  BluetoothService() {
    _transport = NativeSppTransport();
    
    _radioSub = _transport.radioState.listen((state) {
      _radioState = state;
      // If bluetooth is off, we are implicitly disconnected
      if (state != BluetoothRadioState.on) {
        _connectionState = BluetoothConnectionState.disconnected;
      }
      notifyListeners();
    });

    _connSub = _transport.connectionState.listen((state) {
      _connectionState = state;
      notifyListeners();
    });
  }

  Future<void> requestEnable() async {
    await _transport.requestEnable();
  }

  Future<void> sendBytes(List<int> data) async {
    if (_connectionState != BluetoothConnectionState.connected) {
      throw Exception('Bluetooth not connected');
    }
    await _transport.sendBytes(data);
  }

  @override
  void dispose() {
    _radioSub?.cancel();
    _connSub?.cancel();
    if (_transport is NativeSppTransport) {
      (_transport).dispose();
    }
    super.dispose();
  }
}
