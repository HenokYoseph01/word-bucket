import 'package:flutter/material.dart';

import 'core/theme.dart';
import 'ui/screens/bucket_screen.dart';

class WordBucketApp extends StatelessWidget {
  const WordBucketApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'WordBucket',
      debugShowCheckedModeBanner: false,
      theme: buildWordBucketTheme(),
      home: const BucketScreen(),
    );
  }
}
