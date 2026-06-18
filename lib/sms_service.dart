import 'package:another_telephony/telephony.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'config.dart';
import 'sheets_api.dart';

final Telephony telephony = Telephony.instance;

class SmsService {
  static const String _processedIdsKey = 'processed_sms_ids';

  /// Runtime এ SMS permission চাওয়া হবে
  static Future<bool> requestPermissions() async {
    final granted = await telephony.requestPhoneAndSmsPermissions;
    return granted ?? false;
  }

  /// SMS listening শুরু — app foreground এ থাকলেও, background এ থাকলেও কাজ করবে
  static Future<void> startListening({
    void Function(String logLine)? onLog,
  }) async {
    telephony.listenIncomingSms(
      onNewMessage: (SmsMessage message) {
        _handleMessage(message, onLog: onLog);
      },
      onBackgroundMessage: backgroundMessageHandler,
      listenInBackground: true,
    );
  }

  /// sender টা আমাদের allowedSenders list এর সাথে match করে কিনা
  static bool isFromAllowedSender(String? address) {
    if (address == null) return false;
    final normalized = address.toUpperCase();
    return AppConfig.allowedSenders.any(
      (sender) => normalized.contains(sender.toUpperCase()),
    );
  }

  static Future<bool> _alreadyProcessed(int? id) async {
    if (id == null) return false;
    final prefs = await SharedPreferences.getInstance();
    final List<String> ids = prefs.getStringList(_processedIdsKey) ?? [];
    return ids.contains(id.toString());
  }

  static Future<void> _markProcessed(int? id) async {
    if (id == null) return;
    final prefs = await SharedPreferences.getInstance();
    List<String> ids = prefs.getStringList(_processedIdsKey) ?? [];
    ids.add(id.toString());
    // অনেক বেশি বড় হয়ে গেলে পুরোনো গুলো ফেলে দেওয়া, memory বাঁচানোর জন্য
    if (ids.length > 300) {
      ids = ids.sublist(ids.length - 300);
    }
    await prefs.setStringList(_processedIdsKey, ids);
  }

  static Future<void> _handleMessage(
    SmsMessage message, {
    void Function(String logLine)? onLog,
  }) async {
    if (!isFromAllowedSender(message.address)) return;
    if (await _alreadyProcessed(message.id)) return;

    final date = message.date != null
        ? DateFormat('dd/MM/yyyy HH:mm:ss')
            .format(DateTime.fromMillisecondsSinceEpoch(message.date!))
        : DateFormat('dd/MM/yyyy HH:mm:ss').format(DateTime.now());

    final sent = await SheetsApi.sendMessage(
      date: date,
      sender: message.address ?? 'Unknown',
      content: message.body ?? '',
    );

    if (sent) {
      await _markProcessed(message.id);
      onLog?.call('$date  →  ${message.body ?? ""}');
    }
  }
}

/// app background এ থাকলে / kill হয়ে গেলেও এই function টা আলাদা isolate এ চলবে।
/// এই annotation টা must, না হলে release build এ কাজ করবে না।
@pragma('vm:entry-point')
Future<void> backgroundMessageHandler(SmsMessage message) async {
  await SmsService._handleMessage(message);
}
