import 'dart:io';
import 'dart:typed_data';

import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import 'package:path_provider/path_provider.dart';

import '../domain/smtp_config.dart';

class SmtpEmailService {
  static Future<bool> sendDocumentEmail({
    required SmtpConfig config,
    required String recipientEmail,
    required String subject,
    required String bodyText,
    required Uint8List attachmentBytes,
    required String attachmentFilename,
    String? recipientName,
  }) async {
    final smtpServer = SmtpServer(
      config.host,
      port: config.port,
      ssl: config.isSsl,
      username: config.username,
      password: config.password,
    );

    // Save attachment to temp file
    final tempDir = await getTemporaryDirectory();
    final tempFile = File('${tempDir.path}/$attachmentFilename');
    await tempFile.writeAsBytes(attachmentBytes);

    final message = Message()
      ..from = Address(config.senderEmail, config.senderName)
      ..recipients.add(Address(recipientEmail, recipientName))
      ..subject = subject
      ..text = bodyText
      ..attachments.add(FileAttachment(tempFile));

    try {
      await send(message, smtpServer);
      return true;
    } catch (e) {
      rethrow;
    }
  }

  static Future<bool> testConnection(SmtpConfig config) async {
    final smtpServer = SmtpServer(
      config.host,
      port: config.port,
      ssl: config.isSsl,
      username: config.username,
      password: config.password,
    );

    final message = Message()
      ..from = Address(config.senderEmail, config.senderName)
      ..recipients.add(Address(config.senderEmail, config.senderName))
      ..subject = 'Etole SMTP Test Connection'
      ..text = 'Your Etole email settings are configured successfully!';

    try {
      await send(message, smtpServer);
      return true;
    } catch (e) {
      rethrow;
    }
  }
}
