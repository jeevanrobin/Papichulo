import 'package:flutter/material.dart';

class ErrorFallbackWidget extends StatelessWidget {
  const ErrorFallbackWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF121212),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 420),
          margin: const EdgeInsets.all(24),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E1E),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0x33FFD700)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: Color(0xFFFFD700), size: 36),
              const SizedBox(height: 10),
              const Text(
                'Something went wrong',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Please refresh the page or try again in a moment.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[400]),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
