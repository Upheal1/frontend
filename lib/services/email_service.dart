import 'package:flutter/foundation.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';

import '../config.dart';

class EmailService {
  static Future<void> sendOtp(String toEmail, String otp) async {
    try {
      if (SMTP_USERNAME.isNotEmpty && SMTP_PASSWORD.isNotEmpty) {
        final ok = await _sendEmailRaw(
          toEmail,
          'UpHeal OTP Verification',
          'Your OTP code is: $otp\n\nDo not share it with anyone.',
        );
        if (ok) return;
      }

      if (kDebugMode) {
        print('OTP fallback for $toEmail => $otp');
      }
    } catch (e) {
      if (kDebugMode) print('Failed to send OTP: $e');
    }
  }

  static Future<void> sendPasswordResetRequest(String toEmail) async {
    try {
      if (SMTP_USERNAME.isNotEmpty && SMTP_PASSWORD.isNotEmpty) {
        final ok = await _sendEmailRaw(
          toEmail,
          'UpHeal Password Reset',
          'We received a request to reset your password.\n'
              'If this was you, please follow the instructions in the app.\n'
              'If not, ignore this message.',
        );
        if (ok) return;
      }

      if (kDebugMode) {
        print(
          'SMTP not configured. Password reset should be sent through SupabaseAuthService: $toEmail',
        );
      }
    } catch (e) {
      if (kDebugMode) print('Failed to send password reset email: $e');
    }
  }

  static Future<bool> _sendEmailRaw(
    String toEmail,
    String subject,
    String body,
  ) async {
    if (SMTP_USERNAME.isEmpty || SMTP_PASSWORD.isEmpty) {
      if (kDebugMode) print('SMTP not configured. Email not sent to $toEmail');
      return false;
    }

    final smtpServer = SmtpServer(
      SMTP_HOST,
      port: SMTP_PORT,
      username: SMTP_USERNAME,
      password: SMTP_PASSWORD,
      ssl: SMTP_PORT == 465,
      ignoreBadCertificate: true,
    );

    final message = Message()
      ..from = Address(FROM_EMAIL, FROM_NAME)
      ..recipients.add(toEmail)
      ..subject = subject
      ..text = body;

    try {
      final sendReport = await send(message, smtpServer);
      if (kDebugMode) print('Email sent: $sendReport');
      return true;
    } on MailerException catch (e) {
      if (kDebugMode) print('MailerException: $e');
      for (final problem in e.problems) {
        if (kDebugMode) print(' - problem: ${problem.code}: ${problem.msg}');
      }
      return false;
    } catch (e) {
      if (kDebugMode) print('Unexpected email error: $e');
      return false;
    }
  }
}
