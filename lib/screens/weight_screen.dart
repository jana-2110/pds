import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/weight_service.dart';
import '../services/oasys_service.dart';
import '../services/bluetooth_transport.dart';
import '../services/bluetooth_service.dart';
import '../widgets/bluetooth_status.dart';
import '../widgets/weight_button.dart';
import '../widgets/custom_weight_button.dart';


class WeightScreen extends StatefulWidget {
  const WeightScreen({super.key});

  @override
  State<WeightScreen> createState() => _WeightScreenState();
}

class _WeightScreenState extends State<WeightScreen> {
  double? _activeWeight;

  void _sendWeight(double weight) async {
    final oasysService = context.read<OasysService>();
    final bluetoothService = context.read<BluetoothService>();
    
    if (bluetoothService.connectionState == BluetoothConnectionState.connected) {
      try {
        final success = await oasysService.sendWeight(weight);
        
        if (mounted) {
          ScaffoldMessenger.of(context).clearSnackBars();
          
          if (success) {
            setState(() {
              _activeWeight = weight;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(Icons.check, color: Colors.white),
                    const SizedBox(width: 8),
                    Text(
                      'Sent: ${weight.toStringAsFixed(3)}',
                      style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                backgroundColor: const Color(0xFF2E7D32),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                behavior: SnackBarBehavior.floating,
                duration: const Duration(seconds: 2),
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Protocol pending: Packet requires physical device capture'),
                backgroundColor: Colors.blueGrey,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error sending weight: $e'), backgroundColor: Colors.red),
          );
        }
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Device not connected'),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _confirmDeleteWeight(double weight) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Weight?'),
        content: Text('Are you sure you want to delete\n${weight.toStringAsFixed(3)} kg?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              final weightService = context.read<WeightService>();
              if (weightService.removeWeight(weight)) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('${weight.toStringAsFixed(3)} kg deleted')),
                );
              }
            },
            child: const Text('DELETE'),
          ),
        ],
      ),
    );
  }

  void _showCustomWeightDialog() {
    showDialog(
      context: context,
      builder: (context) => const _CustomWeightDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final weightService = context.watch<WeightService>();
    final weights = weightService.getAllWeights();

    return Scaffold(
      appBar: AppBar(
        leading: Padding(
          padding: const EdgeInsets.only(left: 12.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(Icons.monitor_weight, size: 24),
              Text('KG', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        title: const Text('Weight Machine', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          Consumer<BluetoothService>(
            builder: (context, bluetoothService, child) {
              final isConnected = bluetoothService.connectionState == BluetoothConnectionState.connected;
              final isOff = bluetoothService.radioState == BluetoothRadioState.off || 
                            bluetoothService.radioState == BluetoothRadioState.unavailable;
              
              IconData btnIcon = Icons.bluetooth;
              Color iconColor = Colors.white;

              if (isOff) {
                btnIcon = Icons.bluetooth_disabled;
                iconColor = Colors.white54;
              } else if (isConnected) {
                iconColor = const Color(0xFFC8E6C9); // Light green hint
              }

              return IconButton(
                icon: Icon(btnIcon, color: iconColor),
                onPressed: () {
                  bluetoothService.requestEnable();
                },
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          const BluetoothStatusBanner(),
          
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total weights: ${weights.length}',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
                if (_activeWeight != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFC8E6C9), // Light green
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Active: ${_activeWeight!.toStringAsFixed(3)}kg',
                      style: const TextStyle(
                        color: Color(0xFF2E7D32), // Dark green
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                childAspectRatio: 1.0,
                crossAxisSpacing: 8.0,
                mainAxisSpacing: 8.0,
              ),
              itemCount: weights.length,
              itemBuilder: (context, index) {
                return WeightButton(
                  formattedWeight: weights[index].formattedValue,
                  isCustom: weights[index].isCustom,
                  onPressed: () => _sendWeight(weights[index].value),
                  onLongPress: () => _confirmDeleteWeight(weights[index].value),
                );
              },
            ),
          ),
          
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: CustomWeightButton(onPressed: _showCustomWeightDialog),
          ),
        ],
      ),
    );
  }
}

class _CustomWeightDialog extends StatefulWidget {
  const _CustomWeightDialog();

  @override
  State<_CustomWeightDialog> createState() => _CustomWeightDialogState();
}

class _CustomWeightDialogState extends State<_CustomWeightDialog> {
  final TextEditingController _controller = TextEditingController();
  String? _errorMessage;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _validateAndAdd() {
    final text = _controller.text.trim();
    if (text.isEmpty) {
      setState(() => _errorMessage = 'Please enter a valid weight');
      return;
    }

    final parsed = double.tryParse(text);
    if (parsed == null) {
      setState(() => _errorMessage = 'Invalid weight format');
      return;
    }

    if (parsed <= 0) {
      setState(() => _errorMessage = 'Please enter a positive weight');
      return;
    }

    final weightService = context.read<WeightService>();
    final normalizedStr = weightService.normalizeWeight(parsed).toStringAsFixed(3);

    if (weightService.weightExists(parsed)) {
      setState(() => _errorMessage = '$normalizedStr kg already exists');
      return;
    }

    weightService.addCustomWeight(parsed);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Custom Weight'),
      content: TextField(
        controller: _controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(
          suffixText: 'kg',
          hintText: 'Enter weight',
          errorText: _errorMessage,
        ),
        onChanged: (_) {
          if (_errorMessage != null) {
            setState(() => _errorMessage = null);
          }
        },
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('CANCEL'),
        ),
        ElevatedButton(
          onPressed: _validateAndAdd,
          child: const Text('ADD'),
        ),
      ],
    );
  }
}
