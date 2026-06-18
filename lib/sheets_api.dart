import 'dart:convert';
import 'package:http/http.dart' as http;
import 'config.dart';

/// Google Apps Script Web App এ data পাঠানোর জন্য responsible class।
class SheetsApi {
  static Future<bool> sendMessage({
    required String date,
    required String sender,
    required String content,
  }) async {
    if (AppConfig.appsScriptUrl.contains('PASTE_YOUR')) {
      // URL এখনো সেট করা হয়নি।
      // print('appsScriptUrl এখনো config.dart এ সেট করা হয়নি।');
      return false;
    }

    try {
      final response = await http.post(
        Uri.parse(AppConfig.appsScriptUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'date': date,
          'sender': sender,
          'content': content,
        }),
      );
      return response.statusCode == 200;
    } catch (e) {
      // network বা script এ কোনো সমস্যা হলে এখানে ধরা পড়বে
      return false;
    }
  }
}
