import 'package:firep/screen/speech_screen.dart';
import 'package:flutter/material.dart';

void main() {
  // SystemChrome.setSystemUIOverlayStyle(
  //     const SystemUiOverlayStyle(statusBarColor: Colors.transparent));
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  MyApp({super.key});

  List<String> savedText = [];
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: SpeechScreen(savedTexts: savedText),
      debugShowCheckedModeBanner: false,
      title: 'Speech  to text',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
    );
  }
}
