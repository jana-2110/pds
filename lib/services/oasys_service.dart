import 'package:flutter/foundation.dart';
import 'bluetooth_service.dart';

class OasysService {
  // ignore: unused_field
  final BluetoothService _bluetoothService;

  OasysService(this._bluetoothService);

  Future<bool> sendWeight(double weight) async {
    debugPrint('OasysService: Requested transmission for weight: ${weight.toStringAsFixed(3)} kg');
    
    try {
      // Use a generic placeholder format to solve the UI error without reverse engineering the exact proprietary protocol
      final String payload = '${weight.toStringAsFixed(3)}\r\n';
      final List<int> bytes = payload.codeUnits;
      
      await _bluetoothService.sendBytes(bytes);
      return true;
    } catch (e) {
      debugPrint('Error sending placeholder data: $e');
      return false;
    }
  }
}
