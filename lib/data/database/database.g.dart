// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $WordsTable extends Words with TableInfo<$WordsTable, SavedWord> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WordsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _wordMeta = const VerificationMeta('word');
  @override
  late final GeneratedColumn<String> word = GeneratedColumn<String>(
    'word',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _phoneticMeta = const VerificationMeta(
    'phonetic',
  );
  @override
  late final GeneratedColumn<String> phonetic = GeneratedColumn<String>(
    'phonetic',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _partOfSpeechMeta = const VerificationMeta(
    'partOfSpeech',
  );
  @override
  late final GeneratedColumn<String> partOfSpeech = GeneratedColumn<String>(
    'part_of_speech',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _definitionMeta = const VerificationMeta(
    'definition',
  );
  @override
  late final GeneratedColumn<String> definition = GeneratedColumn<String>(
    'definition',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _exampleSentenceMeta = const VerificationMeta(
    'exampleSentence',
  );
  @override
  late final GeneratedColumn<String> exampleSentence = GeneratedColumn<String>(
    'example_sentence',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _savedAtMeta = const VerificationMeta(
    'savedAt',
  );
  @override
  late final GeneratedColumn<DateTime> savedAt = GeneratedColumn<DateTime>(
    'saved_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _reviewCountMeta = const VerificationMeta(
    'reviewCount',
  );
  @override
  late final GeneratedColumn<int> reviewCount = GeneratedColumn<int>(
    'review_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _nextReviewAtMeta = const VerificationMeta(
    'nextReviewAt',
  );
  @override
  late final GeneratedColumn<DateTime> nextReviewAt = GeneratedColumn<DateTime>(
    'next_review_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    word,
    phonetic,
    partOfSpeech,
    definition,
    exampleSentence,
    savedAt,
    reviewCount,
    nextReviewAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'words';
  @override
  VerificationContext validateIntegrity(
    Insertable<SavedWord> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('word')) {
      context.handle(
        _wordMeta,
        word.isAcceptableOrUnknown(data['word']!, _wordMeta),
      );
    } else if (isInserting) {
      context.missing(_wordMeta);
    }
    if (data.containsKey('phonetic')) {
      context.handle(
        _phoneticMeta,
        phonetic.isAcceptableOrUnknown(data['phonetic']!, _phoneticMeta),
      );
    }
    if (data.containsKey('part_of_speech')) {
      context.handle(
        _partOfSpeechMeta,
        partOfSpeech.isAcceptableOrUnknown(
          data['part_of_speech']!,
          _partOfSpeechMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_partOfSpeechMeta);
    }
    if (data.containsKey('definition')) {
      context.handle(
        _definitionMeta,
        definition.isAcceptableOrUnknown(data['definition']!, _definitionMeta),
      );
    } else if (isInserting) {
      context.missing(_definitionMeta);
    }
    if (data.containsKey('example_sentence')) {
      context.handle(
        _exampleSentenceMeta,
        exampleSentence.isAcceptableOrUnknown(
          data['example_sentence']!,
          _exampleSentenceMeta,
        ),
      );
    }
    if (data.containsKey('saved_at')) {
      context.handle(
        _savedAtMeta,
        savedAt.isAcceptableOrUnknown(data['saved_at']!, _savedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_savedAtMeta);
    }
    if (data.containsKey('review_count')) {
      context.handle(
        _reviewCountMeta,
        reviewCount.isAcceptableOrUnknown(
          data['review_count']!,
          _reviewCountMeta,
        ),
      );
    }
    if (data.containsKey('next_review_at')) {
      context.handle(
        _nextReviewAtMeta,
        nextReviewAt.isAcceptableOrUnknown(
          data['next_review_at']!,
          _nextReviewAtMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {word};
  @override
  SavedWord map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SavedWord(
      word: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}word'],
      )!,
      phonetic: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}phonetic'],
      ),
      partOfSpeech: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}part_of_speech'],
      )!,
      definition: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}definition'],
      )!,
      exampleSentence: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}example_sentence'],
      ),
      savedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}saved_at'],
      )!,
      reviewCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}review_count'],
      )!,
      nextReviewAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}next_review_at'],
      ),
    );
  }

  @override
  $WordsTable createAlias(String alias) {
    return $WordsTable(attachedDatabase, alias);
  }
}

class SavedWord extends DataClass implements Insertable<SavedWord> {
  final String word;
  final String? phonetic;
  final String partOfSpeech;
  final String definition;
  final String? exampleSentence;
  final DateTime savedAt;
  final int reviewCount;
  final DateTime? nextReviewAt;
  const SavedWord({
    required this.word,
    this.phonetic,
    required this.partOfSpeech,
    required this.definition,
    this.exampleSentence,
    required this.savedAt,
    required this.reviewCount,
    this.nextReviewAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['word'] = Variable<String>(word);
    if (!nullToAbsent || phonetic != null) {
      map['phonetic'] = Variable<String>(phonetic);
    }
    map['part_of_speech'] = Variable<String>(partOfSpeech);
    map['definition'] = Variable<String>(definition);
    if (!nullToAbsent || exampleSentence != null) {
      map['example_sentence'] = Variable<String>(exampleSentence);
    }
    map['saved_at'] = Variable<DateTime>(savedAt);
    map['review_count'] = Variable<int>(reviewCount);
    if (!nullToAbsent || nextReviewAt != null) {
      map['next_review_at'] = Variable<DateTime>(nextReviewAt);
    }
    return map;
  }

  WordsCompanion toCompanion(bool nullToAbsent) {
    return WordsCompanion(
      word: Value(word),
      phonetic: phonetic == null && nullToAbsent
          ? const Value.absent()
          : Value(phonetic),
      partOfSpeech: Value(partOfSpeech),
      definition: Value(definition),
      exampleSentence: exampleSentence == null && nullToAbsent
          ? const Value.absent()
          : Value(exampleSentence),
      savedAt: Value(savedAt),
      reviewCount: Value(reviewCount),
      nextReviewAt: nextReviewAt == null && nullToAbsent
          ? const Value.absent()
          : Value(nextReviewAt),
    );
  }

  factory SavedWord.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SavedWord(
      word: serializer.fromJson<String>(json['word']),
      phonetic: serializer.fromJson<String?>(json['phonetic']),
      partOfSpeech: serializer.fromJson<String>(json['partOfSpeech']),
      definition: serializer.fromJson<String>(json['definition']),
      exampleSentence: serializer.fromJson<String?>(json['exampleSentence']),
      savedAt: serializer.fromJson<DateTime>(json['savedAt']),
      reviewCount: serializer.fromJson<int>(json['reviewCount']),
      nextReviewAt: serializer.fromJson<DateTime?>(json['nextReviewAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'word': serializer.toJson<String>(word),
      'phonetic': serializer.toJson<String?>(phonetic),
      'partOfSpeech': serializer.toJson<String>(partOfSpeech),
      'definition': serializer.toJson<String>(definition),
      'exampleSentence': serializer.toJson<String?>(exampleSentence),
      'savedAt': serializer.toJson<DateTime>(savedAt),
      'reviewCount': serializer.toJson<int>(reviewCount),
      'nextReviewAt': serializer.toJson<DateTime?>(nextReviewAt),
    };
  }

  SavedWord copyWith({
    String? word,
    Value<String?> phonetic = const Value.absent(),
    String? partOfSpeech,
    String? definition,
    Value<String?> exampleSentence = const Value.absent(),
    DateTime? savedAt,
    int? reviewCount,
    Value<DateTime?> nextReviewAt = const Value.absent(),
  }) => SavedWord(
    word: word ?? this.word,
    phonetic: phonetic.present ? phonetic.value : this.phonetic,
    partOfSpeech: partOfSpeech ?? this.partOfSpeech,
    definition: definition ?? this.definition,
    exampleSentence: exampleSentence.present
        ? exampleSentence.value
        : this.exampleSentence,
    savedAt: savedAt ?? this.savedAt,
    reviewCount: reviewCount ?? this.reviewCount,
    nextReviewAt: nextReviewAt.present ? nextReviewAt.value : this.nextReviewAt,
  );
  SavedWord copyWithCompanion(WordsCompanion data) {
    return SavedWord(
      word: data.word.present ? data.word.value : this.word,
      phonetic: data.phonetic.present ? data.phonetic.value : this.phonetic,
      partOfSpeech: data.partOfSpeech.present
          ? data.partOfSpeech.value
          : this.partOfSpeech,
      definition: data.definition.present
          ? data.definition.value
          : this.definition,
      exampleSentence: data.exampleSentence.present
          ? data.exampleSentence.value
          : this.exampleSentence,
      savedAt: data.savedAt.present ? data.savedAt.value : this.savedAt,
      reviewCount: data.reviewCount.present
          ? data.reviewCount.value
          : this.reviewCount,
      nextReviewAt: data.nextReviewAt.present
          ? data.nextReviewAt.value
          : this.nextReviewAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SavedWord(')
          ..write('word: $word, ')
          ..write('phonetic: $phonetic, ')
          ..write('partOfSpeech: $partOfSpeech, ')
          ..write('definition: $definition, ')
          ..write('exampleSentence: $exampleSentence, ')
          ..write('savedAt: $savedAt, ')
          ..write('reviewCount: $reviewCount, ')
          ..write('nextReviewAt: $nextReviewAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    word,
    phonetic,
    partOfSpeech,
    definition,
    exampleSentence,
    savedAt,
    reviewCount,
    nextReviewAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SavedWord &&
          other.word == this.word &&
          other.phonetic == this.phonetic &&
          other.partOfSpeech == this.partOfSpeech &&
          other.definition == this.definition &&
          other.exampleSentence == this.exampleSentence &&
          other.savedAt == this.savedAt &&
          other.reviewCount == this.reviewCount &&
          other.nextReviewAt == this.nextReviewAt);
}

class WordsCompanion extends UpdateCompanion<SavedWord> {
  final Value<String> word;
  final Value<String?> phonetic;
  final Value<String> partOfSpeech;
  final Value<String> definition;
  final Value<String?> exampleSentence;
  final Value<DateTime> savedAt;
  final Value<int> reviewCount;
  final Value<DateTime?> nextReviewAt;
  final Value<int> rowid;
  const WordsCompanion({
    this.word = const Value.absent(),
    this.phonetic = const Value.absent(),
    this.partOfSpeech = const Value.absent(),
    this.definition = const Value.absent(),
    this.exampleSentence = const Value.absent(),
    this.savedAt = const Value.absent(),
    this.reviewCount = const Value.absent(),
    this.nextReviewAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  WordsCompanion.insert({
    required String word,
    this.phonetic = const Value.absent(),
    required String partOfSpeech,
    required String definition,
    this.exampleSentence = const Value.absent(),
    required DateTime savedAt,
    this.reviewCount = const Value.absent(),
    this.nextReviewAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : word = Value(word),
       partOfSpeech = Value(partOfSpeech),
       definition = Value(definition),
       savedAt = Value(savedAt);
  static Insertable<SavedWord> custom({
    Expression<String>? word,
    Expression<String>? phonetic,
    Expression<String>? partOfSpeech,
    Expression<String>? definition,
    Expression<String>? exampleSentence,
    Expression<DateTime>? savedAt,
    Expression<int>? reviewCount,
    Expression<DateTime>? nextReviewAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (word != null) 'word': word,
      if (phonetic != null) 'phonetic': phonetic,
      if (partOfSpeech != null) 'part_of_speech': partOfSpeech,
      if (definition != null) 'definition': definition,
      if (exampleSentence != null) 'example_sentence': exampleSentence,
      if (savedAt != null) 'saved_at': savedAt,
      if (reviewCount != null) 'review_count': reviewCount,
      if (nextReviewAt != null) 'next_review_at': nextReviewAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  WordsCompanion copyWith({
    Value<String>? word,
    Value<String?>? phonetic,
    Value<String>? partOfSpeech,
    Value<String>? definition,
    Value<String?>? exampleSentence,
    Value<DateTime>? savedAt,
    Value<int>? reviewCount,
    Value<DateTime?>? nextReviewAt,
    Value<int>? rowid,
  }) {
    return WordsCompanion(
      word: word ?? this.word,
      phonetic: phonetic ?? this.phonetic,
      partOfSpeech: partOfSpeech ?? this.partOfSpeech,
      definition: definition ?? this.definition,
      exampleSentence: exampleSentence ?? this.exampleSentence,
      savedAt: savedAt ?? this.savedAt,
      reviewCount: reviewCount ?? this.reviewCount,
      nextReviewAt: nextReviewAt ?? this.nextReviewAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (word.present) {
      map['word'] = Variable<String>(word.value);
    }
    if (phonetic.present) {
      map['phonetic'] = Variable<String>(phonetic.value);
    }
    if (partOfSpeech.present) {
      map['part_of_speech'] = Variable<String>(partOfSpeech.value);
    }
    if (definition.present) {
      map['definition'] = Variable<String>(definition.value);
    }
    if (exampleSentence.present) {
      map['example_sentence'] = Variable<String>(exampleSentence.value);
    }
    if (savedAt.present) {
      map['saved_at'] = Variable<DateTime>(savedAt.value);
    }
    if (reviewCount.present) {
      map['review_count'] = Variable<int>(reviewCount.value);
    }
    if (nextReviewAt.present) {
      map['next_review_at'] = Variable<DateTime>(nextReviewAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WordsCompanion(')
          ..write('word: $word, ')
          ..write('phonetic: $phonetic, ')
          ..write('partOfSpeech: $partOfSpeech, ')
          ..write('definition: $definition, ')
          ..write('exampleSentence: $exampleSentence, ')
          ..write('savedAt: $savedAt, ')
          ..write('reviewCount: $reviewCount, ')
          ..write('nextReviewAt: $nextReviewAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ReviewAttemptsTable extends ReviewAttempts
    with TableInfo<$ReviewAttemptsTable, ReviewAttempt> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ReviewAttemptsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _wordMeta = const VerificationMeta('word');
  @override
  late final GeneratedColumn<String> word = GeneratedColumn<String>(
    'word',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _reviewedAtMeta = const VerificationMeta(
    'reviewedAt',
  );
  @override
  late final GeneratedColumn<DateTime> reviewedAt = GeneratedColumn<DateTime>(
    'reviewed_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _rememberedMeta = const VerificationMeta(
    'remembered',
  );
  @override
  late final GeneratedColumn<bool> remembered = GeneratedColumn<bool>(
    'remembered',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("remembered" IN (0, 1))',
    ),
  );
  static const VerificationMeta _reviewCountMeta = const VerificationMeta(
    'reviewCount',
  );
  @override
  late final GeneratedColumn<int> reviewCount = GeneratedColumn<int>(
    'review_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    word,
    reviewedAt,
    remembered,
    reviewCount,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'review_attempts';
  @override
  VerificationContext validateIntegrity(
    Insertable<ReviewAttempt> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('word')) {
      context.handle(
        _wordMeta,
        word.isAcceptableOrUnknown(data['word']!, _wordMeta),
      );
    } else if (isInserting) {
      context.missing(_wordMeta);
    }
    if (data.containsKey('reviewed_at')) {
      context.handle(
        _reviewedAtMeta,
        reviewedAt.isAcceptableOrUnknown(data['reviewed_at']!, _reviewedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_reviewedAtMeta);
    }
    if (data.containsKey('remembered')) {
      context.handle(
        _rememberedMeta,
        remembered.isAcceptableOrUnknown(data['remembered']!, _rememberedMeta),
      );
    } else if (isInserting) {
      context.missing(_rememberedMeta);
    }
    if (data.containsKey('review_count')) {
      context.handle(
        _reviewCountMeta,
        reviewCount.isAcceptableOrUnknown(
          data['review_count']!,
          _reviewCountMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_reviewCountMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ReviewAttempt map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ReviewAttempt(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      word: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}word'],
      )!,
      reviewedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}reviewed_at'],
      )!,
      remembered: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}remembered'],
      )!,
      reviewCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}review_count'],
      )!,
    );
  }

  @override
  $ReviewAttemptsTable createAlias(String alias) {
    return $ReviewAttemptsTable(attachedDatabase, alias);
  }
}

class ReviewAttempt extends DataClass implements Insertable<ReviewAttempt> {
  final int id;
  final String word;
  final DateTime reviewedAt;
  final bool remembered;
  final int reviewCount;
  const ReviewAttempt({
    required this.id,
    required this.word,
    required this.reviewedAt,
    required this.remembered,
    required this.reviewCount,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['word'] = Variable<String>(word);
    map['reviewed_at'] = Variable<DateTime>(reviewedAt);
    map['remembered'] = Variable<bool>(remembered);
    map['review_count'] = Variable<int>(reviewCount);
    return map;
  }

  ReviewAttemptsCompanion toCompanion(bool nullToAbsent) {
    return ReviewAttemptsCompanion(
      id: Value(id),
      word: Value(word),
      reviewedAt: Value(reviewedAt),
      remembered: Value(remembered),
      reviewCount: Value(reviewCount),
    );
  }

  factory ReviewAttempt.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ReviewAttempt(
      id: serializer.fromJson<int>(json['id']),
      word: serializer.fromJson<String>(json['word']),
      reviewedAt: serializer.fromJson<DateTime>(json['reviewedAt']),
      remembered: serializer.fromJson<bool>(json['remembered']),
      reviewCount: serializer.fromJson<int>(json['reviewCount']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'word': serializer.toJson<String>(word),
      'reviewedAt': serializer.toJson<DateTime>(reviewedAt),
      'remembered': serializer.toJson<bool>(remembered),
      'reviewCount': serializer.toJson<int>(reviewCount),
    };
  }

  ReviewAttempt copyWith({
    int? id,
    String? word,
    DateTime? reviewedAt,
    bool? remembered,
    int? reviewCount,
  }) => ReviewAttempt(
    id: id ?? this.id,
    word: word ?? this.word,
    reviewedAt: reviewedAt ?? this.reviewedAt,
    remembered: remembered ?? this.remembered,
    reviewCount: reviewCount ?? this.reviewCount,
  );
  ReviewAttempt copyWithCompanion(ReviewAttemptsCompanion data) {
    return ReviewAttempt(
      id: data.id.present ? data.id.value : this.id,
      word: data.word.present ? data.word.value : this.word,
      reviewedAt: data.reviewedAt.present
          ? data.reviewedAt.value
          : this.reviewedAt,
      remembered: data.remembered.present
          ? data.remembered.value
          : this.remembered,
      reviewCount: data.reviewCount.present
          ? data.reviewCount.value
          : this.reviewCount,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ReviewAttempt(')
          ..write('id: $id, ')
          ..write('word: $word, ')
          ..write('reviewedAt: $reviewedAt, ')
          ..write('remembered: $remembered, ')
          ..write('reviewCount: $reviewCount')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, word, reviewedAt, remembered, reviewCount);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ReviewAttempt &&
          other.id == this.id &&
          other.word == this.word &&
          other.reviewedAt == this.reviewedAt &&
          other.remembered == this.remembered &&
          other.reviewCount == this.reviewCount);
}

class ReviewAttemptsCompanion extends UpdateCompanion<ReviewAttempt> {
  final Value<int> id;
  final Value<String> word;
  final Value<DateTime> reviewedAt;
  final Value<bool> remembered;
  final Value<int> reviewCount;
  const ReviewAttemptsCompanion({
    this.id = const Value.absent(),
    this.word = const Value.absent(),
    this.reviewedAt = const Value.absent(),
    this.remembered = const Value.absent(),
    this.reviewCount = const Value.absent(),
  });
  ReviewAttemptsCompanion.insert({
    this.id = const Value.absent(),
    required String word,
    required DateTime reviewedAt,
    required bool remembered,
    required int reviewCount,
  }) : word = Value(word),
       reviewedAt = Value(reviewedAt),
       remembered = Value(remembered),
       reviewCount = Value(reviewCount);
  static Insertable<ReviewAttempt> custom({
    Expression<int>? id,
    Expression<String>? word,
    Expression<DateTime>? reviewedAt,
    Expression<bool>? remembered,
    Expression<int>? reviewCount,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (word != null) 'word': word,
      if (reviewedAt != null) 'reviewed_at': reviewedAt,
      if (remembered != null) 'remembered': remembered,
      if (reviewCount != null) 'review_count': reviewCount,
    });
  }

  ReviewAttemptsCompanion copyWith({
    Value<int>? id,
    Value<String>? word,
    Value<DateTime>? reviewedAt,
    Value<bool>? remembered,
    Value<int>? reviewCount,
  }) {
    return ReviewAttemptsCompanion(
      id: id ?? this.id,
      word: word ?? this.word,
      reviewedAt: reviewedAt ?? this.reviewedAt,
      remembered: remembered ?? this.remembered,
      reviewCount: reviewCount ?? this.reviewCount,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (word.present) {
      map['word'] = Variable<String>(word.value);
    }
    if (reviewedAt.present) {
      map['reviewed_at'] = Variable<DateTime>(reviewedAt.value);
    }
    if (remembered.present) {
      map['remembered'] = Variable<bool>(remembered.value);
    }
    if (reviewCount.present) {
      map['review_count'] = Variable<int>(reviewCount.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ReviewAttemptsCompanion(')
          ..write('id: $id, ')
          ..write('word: $word, ')
          ..write('reviewedAt: $reviewedAt, ')
          ..write('remembered: $remembered, ')
          ..write('reviewCount: $reviewCount')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $WordsTable words = $WordsTable(this);
  late final $ReviewAttemptsTable reviewAttempts = $ReviewAttemptsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [words, reviewAttempts];
}

typedef $$WordsTableCreateCompanionBuilder =
    WordsCompanion Function({
      required String word,
      Value<String?> phonetic,
      required String partOfSpeech,
      required String definition,
      Value<String?> exampleSentence,
      required DateTime savedAt,
      Value<int> reviewCount,
      Value<DateTime?> nextReviewAt,
      Value<int> rowid,
    });
typedef $$WordsTableUpdateCompanionBuilder =
    WordsCompanion Function({
      Value<String> word,
      Value<String?> phonetic,
      Value<String> partOfSpeech,
      Value<String> definition,
      Value<String?> exampleSentence,
      Value<DateTime> savedAt,
      Value<int> reviewCount,
      Value<DateTime?> nextReviewAt,
      Value<int> rowid,
    });

class $$WordsTableFilterComposer extends Composer<_$AppDatabase, $WordsTable> {
  $$WordsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get word => $composableBuilder(
    column: $table.word,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get phonetic => $composableBuilder(
    column: $table.phonetic,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get partOfSpeech => $composableBuilder(
    column: $table.partOfSpeech,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get definition => $composableBuilder(
    column: $table.definition,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get exampleSentence => $composableBuilder(
    column: $table.exampleSentence,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get savedAt => $composableBuilder(
    column: $table.savedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get reviewCount => $composableBuilder(
    column: $table.reviewCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get nextReviewAt => $composableBuilder(
    column: $table.nextReviewAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$WordsTableOrderingComposer
    extends Composer<_$AppDatabase, $WordsTable> {
  $$WordsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get word => $composableBuilder(
    column: $table.word,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get phonetic => $composableBuilder(
    column: $table.phonetic,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get partOfSpeech => $composableBuilder(
    column: $table.partOfSpeech,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get definition => $composableBuilder(
    column: $table.definition,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get exampleSentence => $composableBuilder(
    column: $table.exampleSentence,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get savedAt => $composableBuilder(
    column: $table.savedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get reviewCount => $composableBuilder(
    column: $table.reviewCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get nextReviewAt => $composableBuilder(
    column: $table.nextReviewAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$WordsTableAnnotationComposer
    extends Composer<_$AppDatabase, $WordsTable> {
  $$WordsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get word =>
      $composableBuilder(column: $table.word, builder: (column) => column);

  GeneratedColumn<String> get phonetic =>
      $composableBuilder(column: $table.phonetic, builder: (column) => column);

  GeneratedColumn<String> get partOfSpeech => $composableBuilder(
    column: $table.partOfSpeech,
    builder: (column) => column,
  );

  GeneratedColumn<String> get definition => $composableBuilder(
    column: $table.definition,
    builder: (column) => column,
  );

  GeneratedColumn<String> get exampleSentence => $composableBuilder(
    column: $table.exampleSentence,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get savedAt =>
      $composableBuilder(column: $table.savedAt, builder: (column) => column);

  GeneratedColumn<int> get reviewCount => $composableBuilder(
    column: $table.reviewCount,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get nextReviewAt => $composableBuilder(
    column: $table.nextReviewAt,
    builder: (column) => column,
  );
}

class $$WordsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $WordsTable,
          SavedWord,
          $$WordsTableFilterComposer,
          $$WordsTableOrderingComposer,
          $$WordsTableAnnotationComposer,
          $$WordsTableCreateCompanionBuilder,
          $$WordsTableUpdateCompanionBuilder,
          (SavedWord, BaseReferences<_$AppDatabase, $WordsTable, SavedWord>),
          SavedWord,
          PrefetchHooks Function()
        > {
  $$WordsTableTableManager(_$AppDatabase db, $WordsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$WordsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$WordsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$WordsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> word = const Value.absent(),
                Value<String?> phonetic = const Value.absent(),
                Value<String> partOfSpeech = const Value.absent(),
                Value<String> definition = const Value.absent(),
                Value<String?> exampleSentence = const Value.absent(),
                Value<DateTime> savedAt = const Value.absent(),
                Value<int> reviewCount = const Value.absent(),
                Value<DateTime?> nextReviewAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => WordsCompanion(
                word: word,
                phonetic: phonetic,
                partOfSpeech: partOfSpeech,
                definition: definition,
                exampleSentence: exampleSentence,
                savedAt: savedAt,
                reviewCount: reviewCount,
                nextReviewAt: nextReviewAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String word,
                Value<String?> phonetic = const Value.absent(),
                required String partOfSpeech,
                required String definition,
                Value<String?> exampleSentence = const Value.absent(),
                required DateTime savedAt,
                Value<int> reviewCount = const Value.absent(),
                Value<DateTime?> nextReviewAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => WordsCompanion.insert(
                word: word,
                phonetic: phonetic,
                partOfSpeech: partOfSpeech,
                definition: definition,
                exampleSentence: exampleSentence,
                savedAt: savedAt,
                reviewCount: reviewCount,
                nextReviewAt: nextReviewAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$WordsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $WordsTable,
      SavedWord,
      $$WordsTableFilterComposer,
      $$WordsTableOrderingComposer,
      $$WordsTableAnnotationComposer,
      $$WordsTableCreateCompanionBuilder,
      $$WordsTableUpdateCompanionBuilder,
      (SavedWord, BaseReferences<_$AppDatabase, $WordsTable, SavedWord>),
      SavedWord,
      PrefetchHooks Function()
    >;
typedef $$ReviewAttemptsTableCreateCompanionBuilder =
    ReviewAttemptsCompanion Function({
      Value<int> id,
      required String word,
      required DateTime reviewedAt,
      required bool remembered,
      required int reviewCount,
    });
typedef $$ReviewAttemptsTableUpdateCompanionBuilder =
    ReviewAttemptsCompanion Function({
      Value<int> id,
      Value<String> word,
      Value<DateTime> reviewedAt,
      Value<bool> remembered,
      Value<int> reviewCount,
    });

class $$ReviewAttemptsTableFilterComposer
    extends Composer<_$AppDatabase, $ReviewAttemptsTable> {
  $$ReviewAttemptsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get word => $composableBuilder(
    column: $table.word,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get reviewedAt => $composableBuilder(
    column: $table.reviewedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get remembered => $composableBuilder(
    column: $table.remembered,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get reviewCount => $composableBuilder(
    column: $table.reviewCount,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ReviewAttemptsTableOrderingComposer
    extends Composer<_$AppDatabase, $ReviewAttemptsTable> {
  $$ReviewAttemptsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get word => $composableBuilder(
    column: $table.word,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get reviewedAt => $composableBuilder(
    column: $table.reviewedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get remembered => $composableBuilder(
    column: $table.remembered,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get reviewCount => $composableBuilder(
    column: $table.reviewCount,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ReviewAttemptsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ReviewAttemptsTable> {
  $$ReviewAttemptsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get word =>
      $composableBuilder(column: $table.word, builder: (column) => column);

  GeneratedColumn<DateTime> get reviewedAt => $composableBuilder(
    column: $table.reviewedAt,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get remembered => $composableBuilder(
    column: $table.remembered,
    builder: (column) => column,
  );

  GeneratedColumn<int> get reviewCount => $composableBuilder(
    column: $table.reviewCount,
    builder: (column) => column,
  );
}

class $$ReviewAttemptsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ReviewAttemptsTable,
          ReviewAttempt,
          $$ReviewAttemptsTableFilterComposer,
          $$ReviewAttemptsTableOrderingComposer,
          $$ReviewAttemptsTableAnnotationComposer,
          $$ReviewAttemptsTableCreateCompanionBuilder,
          $$ReviewAttemptsTableUpdateCompanionBuilder,
          (
            ReviewAttempt,
            BaseReferences<_$AppDatabase, $ReviewAttemptsTable, ReviewAttempt>,
          ),
          ReviewAttempt,
          PrefetchHooks Function()
        > {
  $$ReviewAttemptsTableTableManager(
    _$AppDatabase db,
    $ReviewAttemptsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ReviewAttemptsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ReviewAttemptsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ReviewAttemptsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> word = const Value.absent(),
                Value<DateTime> reviewedAt = const Value.absent(),
                Value<bool> remembered = const Value.absent(),
                Value<int> reviewCount = const Value.absent(),
              }) => ReviewAttemptsCompanion(
                id: id,
                word: word,
                reviewedAt: reviewedAt,
                remembered: remembered,
                reviewCount: reviewCount,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String word,
                required DateTime reviewedAt,
                required bool remembered,
                required int reviewCount,
              }) => ReviewAttemptsCompanion.insert(
                id: id,
                word: word,
                reviewedAt: reviewedAt,
                remembered: remembered,
                reviewCount: reviewCount,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ReviewAttemptsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ReviewAttemptsTable,
      ReviewAttempt,
      $$ReviewAttemptsTableFilterComposer,
      $$ReviewAttemptsTableOrderingComposer,
      $$ReviewAttemptsTableAnnotationComposer,
      $$ReviewAttemptsTableCreateCompanionBuilder,
      $$ReviewAttemptsTableUpdateCompanionBuilder,
      (
        ReviewAttempt,
        BaseReferences<_$AppDatabase, $ReviewAttemptsTable, ReviewAttempt>,
      ),
      ReviewAttempt,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$WordsTableTableManager get words =>
      $$WordsTableTableManager(_db, _db.words);
  $$ReviewAttemptsTableTableManager get reviewAttempts =>
      $$ReviewAttemptsTableTableManager(_db, _db.reviewAttempts);
}
