import 'dart:developer' as developer;
import 'package:another_telephony/telephony.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'config.dart';
import 'sheets_api.dart';

final Telephony telephony = Telephony.instance;

/// সব debug log এক জায়গায়। logcat এ `SMSLOG` দিয়ে filter করা যাবে।
void smsLog(String message) {
  // ignore: avoid_print
  print('SMSLOG: $message');
  developer.log(message, name: 'SMSLOG');
}

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
    smsLog('startListening() called — listener register করা হচ্ছে');
    telephony.listenIncomingSms(
      onNewMessage: (SmsMessage message) {
        smsLog('onNewMessage fired (foreground)');
        _handleMessage(message, onLog: onLog);
      },
      onBackgroundMessage: backgroundMessageHandler,
      listenInBackground: true,
    );
    smsLog('listenIncomingSms register সম্পন্ন');
  }

  /// sender টা আমাদের allowedSenders list এর সাথে match করে কিনা
  static bool isFromAllowedSender(String? address) {
    if (address == null) return false;
    final normalized = address.toUpperCase();
    return AppConfig.allowedSenders.any(
      (sender) => normalized.contains(sender.toUpperCase()),
    );
  }

  /// অনেক device এ message.id null আসে, তাই শুধু id দিয়ে duplicate ধরা যায় না।
  /// id থাকলে সেটা, না থাকলে date+address+body মিলিয়ে একটা stable key বানাই।
  static String _dedupKey(SmsMessage message) {
    if (message.id != null) return 'id:${message.id}';
    return 'k:${message.date}_${message.address}_${message.body}';
  }

  static Future<bool> _alreadyProcessed(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.reload(); // অন্য isolate এর লেখা পরিবর্তন দেখার জন্য
    final List<String> ids = prefs.getStringList(_processedIdsKey) ?? [];
    return ids.contains(key);
  }

  static Future<void> _markProcessed(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.reload();
    List<String> ids = prefs.getStringList(_processedIdsKey) ?? [];
    ids.add(key);
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
    smsLog(
      'message এসেছে → address="${message.address}", id=${message.id}, '
      'body="${message.body}"',
    );

    if (!isFromAllowedSender(message.address)) {
      smsLog(
        'SKIP: sender "${message.address}" allowedSenders এর সাথে match করেনি। '
        'allowed=${AppConfig.allowedSenders}',
      );
      return;
    }
    smsLog('OK: sender allowed');

    final dedupKey = _dedupKey(message);
    if (await _alreadyProcessed(dedupKey)) {
      smsLog('SKIP: "$dedupKey" আগেই process হয়ে গেছে (duplicate)');
      return;
    }

    final date = message.date != null
        ? DateFormat('dd/MM/yyyy HH:mm:ss')
            .format(DateTime.fromMillisecondsSinceEpoch(message.date!))
        : DateFormat('dd/MM/yyyy HH:mm:ss').format(DateTime.now());

    smsLog('Sheet এ পাঠানোর চেষ্টা হচ্ছে... (date=$date)');
    final sent = await SheetsApi.sendMessage(
      date: date,
      sender: message.address ?? 'Unknown',
      content: message.body ?? '',
    );

    if (sent) {
      await _markProcessed(dedupKey);
      smsLog('SUCCESS: Sheet এ পাঠানো হয়েছে ✅');
      onLog?.call('$date  →  ${message.body ?? ""}');
    } else {
      smsLog('FAIL: Sheet এ পাঠানো যায়নি ❌ (SheetsApi false ফিরিয়েছে)');
    }
  }
}

/// app background এ থাকলে / kill হয়ে গেলেও এই function টা আলাদা isolate এ চলবে।
/// এই annotation টা must, না হলে release build এ কাজ করবে না।
@pragma('vm:entry-point')
Future<void> backgroundMessageHandler(SmsMessage message) async {
  await SmsService._handleMessage(message);
}
