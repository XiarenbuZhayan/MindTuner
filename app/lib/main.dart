import 'package:flutter/material.dart';
import 'backend_service.dart';  // 你之前创建的文件

void main() => runApp(const MyApp());

class MyApp extends StatefulWidget {
  const MyApp({super.key});
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String _status = 'Checking backend…';

  @override
  void initState() {
    super.initState();
    BackendService().ping().then((ok) {
      setState(() => _status = ok ? '✅ Backend OK' : '❌ Backend Failed');
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('MindTuner Test')),
        body: Center(
          child: Text(_status, style: const TextStyle(fontSize: 24)),
        ),
      ),
    );
  }
}

