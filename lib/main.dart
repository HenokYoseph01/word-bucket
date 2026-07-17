import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'background/review_worker.dart';

Future<void> main(List<String> arguments) async {
  WidgetsFlutterBinding.ensureInitialized();
  final bucketifyMode = arguments.contains('bucketify');
  if (!bucketifyMode) await initializeReviewWork();

  runApp(ProviderScope(child: WordBucketApp(bucketifyMode: bucketifyMode)));
}
