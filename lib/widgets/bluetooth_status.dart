import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/bluetooth_service.dart';
import '../services/bluetooth_transport.dart';

class BluetoothStatusBanner extends StatelessWidget {
  const BluetoothStatusBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<BluetoothService>(
      builder: (context, bluetoothService, child) {
        final radioState = bluetoothService.radioState;
        final connState = bluetoothService.connectionState;
        
        Color backgroundColor;
        Color textColor;
        IconData iconData;
        String text;

        if (radioState == BluetoothRadioState.off || radioState == BluetoothRadioState.unavailable) {
          backgroundColor = const Color(0xFFFFEBEE); // Error background
          textColor = const Color(0xFFC62828); // Error red
          iconData = Icons.bluetooth_disabled;
          text = "Bluetooth is OFF — tap icon to turn on";
        } else if (connState == BluetoothConnectionState.connected) {
          backgroundColor = const Color(0xFFE8F5E9); // Success background
          textColor = const Color(0xFF2E7D32); // Success green
          iconData = Icons.check_circle;
          text = "Connected & Streaming";
        } else {
          backgroundColor = const Color(0xFFFFF8E1); // Waiting background
          textColor = const Color(0xFFF57C00); // Waiting orange
          iconData = Icons.bluetooth;
          text = "Waiting for a device to connect via Bluetooth...";
        }

        return Container(
          width: double.infinity,
          color: backgroundColor,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(iconData, size: 24, color: textColor),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  text,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: textColor,
                    fontSize: 16,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
