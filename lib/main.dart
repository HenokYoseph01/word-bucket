import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';

void main(List<String> arguments) {
  runApp(
    ProviderScope(
      child: WordBucketApp(bucketifyMode: arguments.contains('bucketify')),
    ),
  );
}
