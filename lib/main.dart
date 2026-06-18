import 'package:flutter/material.dart';
import 'sms_service.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Robi SMS Logger',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.green,
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _isListening = false;
  bool _permissionGranted = false;
  final List<String> _logs = [];

  Future<void> _startListening() async {
    final granted = await SmsService.requestPermissions();
    setState(() => _permissionGranted = granted);

    if (!granted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('SMS permission দরকার, অনুগ্রহ করে allow করো।'),
          ),
        );
      }
      return;
    }

    await SmsService.startListening(
      onLog: (entry) {
        if (mounted) {
          setState(() {
            _logs.insert(0, entry);
          });
        }
      },
    );

    setState(() => _isListening = true);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Listening শুরু হয়ে গেছে ✅')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Robi SMS → Google Sheet')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: ListTile(
                title: Text(_isListening ? 'Listening চলছে' : 'বন্ধ আছে'),
                subtitle: Text(
                  _permissionGranted
                      ? 'SMS Permission: দেওয়া আছে'
                      : 'SMS Permission: দেওয়া নেই',
                ),
                trailing: Icon(
                  _isListening ? Icons.check_circle : Icons.circle_outlined,
                  color: _isListening ? Colors.green : Colors.grey,
                ),
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _isListening ? null : _startListening,
              child: const Text('Listening শুরু করো'),
            ),
            const SizedBox(height: 16),
            const Text(
              'সর্বশেষ যেগুলো Sheet এ পাঠানো হয়েছে:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: _logs.isEmpty
                  ? const Center(child: Text('এখনো কিছু নেই'))
                  : ListView.builder(
                      itemCount: _logs.length,
                      itemBuilder: (context, index) => Card(
                        child: ListTile(title: Text(_logs[index])),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
