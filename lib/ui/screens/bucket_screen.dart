import 'package:flutter/material.dart';

import '../../data/models/word_model.dart';
import '../widgets/word_card.dart';

class BucketScreen extends StatelessWidget {
  const BucketScreen({super.key});

  static final List<WordModel> _sampleWords = [
    WordModel(
      word: 'ephemeral',
      phonetic: '/\u026a\u02c8f\u025bm(\u0259)r\u0259l/',
      partOfSpeech: 'adjective',
      definition: 'Lasting for a very short time.',
      exampleSentence: 'The beauty of the sunset was ephemeral.',
      savedAt: DateTime(2026, 7, 16),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'WordBucket',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 16),
            child: Chip(label: Text('1 word')),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: _sampleWords.length,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) => WordCard(word: _sampleWords[index]),
        ),
      ),
    );
  }
}
