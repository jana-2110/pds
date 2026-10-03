import 'package:flutter/material.dart';

class CustomWeightButton extends StatelessWidget {
  final VoidCallback onPressed;

  const CustomWeightButton({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final Color primary = Theme.of(context).primaryColor;
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(Icons.add, color: primary),
      label: Text(
        'Custom Weight',
        style: TextStyle(fontSize: 18, color: primary, fontWeight: FontWeight.bold),
      ),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(double.infinity, 60),
        backgroundColor: Colors.white,
        side: BorderSide(color: primary, width: 2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}
