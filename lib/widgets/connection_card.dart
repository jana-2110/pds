import 'package:flutter/material.dart';
import '../models/bluetooth_device_model.dart';

class ConnectionCard extends StatelessWidget {
  final BluetoothDeviceModel device;
  final bool isConnected;
  final bool isConnecting;
  final VoidCallback onConnect;
  final VoidCallback onDisconnect;

  const ConnectionCard({
    super.key,
    required this.device,
    required this.isConnected,
    required this.isConnecting,
    required this.onConnect,
    required this.onDisconnect,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: Icon(
          Icons.bluetooth,
          color: isConnected ? Colors.green : Theme.of(context).primaryColor,
        ),
        title: Text(device.name),
        subtitle: Text(device.id),
        trailing: isConnecting
            ? const CircularProgressIndicator()
            : isConnected
                ? ElevatedButton(
                    onPressed: onDisconnect,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                    ),
                    child: const Text('DISCONNECT'),
                  )
                : ElevatedButton(
                    onPressed: onConnect,
                    child: const Text('CONNECT'),
                  ),
      ),
    );
  }
}
