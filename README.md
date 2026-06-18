# Robi SMS Logger

Robi থেকে আসা SMS automatically date + sender + content নিয়ে Google Sheet এ log করার Flutter app।

⚠️ এটা শুধুমাত্র **Android** এ কাজ করবে। iOS এ Apple কোনো app কে SMS পড়তে দেয় না, তাই এই app iOS এ চলবে না।

---

## ১. Project Setup (VS Code এ)

1. zip ফাইলটা extract করো এবং VS Code এ ফোল্ডারটা খোলো।
2. VS Code এর Terminal এ গিয়ে নিচের command চালাও — এটা `android/` ও `ios/` ফোল্ডার তোমার installed Flutter version অনুযায়ী generate করে দেবে (এই ফোল্ডারগুলো zip এ দেওয়া নেই, কারণ Flutter/Gradle version এর সাথে মিল রেখে generate হওয়াটাই সবচেয়ে নিরাপদ):

   ```
   flutter create .
   ```

3. তারপর:

   ```
   flutter pub get
   ```

4. `android/app/src/main/AndroidManifest.xml` ফাইলটা খোলো। `<manifest ...>` ট্যাগের ভেতরে, `<application>` ট্যাগের **উপরে**, নিচের permission গুলো যুক্ত করো:

   ```xml
   <uses-permission android:name="android.permission.INTERNET" />
   <uses-permission android:name="android.permission.READ_SMS" />
   <uses-permission android:name="android.permission.RECEIVE_SMS" />
   <uses-permission android:name="android.permission.RECEIVE_MMS" />
   ```

5. `lib/config.dart` ফাইলটা খুলে:
   - `allowedSenders` লিস্টে Robi এর sender name/number বসাও (ডিফল্ট ভাবে `"Robi"` আর `"ROBI"` দেওয়া আছে)।
   - `appsScriptUrl` এ তোমার Apps Script Web App URL বসাও (নিচের ধাপ ২ থেকে পাবে)।

---

## ২. Google Apps Script Setup (step by step)

1. sheets.google.com এ গিয়ে একটা নতুন **Blank spreadsheet** খোলো।
2. (ঐচ্ছিক) প্রথম row এ header বসাও — A1 = `Date`, B1 = `Sender`, C1 = `Content`।
3. মেনু থেকে **Extensions → Apps Script** ক্লিক করো। এটা একটা নতুন ট্যাবে script editor খুলবে।
4. Editor এ যে default code (`function myFunction() {...}`) থাকে, সব select করে delete করো।
5. এই project এর `appscript/Code.gs` ফাইলের পুরো কন্টেন্ট কপি করে এখানে paste করো।
6. উপরে 💾 (Save) আইকনে ক্লিক করো। চাইলে project এর একটা নাম দিতে পারো (যেমন `Robi SMS Logger`)।
7. ডানদিকে উপরে **Deploy → New deployment** এ ক্লিক করো।
8. "Select type" এর পাশে ⚙️ (gear) আইকনে ক্লিক করে **Web app** সিলেক্ট করো।
9. সেখানে:
   - **Execute as:** `Me`
   - **Who has access:** `Anyone`  ← এটা অবশ্যই দিতে হবে, না হলে phone থেকে পাঠানো request reject হবে।
10. **Deploy** বাটনে ক্লিক করো।
11. প্রথমবার একটা Authorization popup আসবে:
    - **Authorize access** ক্লিক করো
    - তোমার Google account select করো
    - "Google hasn't verified this app" এই রকম একটা warning আসবে — এটা normal, কারণ এটা তোমার নিজের script। **Advanced** ক্লিক করো → **Go to [project name] (unsafe)** ক্লিক করো → **Allow** দিয়ে দাও।
12. Deploy সম্পন্ন হলে একটা **Web app URL** (অনেক বড়, `https://script.google.com/macros/s/.../exec` এই রকম দেখতে) শো করবে। এটা কপি করো।
13. এই URL টা `lib/config.dart` এর `appsScriptUrl` এ paste করে দাও।

### টেস্ট করার উপায়
ব্রাউজারে গিয়ে সরাসরি ওই URL টা পেস্ট করে খুললে "Robi SMS Logger script চালু আছে ✅" লেখা দেখলে বুঝবে deployment সঠিক হয়েছে।

### ভবিষ্যতে Code.gs এ পরিবর্তন আনলে
Script edit করার পর পুরোনো URL এ change কাজ করবে না, যতক্ষণ না নতুন version deploy করো —
**Deploy → Manage deployments → ✏️ (edit) → Version: "New version" → Deploy**

---

## ৩. App Run করা

1. একটা real Android phone USB দিয়ে কানেক্ট করো (USB debugging চালু রেখে)। **এটা emulator এ properly test করা যাবে না**, কারণ emulator এ real SMS receive হয় না।
2. Terminal এ:

   ```
   flutter run
   ```

3. App ওপেন হলে "Listening শুরু করো" বাটনে ক্লিক করো, SMS permission allow করো।
4. এখন থেকে Robi থেকে কোনো SMS আসলে সেটা automatic ভাবে তোমার Google Sheet এ একটা নতুন row হিসেবে যুক্ত হয়ে যাবে।

---

## ৪. Reliability সংক্রান্ত টিপস

- Phone এর **Settings → Apps → Robi SMS Logger → Battery → Unrestricted/No restrictions** করে রাখো, না হলে Android battery optimization এর কারণে background এ app বন্ধ হয়ে গিয়ে message miss হতে পারে।
- কিছু কিছু ফোনের custom Android (Xiaomi/Oppo/Vivo ইত্যাদি) এ আলাদা করে "Autostart" বা "Background activity" অনুমতি দিতে হতে পারে — সেটা phone এর Settings এ খুঁজে allow করে দিও।
- App টা একবার বন্ধ করে আবার চালু করলে আবার "Listening শুরু করো" বাটনে ক্লিক করতে হবে।

---

## Project Structure

```
lib/
  main.dart        → UI
  config.dart       → তোমার sender list ও Apps Script URL
  sms_service.dart   → SMS listen, filter, duplicate check করার core logic
  sheets_api.dart    → Apps Script এ HTTP POST পাঠানো
appscript/
  Code.gs            → Google Sheet এর Apps Script এ paste করার কোড
```
