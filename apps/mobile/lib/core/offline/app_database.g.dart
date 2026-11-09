// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $PendingSetLogsTable extends PendingSetLogs
    with TableInfo<$PendingSetLogsTable, PendingSetLog> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PendingSetLogsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _clientIdMeta = const VerificationMeta(
    'clientId',
  );
  @override
  late final GeneratedColumn<String> clientId = GeneratedColumn<String>(
    'client_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'user_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _workoutSessionIdMeta = const VerificationMeta(
    'workoutSessionId',
  );
  @override
  late final GeneratedColumn<String> workoutSessionId = GeneratedColumn<String>(
    'workout_session_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _workoutExerciseIdMeta = const VerificationMeta(
    'workoutExerciseId',
  );
  @override
  late final GeneratedColumn<String> workoutExerciseId =
      GeneratedColumn<String>(
        'workout_exercise_id',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _exerciseIdMeta = const VerificationMeta(
    'exerciseId',
  );
  @override
  late final GeneratedColumn<String> exerciseId = GeneratedColumn<String>(
    'exercise_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _setIndexMeta = const VerificationMeta(
    'setIndex',
  );
  @override
  late final GeneratedColumn<int> setIndex = GeneratedColumn<int>(
    'set_index',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _repsMeta = const VerificationMeta('reps');
  @override
  late final GeneratedColumn<int> reps = GeneratedColumn<int>(
    'reps',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _loadKgMeta = const VerificationMeta('loadKg');
  @override
  late final GeneratedColumn<double> loadKg = GeneratedColumn<double>(
    'load_kg',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _rirMeta = const VerificationMeta('rir');
  @override
  late final GeneratedColumn<int> rir = GeneratedColumn<int>(
    'rir',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _completedAtMeta = const VerificationMeta(
    'completedAt',
  );
  @override
  late final GeneratedColumn<DateTime> completedAt = GeneratedColumn<DateTime>(
    'completed_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<PendingSetLogStatus, String>
  status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: Constant(PendingSetLogStatus.pending.name),
  ).withConverter<PendingSetLogStatus>($PendingSetLogsTable.$converterstatus);
  static const VerificationMeta _attemptsMeta = const VerificationMeta(
    'attempts',
  );
  @override
  late final GeneratedColumn<int> attempts = GeneratedColumn<int>(
    'attempts',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _lastErrorMeta = const VerificationMeta(
    'lastError',
  );
  @override
  late final GeneratedColumn<String> lastError = GeneratedColumn<String>(
    'last_error',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _nextAttemptAtMeta = const VerificationMeta(
    'nextAttemptAt',
  );
  @override
  late final GeneratedColumn<DateTime> nextAttemptAt =
      GeneratedColumn<DateTime>(
        'next_attempt_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  @override
  List<GeneratedColumn> get $columns => [
    clientId,
    userId,
    workoutSessionId,
    workoutExerciseId,
    exerciseId,
    setIndex,
    reps,
    loadKg,
    rir,
    completedAt,
    updatedAt,
    status,
    attempts,
    lastError,
    nextAttemptAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'pending_set_logs';
  @override
  VerificationContext validateIntegrity(
    Insertable<PendingSetLog> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('client_id')) {
      context.handle(
        _clientIdMeta,
        clientId.isAcceptableOrUnknown(data['client_id']!, _clientIdMeta),
      );
    } else if (isInserting) {
      context.missing(_clientIdMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('workout_session_id')) {
      context.handle(
        _workoutSessionIdMeta,
        workoutSessionId.isAcceptableOrUnknown(
          data['workout_session_id']!,
          _workoutSessionIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_workoutSessionIdMeta);
    }
    if (data.containsKey('workout_exercise_id')) {
      context.handle(
        _workoutExerciseIdMeta,
        workoutExerciseId.isAcceptableOrUnknown(
          data['workout_exercise_id']!,
          _workoutExerciseIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_workoutExerciseIdMeta);
    }
    if (data.containsKey('exercise_id')) {
      context.handle(
        _exerciseIdMeta,
        exerciseId.isAcceptableOrUnknown(data['exercise_id']!, _exerciseIdMeta),
      );
    }
    if (data.containsKey('set_index')) {
      context.handle(
        _setIndexMeta,
        setIndex.isAcceptableOrUnknown(data['set_index']!, _setIndexMeta),
      );
    } else if (isInserting) {
      context.missing(_setIndexMeta);
    }
    if (data.containsKey('reps')) {
      context.handle(
        _repsMeta,
        reps.isAcceptableOrUnknown(data['reps']!, _repsMeta),
      );
    }
    if (data.containsKey('load_kg')) {
      context.handle(
        _loadKgMeta,
        loadKg.isAcceptableOrUnknown(data['load_kg']!, _loadKgMeta),
      );
    }
    if (data.containsKey('rir')) {
      context.handle(
        _rirMeta,
        rir.isAcceptableOrUnknown(data['rir']!, _rirMeta),
      );
    }
    if (data.containsKey('completed_at')) {
      context.handle(
        _completedAtMeta,
        completedAt.isAcceptableOrUnknown(
          data['completed_at']!,
          _completedAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_completedAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('attempts')) {
      context.handle(
        _attemptsMeta,
        attempts.isAcceptableOrUnknown(data['attempts']!, _attemptsMeta),
      );
    }
    if (data.containsKey('last_error')) {
      context.handle(
        _lastErrorMeta,
        lastError.isAcceptableOrUnknown(data['last_error']!, _lastErrorMeta),
      );
    }
    if (data.containsKey('next_attempt_at')) {
      context.handle(
        _nextAttemptAtMeta,
        nextAttemptAt.isAcceptableOrUnknown(
          data['next_attempt_at']!,
          _nextAttemptAtMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {clientId};
  @override
  PendingSetLog map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PendingSetLog(
      clientId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}client_id'],
      )!,
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      )!,
      workoutSessionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}workout_session_id'],
      )!,
      workoutExerciseId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}workout_exercise_id'],
      )!,
      exerciseId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}exercise_id'],
      ),
      setIndex: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}set_index'],
      )!,
      reps: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}reps'],
      ),
      loadKg: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}load_kg'],
      ),
      rir: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}rir'],
      ),
      completedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}completed_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      status: $PendingSetLogsTable.$converterstatus.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}status'],
        )!,
      ),
      attempts: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}attempts'],
      )!,
      lastError: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_error'],
      ),
      nextAttemptAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}next_attempt_at'],
      ),
    );
  }

  @override
  $PendingSetLogsTable createAlias(String alias) {
    return $PendingSetLogsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<PendingSetLogStatus, String, String>
  $converterstatus = const EnumNameConverter<PendingSetLogStatus>(
    PendingSetLogStatus.values,
  );
}

class PendingSetLog extends DataClass implements Insertable<PendingSetLog> {
  /// UUID v4 generado en el dispositivo. La API lo usará como clave de
  /// idempotencia (Fase 3): reenviar la misma serie no la duplica.
  final String clientId;

  /// Dueño de la serie: solo se sincroniza con la sesión de ese usuario.
  final String userId;
  final String workoutSessionId;

  /// `WorkoutExercise.id` de la sesión (segmento de la ruta del endpoint).
  final String workoutExerciseId;

  /// Id del ejercicio de catálogo (informativo).
  final String? exerciseId;
  final int setIndex;
  final int? reps;
  final double? loadKg;
  final int? rir;
  final DateTime completedAt;
  final DateTime updatedAt;
  final PendingSetLogStatus status;
  final int attempts;
  final String? lastError;

  /// Momento a partir del cual se puede reintentar (backoff exponencial).
  final DateTime? nextAttemptAt;
  const PendingSetLog({
    required this.clientId,
    required this.userId,
    required this.workoutSessionId,
    required this.workoutExerciseId,
    this.exerciseId,
    required this.setIndex,
    this.reps,
    this.loadKg,
    this.rir,
    required this.completedAt,
    required this.updatedAt,
    required this.status,
    required this.attempts,
    this.lastError,
    this.nextAttemptAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['client_id'] = Variable<String>(clientId);
    map['user_id'] = Variable<String>(userId);
    map['workout_session_id'] = Variable<String>(workoutSessionId);
    map['workout_exercise_id'] = Variable<String>(workoutExerciseId);
    if (!nullToAbsent || exerciseId != null) {
      map['exercise_id'] = Variable<String>(exerciseId);
    }
    map['set_index'] = Variable<int>(setIndex);
    if (!nullToAbsent || reps != null) {
      map['reps'] = Variable<int>(reps);
    }
    if (!nullToAbsent || loadKg != null) {
      map['load_kg'] = Variable<double>(loadKg);
    }
    if (!nullToAbsent || rir != null) {
      map['rir'] = Variable<int>(rir);
    }
    map['completed_at'] = Variable<DateTime>(completedAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    {
      map['status'] = Variable<String>(
        $PendingSetLogsTable.$converterstatus.toSql(status),
      );
    }
    map['attempts'] = Variable<int>(attempts);
    if (!nullToAbsent || lastError != null) {
      map['last_error'] = Variable<String>(lastError);
    }
    if (!nullToAbsent || nextAttemptAt != null) {
      map['next_attempt_at'] = Variable<DateTime>(nextAttemptAt);
    }
    return map;
  }

  PendingSetLogsCompanion toCompanion(bool nullToAbsent) {
    return PendingSetLogsCompanion(
      clientId: Value(clientId),
      userId: Value(userId),
      workoutSessionId: Value(workoutSessionId),
      workoutExerciseId: Value(workoutExerciseId),
      exerciseId: exerciseId == null && nullToAbsent
          ? const Value.absent()
          : Value(exerciseId),
      setIndex: Value(setIndex),
      reps: reps == null && nullToAbsent ? const Value.absent() : Value(reps),
      loadKg: loadKg == null && nullToAbsent
          ? const Value.absent()
          : Value(loadKg),
      rir: rir == null && nullToAbsent ? const Value.absent() : Value(rir),
      completedAt: Value(completedAt),
      updatedAt: Value(updatedAt),
      status: Value(status),
      attempts: Value(attempts),
      lastError: lastError == null && nullToAbsent
          ? const Value.absent()
          : Value(lastError),
      nextAttemptAt: nextAttemptAt == null && nullToAbsent
          ? const Value.absent()
          : Value(nextAttemptAt),
    );
  }

  factory PendingSetLog.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PendingSetLog(
      clientId: serializer.fromJson<String>(json['clientId']),
      userId: serializer.fromJson<String>(json['userId']),
      workoutSessionId: serializer.fromJson<String>(json['workoutSessionId']),
      workoutExerciseId: serializer.fromJson<String>(json['workoutExerciseId']),
      exerciseId: serializer.fromJson<String?>(json['exerciseId']),
      setIndex: serializer.fromJson<int>(json['setIndex']),
      reps: serializer.fromJson<int?>(json['reps']),
      loadKg: serializer.fromJson<double?>(json['loadKg']),
      rir: serializer.fromJson<int?>(json['rir']),
      completedAt: serializer.fromJson<DateTime>(json['completedAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      status: $PendingSetLogsTable.$converterstatus.fromJson(
        serializer.fromJson<String>(json['status']),
      ),
      attempts: serializer.fromJson<int>(json['attempts']),
      lastError: serializer.fromJson<String?>(json['lastError']),
      nextAttemptAt: serializer.fromJson<DateTime?>(json['nextAttemptAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'clientId': serializer.toJson<String>(clientId),
      'userId': serializer.toJson<String>(userId),
      'workoutSessionId': serializer.toJson<String>(workoutSessionId),
      'workoutExerciseId': serializer.toJson<String>(workoutExerciseId),
      'exerciseId': serializer.toJson<String?>(exerciseId),
      'setIndex': serializer.toJson<int>(setIndex),
      'reps': serializer.toJson<int?>(reps),
      'loadKg': serializer.toJson<double?>(loadKg),
      'rir': serializer.toJson<int?>(rir),
      'completedAt': serializer.toJson<DateTime>(completedAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'status': serializer.toJson<String>(
        $PendingSetLogsTable.$converterstatus.toJson(status),
      ),
      'attempts': serializer.toJson<int>(attempts),
      'lastError': serializer.toJson<String?>(lastError),
      'nextAttemptAt': serializer.toJson<DateTime?>(nextAttemptAt),
    };
  }

  PendingSetLog copyWith({
    String? clientId,
    String? userId,
    String? workoutSessionId,
    String? workoutExerciseId,
    Value<String?> exerciseId = const Value.absent(),
    int? setIndex,
    Value<int?> reps = const Value.absent(),
    Value<double?> loadKg = const Value.absent(),
    Value<int?> rir = const Value.absent(),
    DateTime? completedAt,
    DateTime? updatedAt,
    PendingSetLogStatus? status,
    int? attempts,
    Value<String?> lastError = const Value.absent(),
    Value<DateTime?> nextAttemptAt = const Value.absent(),
  }) => PendingSetLog(
    clientId: clientId ?? this.clientId,
    userId: userId ?? this.userId,
    workoutSessionId: workoutSessionId ?? this.workoutSessionId,
    workoutExerciseId: workoutExerciseId ?? this.workoutExerciseId,
    exerciseId: exerciseId.present ? exerciseId.value : this.exerciseId,
    setIndex: setIndex ?? this.setIndex,
    reps: reps.present ? reps.value : this.reps,
    loadKg: loadKg.present ? loadKg.value : this.loadKg,
    rir: rir.present ? rir.value : this.rir,
    completedAt: completedAt ?? this.completedAt,
    updatedAt: updatedAt ?? this.updatedAt,
    status: status ?? this.status,
    attempts: attempts ?? this.attempts,
    lastError: lastError.present ? lastError.value : this.lastError,
    nextAttemptAt: nextAttemptAt.present
        ? nextAttemptAt.value
        : this.nextAttemptAt,
  );
  PendingSetLog copyWithCompanion(PendingSetLogsCompanion data) {
    return PendingSetLog(
      clientId: data.clientId.present ? data.clientId.value : this.clientId,
      userId: data.userId.present ? data.userId.value : this.userId,
      workoutSessionId: data.workoutSessionId.present
          ? data.workoutSessionId.value
          : this.workoutSessionId,
      workoutExerciseId: data.workoutExerciseId.present
          ? data.workoutExerciseId.value
          : this.workoutExerciseId,
      exerciseId: data.exerciseId.present
          ? data.exerciseId.value
          : this.exerciseId,
      setIndex: data.setIndex.present ? data.setIndex.value : this.setIndex,
      reps: data.reps.present ? data.reps.value : this.reps,
      loadKg: data.loadKg.present ? data.loadKg.value : this.loadKg,
      rir: data.rir.present ? data.rir.value : this.rir,
      completedAt: data.completedAt.present
          ? data.completedAt.value
          : this.completedAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      status: data.status.present ? data.status.value : this.status,
      attempts: data.attempts.present ? data.attempts.value : this.attempts,
      lastError: data.lastError.present ? data.lastError.value : this.lastError,
      nextAttemptAt: data.nextAttemptAt.present
          ? data.nextAttemptAt.value
          : this.nextAttemptAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PendingSetLog(')
          ..write('clientId: $clientId, ')
          ..write('userId: $userId, ')
          ..write('workoutSessionId: $workoutSessionId, ')
          ..write('workoutExerciseId: $workoutExerciseId, ')
          ..write('exerciseId: $exerciseId, ')
          ..write('setIndex: $setIndex, ')
          ..write('reps: $reps, ')
          ..write('loadKg: $loadKg, ')
          ..write('rir: $rir, ')
          ..write('completedAt: $completedAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('status: $status, ')
          ..write('attempts: $attempts, ')
          ..write('lastError: $lastError, ')
          ..write('nextAttemptAt: $nextAttemptAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    clientId,
    userId,
    workoutSessionId,
    workoutExerciseId,
    exerciseId,
    setIndex,
    reps,
    loadKg,
    rir,
    completedAt,
    updatedAt,
    status,
    attempts,
    lastError,
    nextAttemptAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PendingSetLog &&
          other.clientId == this.clientId &&
          other.userId == this.userId &&
          other.workoutSessionId == this.workoutSessionId &&
          other.workoutExerciseId == this.workoutExerciseId &&
          other.exerciseId == this.exerciseId &&
          other.setIndex == this.setIndex &&
          other.reps == this.reps &&
          other.loadKg == this.loadKg &&
          other.rir == this.rir &&
          other.completedAt == this.completedAt &&
          other.updatedAt == this.updatedAt &&
          other.status == this.status &&
          other.attempts == this.attempts &&
          other.lastError == this.lastError &&
          other.nextAttemptAt == this.nextAttemptAt);
}

class PendingSetLogsCompanion extends UpdateCompanion<PendingSetLog> {
  final Value<String> clientId;
  final Value<String> userId;
  final Value<String> workoutSessionId;
  final Value<String> workoutExerciseId;
  final Value<String?> exerciseId;
  final Value<int> setIndex;
  final Value<int?> reps;
  final Value<double?> loadKg;
  final Value<int?> rir;
  final Value<DateTime> completedAt;
  final Value<DateTime> updatedAt;
  final Value<PendingSetLogStatus> status;
  final Value<int> attempts;
  final Value<String?> lastError;
  final Value<DateTime?> nextAttemptAt;
  final Value<int> rowid;
  const PendingSetLogsCompanion({
    this.clientId = const Value.absent(),
    this.userId = const Value.absent(),
    this.workoutSessionId = const Value.absent(),
    this.workoutExerciseId = const Value.absent(),
    this.exerciseId = const Value.absent(),
    this.setIndex = const Value.absent(),
    this.reps = const Value.absent(),
    this.loadKg = const Value.absent(),
    this.rir = const Value.absent(),
    this.completedAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.status = const Value.absent(),
    this.attempts = const Value.absent(),
    this.lastError = const Value.absent(),
    this.nextAttemptAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PendingSetLogsCompanion.insert({
    required String clientId,
    required String userId,
    required String workoutSessionId,
    required String workoutExerciseId,
    this.exerciseId = const Value.absent(),
    required int setIndex,
    this.reps = const Value.absent(),
    this.loadKg = const Value.absent(),
    this.rir = const Value.absent(),
    required DateTime completedAt,
    required DateTime updatedAt,
    this.status = const Value.absent(),
    this.attempts = const Value.absent(),
    this.lastError = const Value.absent(),
    this.nextAttemptAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : clientId = Value(clientId),
       userId = Value(userId),
       workoutSessionId = Value(workoutSessionId),
       workoutExerciseId = Value(workoutExerciseId),
       setIndex = Value(setIndex),
       completedAt = Value(completedAt),
       updatedAt = Value(updatedAt);
  static Insertable<PendingSetLog> custom({
    Expression<String>? clientId,
    Expression<String>? userId,
    Expression<String>? workoutSessionId,
    Expression<String>? workoutExerciseId,
    Expression<String>? exerciseId,
    Expression<int>? setIndex,
    Expression<int>? reps,
    Expression<double>? loadKg,
    Expression<int>? rir,
    Expression<DateTime>? completedAt,
    Expression<DateTime>? updatedAt,
    Expression<String>? status,
    Expression<int>? attempts,
    Expression<String>? lastError,
    Expression<DateTime>? nextAttemptAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (clientId != null) 'client_id': clientId,
      if (userId != null) 'user_id': userId,
      if (workoutSessionId != null) 'workout_session_id': workoutSessionId,
      if (workoutExerciseId != null) 'workout_exercise_id': workoutExerciseId,
      if (exerciseId != null) 'exercise_id': exerciseId,
      if (setIndex != null) 'set_index': setIndex,
      if (reps != null) 'reps': reps,
      if (loadKg != null) 'load_kg': loadKg,
      if (rir != null) 'rir': rir,
      if (completedAt != null) 'completed_at': completedAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (status != null) 'status': status,
      if (attempts != null) 'attempts': attempts,
      if (lastError != null) 'last_error': lastError,
      if (nextAttemptAt != null) 'next_attempt_at': nextAttemptAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PendingSetLogsCompanion copyWith({
    Value<String>? clientId,
    Value<String>? userId,
    Value<String>? workoutSessionId,
    Value<String>? workoutExerciseId,
    Value<String?>? exerciseId,
    Value<int>? setIndex,
    Value<int?>? reps,
    Value<double?>? loadKg,
    Value<int?>? rir,
    Value<DateTime>? completedAt,
    Value<DateTime>? updatedAt,
    Value<PendingSetLogStatus>? status,
    Value<int>? attempts,
    Value<String?>? lastError,
    Value<DateTime?>? nextAttemptAt,
    Value<int>? rowid,
  }) {
    return PendingSetLogsCompanion(
      clientId: clientId ?? this.clientId,
      userId: userId ?? this.userId,
      workoutSessionId: workoutSessionId ?? this.workoutSessionId,
      workoutExerciseId: workoutExerciseId ?? this.workoutExerciseId,
      exerciseId: exerciseId ?? this.exerciseId,
      setIndex: setIndex ?? this.setIndex,
      reps: reps ?? this.reps,
      loadKg: loadKg ?? this.loadKg,
      rir: rir ?? this.rir,
      completedAt: completedAt ?? this.completedAt,
      updatedAt: updatedAt ?? this.updatedAt,
      status: status ?? this.status,
      attempts: attempts ?? this.attempts,
      lastError: lastError ?? this.lastError,
      nextAttemptAt: nextAttemptAt ?? this.nextAttemptAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (clientId.present) {
      map['client_id'] = Variable<String>(clientId.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (workoutSessionId.present) {
      map['workout_session_id'] = Variable<String>(workoutSessionId.value);
    }
    if (workoutExerciseId.present) {
      map['workout_exercise_id'] = Variable<String>(workoutExerciseId.value);
    }
    if (exerciseId.present) {
      map['exercise_id'] = Variable<String>(exerciseId.value);
    }
    if (setIndex.present) {
      map['set_index'] = Variable<int>(setIndex.value);
    }
    if (reps.present) {
      map['reps'] = Variable<int>(reps.value);
    }
    if (loadKg.present) {
      map['load_kg'] = Variable<double>(loadKg.value);
    }
    if (rir.present) {
      map['rir'] = Variable<int>(rir.value);
    }
    if (completedAt.present) {
      map['completed_at'] = Variable<DateTime>(completedAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(
        $PendingSetLogsTable.$converterstatus.toSql(status.value),
      );
    }
    if (attempts.present) {
      map['attempts'] = Variable<int>(attempts.value);
    }
    if (lastError.present) {
      map['last_error'] = Variable<String>(lastError.value);
    }
    if (nextAttemptAt.present) {
      map['next_attempt_at'] = Variable<DateTime>(nextAttemptAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PendingSetLogsCompanion(')
          ..write('clientId: $clientId, ')
          ..write('userId: $userId, ')
          ..write('workoutSessionId: $workoutSessionId, ')
          ..write('workoutExerciseId: $workoutExerciseId, ')
          ..write('exerciseId: $exerciseId, ')
          ..write('setIndex: $setIndex, ')
          ..write('reps: $reps, ')
          ..write('loadKg: $loadKg, ')
          ..write('rir: $rir, ')
          ..write('completedAt: $completedAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('status: $status, ')
          ..write('attempts: $attempts, ')
          ..write('lastError: $lastError, ')
          ..write('nextAttemptAt: $nextAttemptAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $PendingSetLogsTable pendingSetLogs = $PendingSetLogsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [pendingSetLogs];
}

typedef $$PendingSetLogsTableCreateCompanionBuilder =
    PendingSetLogsCompanion Function({
      required String clientId,
      required String userId,
      required String workoutSessionId,
      required String workoutExerciseId,
      Value<String?> exerciseId,
      required int setIndex,
      Value<int?> reps,
      Value<double?> loadKg,
      Value<int?> rir,
      required DateTime completedAt,
      required DateTime updatedAt,
      Value<PendingSetLogStatus> status,
      Value<int> attempts,
      Value<String?> lastError,
      Value<DateTime?> nextAttemptAt,
      Value<int> rowid,
    });
typedef $$PendingSetLogsTableUpdateCompanionBuilder =
    PendingSetLogsCompanion Function({
      Value<String> clientId,
      Value<String> userId,
      Value<String> workoutSessionId,
      Value<String> workoutExerciseId,
      Value<String?> exerciseId,
      Value<int> setIndex,
      Value<int?> reps,
      Value<double?> loadKg,
      Value<int?> rir,
      Value<DateTime> completedAt,
      Value<DateTime> updatedAt,
      Value<PendingSetLogStatus> status,
      Value<int> attempts,
      Value<String?> lastError,
      Value<DateTime?> nextAttemptAt,
      Value<int> rowid,
    });

class $$PendingSetLogsTableFilterComposer
    extends Composer<_$AppDatabase, $PendingSetLogsTable> {
  $$PendingSetLogsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get clientId => $composableBuilder(
    column: $table.clientId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get workoutSessionId => $composableBuilder(
    column: $table.workoutSessionId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get workoutExerciseId => $composableBuilder(
    column: $table.workoutExerciseId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get exerciseId => $composableBuilder(
    column: $table.exerciseId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get setIndex => $composableBuilder(
    column: $table.setIndex,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get reps => $composableBuilder(
    column: $table.reps,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get loadKg => $composableBuilder(
    column: $table.loadKg,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get rir => $composableBuilder(
    column: $table.rir,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<
    PendingSetLogStatus,
    PendingSetLogStatus,
    String
  >
  get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<int> get attempts => $composableBuilder(
    column: $table.attempts,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastError => $composableBuilder(
    column: $table.lastError,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get nextAttemptAt => $composableBuilder(
    column: $table.nextAttemptAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PendingSetLogsTableOrderingComposer
    extends Composer<_$AppDatabase, $PendingSetLogsTable> {
  $$PendingSetLogsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get clientId => $composableBuilder(
    column: $table.clientId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get workoutSessionId => $composableBuilder(
    column: $table.workoutSessionId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get workoutExerciseId => $composableBuilder(
    column: $table.workoutExerciseId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get exerciseId => $composableBuilder(
    column: $table.exerciseId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get setIndex => $composableBuilder(
    column: $table.setIndex,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get reps => $composableBuilder(
    column: $table.reps,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get loadKg => $composableBuilder(
    column: $table.loadKg,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get rir => $composableBuilder(
    column: $table.rir,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get attempts => $composableBuilder(
    column: $table.attempts,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastError => $composableBuilder(
    column: $table.lastError,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get nextAttemptAt => $composableBuilder(
    column: $table.nextAttemptAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PendingSetLogsTableAnnotationComposer
    extends Composer<_$AppDatabase, $PendingSetLogsTable> {
  $$PendingSetLogsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get clientId =>
      $composableBuilder(column: $table.clientId, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get workoutSessionId => $composableBuilder(
    column: $table.workoutSessionId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get workoutExerciseId => $composableBuilder(
    column: $table.workoutExerciseId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get exerciseId => $composableBuilder(
    column: $table.exerciseId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get setIndex =>
      $composableBuilder(column: $table.setIndex, builder: (column) => column);

  GeneratedColumn<int> get reps =>
      $composableBuilder(column: $table.reps, builder: (column) => column);

  GeneratedColumn<double> get loadKg =>
      $composableBuilder(column: $table.loadKg, builder: (column) => column);

  GeneratedColumn<int> get rir =>
      $composableBuilder(column: $table.rir, builder: (column) => column);

  GeneratedColumn<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumnWithTypeConverter<PendingSetLogStatus, String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<int> get attempts =>
      $composableBuilder(column: $table.attempts, builder: (column) => column);

  GeneratedColumn<String> get lastError =>
      $composableBuilder(column: $table.lastError, builder: (column) => column);

  GeneratedColumn<DateTime> get nextAttemptAt => $composableBuilder(
    column: $table.nextAttemptAt,
    builder: (column) => column,
  );
}

class $$PendingSetLogsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PendingSetLogsTable,
          PendingSetLog,
          $$PendingSetLogsTableFilterComposer,
          $$PendingSetLogsTableOrderingComposer,
          $$PendingSetLogsTableAnnotationComposer,
          $$PendingSetLogsTableCreateCompanionBuilder,
          $$PendingSetLogsTableUpdateCompanionBuilder,
          (
            PendingSetLog,
            BaseReferences<_$AppDatabase, $PendingSetLogsTable, PendingSetLog>,
          ),
          PendingSetLog,
          PrefetchHooks Function()
        > {
  $$PendingSetLogsTableTableManager(
    _$AppDatabase db,
    $PendingSetLogsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PendingSetLogsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PendingSetLogsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PendingSetLogsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> clientId = const Value.absent(),
                Value<String> userId = const Value.absent(),
                Value<String> workoutSessionId = const Value.absent(),
                Value<String> workoutExerciseId = const Value.absent(),
                Value<String?> exerciseId = const Value.absent(),
                Value<int> setIndex = const Value.absent(),
                Value<int?> reps = const Value.absent(),
                Value<double?> loadKg = const Value.absent(),
                Value<int?> rir = const Value.absent(),
                Value<DateTime> completedAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<PendingSetLogStatus> status = const Value.absent(),
                Value<int> attempts = const Value.absent(),
                Value<String?> lastError = const Value.absent(),
                Value<DateTime?> nextAttemptAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PendingSetLogsCompanion(
                clientId: clientId,
                userId: userId,
                workoutSessionId: workoutSessionId,
                workoutExerciseId: workoutExerciseId,
                exerciseId: exerciseId,
                setIndex: setIndex,
                reps: reps,
                loadKg: loadKg,
                rir: rir,
                completedAt: completedAt,
                updatedAt: updatedAt,
                status: status,
                attempts: attempts,
                lastError: lastError,
                nextAttemptAt: nextAttemptAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String clientId,
                required String userId,
                required String workoutSessionId,
                required String workoutExerciseId,
                Value<String?> exerciseId = const Value.absent(),
                required int setIndex,
                Value<int?> reps = const Value.absent(),
                Value<double?> loadKg = const Value.absent(),
                Value<int?> rir = const Value.absent(),
                required DateTime completedAt,
                required DateTime updatedAt,
                Value<PendingSetLogStatus> status = const Value.absent(),
                Value<int> attempts = const Value.absent(),
                Value<String?> lastError = const Value.absent(),
                Value<DateTime?> nextAttemptAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PendingSetLogsCompanion.insert(
                clientId: clientId,
                userId: userId,
                workoutSessionId: workoutSessionId,
                workoutExerciseId: workoutExerciseId,
                exerciseId: exerciseId,
                setIndex: setIndex,
                reps: reps,
                loadKg: loadKg,
                rir: rir,
                completedAt: completedAt,
                updatedAt: updatedAt,
                status: status,
                attempts: attempts,
                lastError: lastError,
                nextAttemptAt: nextAttemptAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PendingSetLogsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PendingSetLogsTable,
      PendingSetLog,
      $$PendingSetLogsTableFilterComposer,
      $$PendingSetLogsTableOrderingComposer,
      $$PendingSetLogsTableAnnotationComposer,
      $$PendingSetLogsTableCreateCompanionBuilder,
      $$PendingSetLogsTableUpdateCompanionBuilder,
      (
        PendingSetLog,
        BaseReferences<_$AppDatabase, $PendingSetLogsTable, PendingSetLog>,
      ),
      PendingSetLog,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$PendingSetLogsTableTableManager get pendingSetLogs =>
      $$PendingSetLogsTableTableManager(_db, _db.pendingSetLogs);
}
