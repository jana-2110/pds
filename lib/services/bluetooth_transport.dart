import 'dart:async';

enum BluetoothRadioState { off, on, unavailable }
enum BluetoothConnectionState { disconnected, connecting, connected }

abstract class BluetoothTransport {
  Stream<BluetoothRadioState> get radioState;
  Stream<BluetoothConnectionState> get connectionState;
  Stream<List<int>> get receivedData;

  Future<void> requestEnable();
  Future<void> connect(String deviceId);
  Future<void> disconnect();
  Future<void> sendBytes(List<int> data);
  void dispose();
}
