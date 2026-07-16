import 'package:flutter/material.dart';

import '../../data/models/word_model.dart';
import '../../data/services/dictionary_service.dart';
import '../widgets/word_card.dart';

class BucketScreen extends StatefulWidget {
  const BucketScreen({super.key});

  @override
  State<BucketScreen> createState() => _BucketScreenState();
}

class _BucketScreenState extends State<BucketScreen> {
  final _controller = TextEditingController();
  final _dictionary = DictionaryService();

  WordModel? _result;
  String? _error;
  bool _isLoading = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _lookUpWord() async {
    FocusScope.of(context).unfocus();
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final result = await _dictionary.define(_controller.text);
      if (!mounted) return;
      setState(() => _result = result);
    } on DictionaryException catch (error) {
      if (!mounted) return;
      setState(() {
        _result = null;
        _error = error.message;
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final wordCount = _result == null ? 0 : 1;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'WordBucket',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Chip(
              label: Text('$wordCount ${wordCount == 1 ? 'word' : 'words'}'),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              TextField(
                controller: _controller,
                textInputAction: TextInputAction.search,
                autocorrect: false,
                decoration: InputDecoration(
                  labelText: 'Look up a word',
                  hintText: 'Try “ephemeral”',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: IconButton(
                    tooltip: 'Search',
                    onPressed: _isLoading ? null : _lookUpWord,
                    icon: const Icon(Icons.arrow_forward),
                  ),
                  border: const OutlineInputBorder(),
                ),
                onSubmitted: _isLoading ? null : (_) => _lookUpWord(),
              ),
              const SizedBox(height: 20),
              Expanded(child: _buildContent(context)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Text(
          _error!,
          style: TextStyle(color: Theme.of(context).colorScheme.error),
          textAlign: TextAlign.center,
        ),
      );
    }

    if (_result != null) {
      return ListView(children: [WordCard(word: _result!)]);
    }

    return const Center(
      child: Text(
        'Enter a word above to fetch its definition.',
        textAlign: TextAlign.center,
      ),
    );
  }
}
