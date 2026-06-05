import 'package:local_auth/local_auth.dart';
import 'package:local_auth_android/local_auth_android.dart';
import 'package:local_auth_darwin/local_auth_darwin.dart';
import 'package:flutter/services.dart';

class BiometricService {
  static final LocalAuthentication _auth = LocalAuthentication();

  /// Check if biometrics are available and the user has enrolled at least one
  static Future<bool> canCheckBiometrics() async {
    try {
      final bool canAuthenticateWithBiometrics = await _auth.canCheckBiometrics;
      final bool canAuthenticate =
          canAuthenticateWithBiometrics || await _auth.isDeviceSupported();
      return canAuthenticate;
    } on PlatformException catch (_) {
      return false;
    }
  }

  /// Trigger the biometric authentication prompt
  static Future<bool> authenticate() async {
    try {
      final bool authenticated = await _auth.authenticate(
        localizedReason: 'Please authenticate to complete your checkout',
        authMessages: const <AuthMessages>[
          AndroidAuthMessages(
            signInTitle: 'Verification Required',
            biometricHint: 'Verify your identity to proceed',
            cancelButton: 'Cancel',
            deviceCredentialsRequiredTitle: 'Authentication Required',
            deviceCredentialsSetupDescription:
                'Please set up a PIN/Password on your device.',
          ),
          IOSAuthMessages(
            cancelButton: 'Cancel',
            lockOut: 'Please re-enable biometrics',
          ),
        ],
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly:
              false, // Allows PIN/Passcode fallback if biometrics fail/unavailable
          useErrorDialogs: true,
        ),
      );
      return authenticated;
    } on PlatformException catch (e) {
      if (e.code == 'NotAvailable') {
        // Handle gracefully (e.g., skip or show message)
      }
      return false;
    }
  }
}
