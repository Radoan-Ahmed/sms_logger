/// এই ফাইলে তোমার নিজের তথ্য বসাও।
class AppConfig {
  /// Robi থেকে আসা SMS identify করার জন্য sender name বা phone number।
  /// সাধারণত operator এর SMS এ sender হিসেবে "Robi" বা "ROBI" এই রকম নাম থাকে,
  /// কিন্তু কখনো কখনো সরাসরি phone number ও আসতে পারে। দুটোই নিচে দেওয়া যাবে,
  /// একটার সাথেও match করলে message টা ধরা হবে।
  static const List<String> allowedSenders = [
    'Robi',
    'ROBI',
    // 'ROBI4U',
    '01887949170', // চাইলে নির্দিষ্ট number ও যুক্ত করতে পারো
  ];

  /// Google Apps Script Deploy করার পর যে Web App URL পাবে,
  /// সেটা এখানে বসাও। (README.md এ ধাপে ধাপে দেখানো আছে কীভাবে পাবে)
  static const String appsScriptUrl =
      'PASTE_YOUR_APPS_SCRIPT_WEB_APP_URL_HERE/exec';
}
