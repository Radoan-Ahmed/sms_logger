import 'dart:convert';
import 'package:http/http.dart' as http;
import 'config.dart';
import 'sms_service.dart' show smsLog;

/// Google Apps Script Web App এ data পাঠানোর জন্য responsible class।
class SheetsApi {
  static Future<bool> sendMessage({
    required String date,
    required String sender,
    required String content,
  }) async {
    if (AppConfig.appsScriptUrl.contains('PASTE_YOUR')) {
      smsLog('SheetsApi: appsScriptUrl এখনো config.dart এ সেট করা হয়নি।');
      return false;
    }

    final client = http.Client();
    try {
      smsLog('SheetsApi: POST করা হচ্ছে → ${AppConfig.appsScriptUrl}');
      http.Response response = await client.post(
        Uri.parse(AppConfig.appsScriptUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'date': date,
          'sender': sender,
          'content': content,
        }),
      );

      // Apps Script এর POST সফল হলে result টা googleusercontent.com এ একটা
      // 302 redirect দিয়ে দেয়। সেই redirect গুলো GET দিয়ে follow করি যতক্ষণ না
      // আসল 200 response পাই।
      var redirectCount = 0;
      while ((response.statusCode == 301 ||
              response.statusCode == 302 ||
              response.statusCode == 303 ||
              response.statusCode == 307 ||
              response.statusCode == 308) &&
          response.headers['location'] != null &&
          redirectCount < 5) {
        final location = response.headers['location']!;
        smsLog('SheetsApi: redirect (${response.statusCode}) follow → $location');
        response = await client.get(Uri.parse(location));
        redirectCount++;
      }

      smsLog(
        'SheetsApi: final statusCode=${response.statusCode}, '
        'body="${response.body}"',
      );
      return response.statusCode == 200;
    } catch (e, st) {
      // network বা script এ কোনো সমস্যা হলে এখানে ধরা পড়বে
      smsLog('SheetsApi: EXCEPTION → $e\n$st');
      return false;
    } finally {
      client.close();
    }
  }
}
