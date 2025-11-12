import 'package:flutter/material.dart';

class ModalDialog extends StatelessWidget {
  final String title;
  final Widget child;

  const ModalDialog({super.key, required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: SizedBox(
        width: 400,
        height: 500,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            ),
            const Divider(),
            Expanded(child: child),
          ],
        ),
      ),
    );
  }
}