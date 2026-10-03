import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'theme.dart';
import '../screens/weight_screen.dart';
import '../services/bluetooth_service.dart';
import '../services/oasys_service.dart';
import '../services/weight_service.dart';

class WeightMachineApp extends StatelessWidget {
  const WeightMachineApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => BluetoothService()),
        ChangeNotifierProvider(create: (_) => WeightService()),
        ProxyProvider<BluetoothService, OasysService>(
          update: (_, bluetoothService, previous) => OasysService(bluetoothService),
        ),
      ],
      child: MaterialApp(
        title: 'Weight Machine',
        theme: AppTheme.lightTheme,
        home: const WeightScreen(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
