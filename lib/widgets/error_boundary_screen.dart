import 'package:flutter/material.dart';

/// A friendly full-screen error widget shown when an unhandled error occurs.
class ErrorBoundaryScreen extends StatelessWidget {
  final FlutterErrorDetails? errorDetails;
  final Object? error;

  const ErrorBoundaryScreen({super.key, this.errorDetails, this.error});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: const Color(0xFF0A0A0A),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('😵', style: TextStyle(fontSize: 56)),
                const SizedBox(height: 18),
                const Text(
                  'Oops! Something went wrong',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                Text(
                  'An unexpected error occurred.\nPlease restart the app.',
                  style: TextStyle(color: Colors.grey[400], height: 1.5),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    // Attempt to pop everything and restart
                    if (context.mounted) {
                      Navigator.of(context, rootNavigator: true)
                          .popUntil((_) => false);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF5C842),
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 28, vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Try Again',
                      style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
