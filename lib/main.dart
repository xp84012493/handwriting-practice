import 'package:flutter/material.dart';

import 'src/ui/handwriting_practice_home_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const HanziPracticeApp());
}

class HanziPracticeApp extends StatelessWidget {
  const HanziPracticeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '汉字笔顺练字帖',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF006A6A)),
        useMaterial3: true,
      ),
      home: const HandwritingPracticeHomePage(),
    );
  }
}
