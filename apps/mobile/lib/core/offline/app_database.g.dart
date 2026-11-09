// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $LocalWorkoutsTable extends LocalWorkouts
    with TableInfo<$LocalWorkoutsTable, LocalWorkout> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalWorkoutsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _planSessionIdMeta = const VerificationMeta(
    'planSessionId',
  );
  @override
  late final GeneratedColumn<String> planSessionId = GeneratedColumn<String>(
    'plan_session_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _serverIdMeta = const VerificationMeta(
    'serverId',
  );
  @override
  late final GeneratedColumn<String> serverId = GeneratedColumn<String>(
    'server_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _startedAtMeta = const VerificationMeta(
    'startedAt',
  );
  @override
  late final GeneratedColumn<DateTime> startedAt = GeneratedColumn<DateTime>(
    'started_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _finishedAtMeta = const VerificationMeta(
    'finishedAt',
  );
  @override
  late final GeneratedColumn<DateTime> finishedAt = GeneratedColumn<DateTime>(
    'finished_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _finishSyncedMeta = const VerificationMeta(
    'finishSynced',
  );
  @override
  late final GeneratedColumn<bool> finishSynced = GeneratedColumn<bool>(
    'finish_synced',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("finish_synced" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
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
  static const VerificationMeta _adjustmentJsonMeta = const VerificationMeta(
    'adjustmentJson',
  );
  @override
  late final GeneratedColumn<String> adjustmentJson = GeneratedColumn<String>(
    'adjustment_json',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    clientId,
    userId,
    planSessionId,
    serverId,
    startedAt,
    finishedAt,
    finishSynced,
    attempts,
    lastError,
    nextAttemptAt,
    adjustmentJson,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_workouts';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalWorkout> instance, {
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
    if (data.containsKey('plan_session_id')) {
      context.handle(
        _planSessionIdMeta,
        planSessionId.isAcceptableOrUnknown(
          data['plan_session_id']!,
          _planSessionIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_planSessionIdMeta);
    }
    if (data.containsKey('server_id')) {
      context.handle(
        _serverIdMeta,
        serverId.isAcceptableOrUnknown(data['server_id']!, _serverIdMeta),
      );
    }
    if (data.containsKey('started_at')) {
      context.handle(
        _startedAtMeta,
        startedAt.isAcceptableOrUnknown(data['started_at']!, _startedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_startedAtMeta);
    }
    if (data.containsKey('finished_at')) {
      context.handle(
        _finishedAtMeta,
        finishedAt.isAcceptableOrUnknown(data['finished_at']!, _finishedAtMeta),
      );
    }
    if (data.containsKey('finish_synced')) {
      context.handle(
        _finishSyncedMeta,
        finishSynced.isAcceptableOrUnknown(
          data['finish_synced']!,
          _finishSyncedMeta,
        ),
      );
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
    if (data.containsKey('adjustment_json')) {
      context.handle(
        _adjustmentJsonMeta,
        adjustmentJson.isAcceptableOrUnknown(
          data['adjustment_json']!,
          _adjustmentJsonMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {clientId};
  @override
  LocalWorkout map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalWorkout(
      clientId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}client_id'],
      )!,
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      )!,
      planSessionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}plan_session_id'],
      )!,
      serverId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}server_id'],
      ),
      startedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}started_at'],
      )!,
      finishedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}finished_at'],
      ),
      finishSynced: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}finish_synced'],
      )!,
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
      adjustmentJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}adjustment_json'],
      ),
    );
  }

  @override
  $LocalWorkoutsTable createAlias(String alias) {
    return $LocalWorkoutsTable(attachedDatabase, alias);
  }
}

class LocalWorkout extends DataClass implements Insertable<LocalWorkout> {
  /// UUID v4 del dispositivo: clave de idempotencia de `POST /workouts`.
  final String clientId;
  final String userId;
  final String planSessionId;

  /// Id de la API; null hasta que el inicio se sincroniza.
  final String? serverId;
  final DateTime startedAt;

  /// Momento en que el usuario terminó (reloj del cliente).
  final DateTime? finishedAt;
  final bool finishSynced;
  final int attempts;
  final String? lastError;
  final DateTime? nextAttemptAt;

  /// Ajuste de hoy elegido antes de empezar (JSON de `WorkoutAdjustment`;
  /// null = sesión completa). Se envía en `POST /workouts`.
  final String? adjustmentJson;
  const LocalWorkout({
    required this.clientId,
    required this.userId,
    required this.planSessionId,
    this.serverId,
    required this.startedAt,
    this.finishedAt,
    required this.finishSynced,
    required this.attempts,
    this.lastError,
    this.nextAttemptAt,
    this.adjustmentJson,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['client_id'] = Variable<String>(clientId);
    map['user_id'] = Variable<String>(userId);
    map['plan_session_id'] = Variable<String>(planSessionId);
    if (!nullToAbsent || serverId != null) {
      map['server_id'] = Variable<String>(serverId);
    }
    map['started_at'] = Variable<DateTime>(startedAt);
    if (!nullToAbsent || finishedAt != null) {
      map['finished_at'] = Variable<DateTime>(finishedAt);
    }
    map['finish_synced'] = Variable<bool>(finishSynced);
    map['attempts'] = Variable<int>(attempts);
    if (!nullToAbsent || lastError != null) {
      map['last_error'] = Variable<String>(lastError);
    }
    if (!nullToAbsent || nextAttemptAt != null) {
      map['next_attempt_at'] = Variable<DateTime>(nextAttemptAt);
    }
    if (!nullToAbsent || adjustmentJson != null) {
      map['adjustment_json'] = Variable<String>(adjustmentJson);
    }
    return map;
  }

  LocalWorkoutsCompanion toCompanion(bool nullToAbsent) {
    return LocalWorkoutsCompanion(
      clientId: Value(clientId),
      userId: Value(userId),
      planSessionId: Value(planSessionId),
      serverId: serverId == null && nullToAbsent
          ? const Value.absent()
          : Value(serverId),
      startedAt: Value(startedAt),
      finishedAt: finishedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(finishedAt),
      finishSynced: Value(finishSynced),
      attempts: Value(attempts),
      lastError: lastError == null && nullToAbsent
          ? const Value.absent()
          : Value(lastError),
      nextAttemptAt: nextAttemptAt == null && nullToAbsent
          ? const Value.absent()
          : Value(nextAttemptAt),
      adjustmentJson: adjustmentJson == null && nullToAbsent
          ? const Value.absent()
          : Value(adjustmentJson),
    );
  }

  factory LocalWorkout.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalWorkout(
      clientId: serializer.fromJson<String>(json['clientId']),
      userId: serializer.fromJson<String>(json['userId']),
      planSessionId: serializer.fromJson<String>(json['planSessionId']),
      serverId: serializer.fromJson<String?>(json['serverId']),
      startedAt: serializer.fromJson<DateTime>(json['startedAt']),
      finishedAt: serializer.fromJson<DateTime?>(json['finishedAt']),
      finishSynced: serializer.fromJson<bool>(json['finishSynced']),
      attempts: serializer.fromJson<int>(json['attempts']),
      lastError: serializer.fromJson<String?>(json['lastError']),
      nextAttemptAt: serializer.fromJson<DateTime?>(json['nextAttemptAt']),
      adjustmentJson: serializer.fromJson<String?>(json['adjustmentJson']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'clientId': serializer.toJson<String>(clientId),
      'userId': serializer.toJson<String>(userId),
      'planSessionId': serializer.toJson<String>(planSessionId),
      'serverId': serializer.toJson<String?>(serverId),
      'startedAt': serializer.toJson<DateTime>(startedAt),
      'finishedAt': serializer.toJson<DateTime?>(finishedAt),
      'finishSynced': serializer.toJson<bool>(finishSynced),
      'attempts': serializer.toJson<int>(attempts),
      'lastError': serializer.toJson<String?>(lastError),
      'nextAttemptAt': serializer.toJson<DateTime?>(nextAttemptAt),
      'adjustmentJson': serializer.toJson<String?>(adjustmentJson),
    };
  }

  LocalWorkout copyWith({
    String? clientId,
    String? userId,
    String? planSessionId,
    Value<String?> serverId = const Value.absent(),
    DateTime? startedAt,
    Value<DateTime?> finishedAt = const Value.absent(),
    bool? finishSynced,
    int? attempts,
    Value<String?> lastError = const Value.absent(),
    Value<DateTime?> nextAttemptAt = const Value.absent(),
    Value<String?> adjustmentJson = const Value.absent(),
  }) => LocalWorkout(
    clientId: clientId ?? this.clientId,
    userId: userId ?? this.userId,
    planSessionId: planSessionId ?? this.planSessionId,
    serverId: serverId.present ? serverId.value : this.serverId,
    startedAt: startedAt ?? this.startedAt,
    finishedAt: finishedAt.present ? finishedAt.value : this.finishedAt,
    finishSynced: finishSynced ?? this.finishSynced,
    attempts: attempts ?? this.attempts,
    lastError: lastError.present ? lastError.value : this.lastError,
    nextAttemptAt: nextAttemptAt.present
        ? nextAttemptAt.value
        : this.nextAttemptAt,
    adjustmentJson: adjustmentJson.present
        ? adjustmentJson.value
        : this.adjustmentJson,
  );
  LocalWorkout copyWithCompanion(LocalWorkoutsCompanion data) {
    return LocalWorkout(
      clientId: data.clientId.present ? data.clientId.value : this.clientId,
      userId: data.userId.present ? data.userId.value : this.userId,
      planSessionId: data.planSessionId.present
          ? data.planSessionId.value
          : this.planSessionId,
      serverId: data.serverId.present ? data.serverId.value : this.serverId,
      startedAt: data.startedAt.present ? data.startedAt.value : this.startedAt,
      finishedAt: data.finishedAt.present
          ? data.finishedAt.value
          : this.finishedAt,
      finishSynced: data.finishSynced.present
          ? data.finishSynced.value
          : this.finishSynced,
      attempts: data.attempts.present ? data.attempts.value : this.attempts,
      lastError: data.lastError.present ? data.lastError.value : this.lastError,
      nextAttemptAt: data.nextAttemptAt.present
          ? data.nextAttemptAt.value
          : this.nextAttemptAt,
      adjustmentJson: data.adjustmentJson.present
          ? data.adjustmentJson.value
          : this.adjustmentJson,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalWorkout(')
          ..write('clientId: $clientId, ')
          ..write('userId: $userId, ')
          ..write('planSessionId: $planSessionId, ')
          ..write('serverId: $serverId, ')
          ..write('startedAt: $startedAt, ')
          ..write('finishedAt: $finishedAt, ')
          ..write('finishSynced: $finishSynced, ')
          ..write('attempts: $attempts, ')
          ..write('lastError: $lastError, ')
          ..write('nextAttemptAt: $nextAttemptAt, ')
          ..write('adjustmentJson: $adjustmentJson')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    clientId,
    userId,
    planSessionId,
    serverId,
    startedAt,
    finishedAt,
    finishSynced,
    attempts,
    lastError,
    nextAttemptAt,
    adjustmentJson,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalWorkout &&
          other.clientId == this.clientId &&
          other.userId == this.userId &&
          other.planSessionId == this.planSessionId &&
          other.serverId == this.serverId &&
          other.startedAt == this.startedAt &&
          other.finishedAt == this.finishedAt &&
          other.finishSynced == this.finishSynced &&
          other.attempts == this.attempts &&
          other.lastError == this.lastError &&
          other.nextAttemptAt == this.nextAttemptAt &&
          other.adjustmentJson == this.adjustmentJson);
}

class LocalWorkoutsCompanion extends UpdateCompanion<LocalWorkout> {
  final Value<String> clientId;
  final Value<String> userId;
  final Value<String> planSessionId;
  final Value<String?> serverId;
  final Value<DateTime> startedAt;
  final Value<DateTime?> finishedAt;
  final Value<bool> finishSynced;
  final Value<int> attempts;
  final Value<String?> lastError;
  final Value<DateTime?> nextAttemptAt;
  final Value<String?> adjustmentJson;
  final Value<int> rowid;
  const LocalWorkoutsCompanion({
    this.clientId = const Value.absent(),
    this.userId = const Value.absent(),
    this.planSessionId = const Value.absent(),
    this.serverId = const Value.absent(),
    this.startedAt = const Value.absent(),
    this.finishedAt = const Value.absent(),
    this.finishSynced = const Value.absent(),
    this.attempts = const Value.absent(),
    this.lastError = const Value.absent(),
    this.nextAttemptAt = const Value.absent(),
    this.adjustmentJson = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalWorkoutsCompanion.insert({
    required String clientId,
    required String userId,
    required String planSessionId,
    this.serverId = const Value.absent(),
    required DateTime startedAt,
    this.finishedAt = const Value.absent(),
    this.finishSynced = const Value.absent(),
    this.attempts = const Value.absent(),
    this.lastError = const Value.absent(),
    this.nextAttemptAt = const Value.absent(),
    this.adjustmentJson = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : clientId = Value(clientId),
       userId = Value(userId),
       planSessionId = Value(planSessionId),
       startedAt = Value(startedAt);
  static Insertable<LocalWorkout> custom({
    Expression<String>? clientId,
    Expression<String>? userId,
    Expression<String>? planSessionId,
    Expression<String>? serverId,
    Expression<DateTime>? startedAt,
    Expression<DateTime>? finishedAt,
    Expression<bool>? finishSynced,
    Expression<int>? attempts,
    Expression<String>? lastError,
    Expression<DateTime>? nextAttemptAt,
    Expression<String>? adjustmentJson,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (clientId != null) 'client_id': clientId,
      if (userId != null) 'user_id': userId,
      if (planSessionId != null) 'plan_session_id': planSessionId,
      if (serverId != null) 'server_id': serverId,
      if (startedAt != null) 'started_at': startedAt,
      if (finishedAt != null) 'finished_at': finishedAt,
      if (finishSynced != null) 'finish_synced': finishSynced,
      if (attempts != null) 'attempts': attempts,
      if (lastError != null) 'last_error': lastError,
      if (nextAttemptAt != null) 'next_attempt_at': nextAttemptAt,
      if (adjustmentJson != null) 'adjustment_json': adjustmentJson,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalWorkoutsCompanion copyWith({
    Value<String>? clientId,
    Value<String>? userId,
    Value<String>? planSessionId,
    Value<String?>? serverId,
    Value<DateTime>? startedAt,
    Value<DateTime?>? finishedAt,
    Value<bool>? finishSynced,
    Value<int>? attempts,
    Value<String?>? lastError,
    Value<DateTime?>? nextAttemptAt,
    Value<String?>? adjustmentJson,
    Value<int>? rowid,
  }) {
    return LocalWorkoutsCompanion(
      clientId: clientId ?? this.clientId,
      userId: userId ?? this.userId,
      planSessionId: planSessionId ?? this.planSessionId,
      serverId: serverId ?? this.serverId,
      startedAt: startedAt ?? this.startedAt,
      finishedAt: finishedAt ?? this.finishedAt,
      finishSynced: finishSynced ?? this.finishSynced,
      attempts: attempts ?? this.attempts,
      lastError: lastError ?? this.lastError,
      nextAttemptAt: nextAttemptAt ?? this.nextAttemptAt,
      adjustmentJson: adjustmentJson ?? this.adjustmentJson,
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
    if (planSessionId.present) {
      map['plan_session_id'] = Variable<String>(planSessionId.value);
    }
    if (serverId.present) {
      map['server_id'] = Variable<String>(serverId.value);
    }
    if (startedAt.present) {
      map['started_at'] = Variable<DateTime>(startedAt.value);
    }
    if (finishedAt.present) {
      map['finished_at'] = Variable<DateTime>(finishedAt.value);
    }
    if (finishSynced.present) {
      map['finish_synced'] = Variable<bool>(finishSynced.value);
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
    if (adjustmentJson.present) {
      map['adjustment_json'] = Variable<String>(adjustmentJson.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalWorkoutsCompanion(')
          ..write('clientId: $clientId, ')
          ..write('userId: $userId, ')
          ..write('planSessionId: $planSessionId, ')
          ..write('serverId: $serverId, ')
          ..write('startedAt: $startedAt, ')
          ..write('finishedAt: $finishedAt, ')
          ..write('finishSynced: $finishSynced, ')
          ..write('attempts: $attempts, ')
          ..write('lastError: $lastError, ')
          ..write('nextAttemptAt: $nextAttemptAt, ')
          ..write('adjustmentJson: $adjustmentJson, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LocalSetLogsTable extends LocalSetLogs
    with TableInfo<$LocalSetLogsTable, LocalSetLog> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalSetLogsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _workoutClientIdMeta = const VerificationMeta(
    'workoutClientId',
  );
  @override
  late final GeneratedColumn<String> workoutClientId = GeneratedColumn<String>(
    'workout_client_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _planExerciseIdMeta = const VerificationMeta(
    'planExerciseId',
  );
  @override
  late final GeneratedColumn<String> planExerciseId = GeneratedColumn<String>(
    'plan_exercise_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _exerciseIdMeta = const VerificationMeta(
    'exerciseId',
  );
  @override
  late final GeneratedColumn<String> exerciseId = GeneratedColumn<String>(
    'exercise_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
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
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _loadKgMeta = const VerificationMeta('loadKg');
  @override
  late final GeneratedColumn<double> loadKg = GeneratedColumn<double>(
    'load_kg',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
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
  static const VerificationMeta _isWarmupMeta = const VerificationMeta(
    'isWarmup',
  );
  @override
  late final GeneratedColumn<bool> isWarmup = GeneratedColumn<bool>(
    'is_warmup',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_warmup" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
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
  late final GeneratedColumnWithTypeConverter<SetSyncStatus, String> status =
      GeneratedColumn<String>(
        'status',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: Constant(SetSyncStatus.pending.name),
      ).withConverter<SetSyncStatus>($LocalSetLogsTable.$converterstatus);
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
    workoutClientId,
    planExerciseId,
    exerciseId,
    setIndex,
    reps,
    loadKg,
    rir,
    isWarmup,
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
  static const String $name = 'local_set_logs';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalSetLog> instance, {
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
    if (data.containsKey('workout_client_id')) {
      context.handle(
        _workoutClientIdMeta,
        workoutClientId.isAcceptableOrUnknown(
          data['workout_client_id']!,
          _workoutClientIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_workoutClientIdMeta);
    }
    if (data.containsKey('plan_exercise_id')) {
      context.handle(
        _planExerciseIdMeta,
        planExerciseId.isAcceptableOrUnknown(
          data['plan_exercise_id']!,
          _planExerciseIdMeta,
        ),
      );
    }
    if (data.containsKey('exercise_id')) {
      context.handle(
        _exerciseIdMeta,
        exerciseId.isAcceptableOrUnknown(data['exercise_id']!, _exerciseIdMeta),
      );
    } else if (isInserting) {
      context.missing(_exerciseIdMeta);
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
    } else if (isInserting) {
      context.missing(_repsMeta);
    }
    if (data.containsKey('load_kg')) {
      context.handle(
        _loadKgMeta,
        loadKg.isAcceptableOrUnknown(data['load_kg']!, _loadKgMeta),
      );
    } else if (isInserting) {
      context.missing(_loadKgMeta);
    }
    if (data.containsKey('rir')) {
      context.handle(
        _rirMeta,
        rir.isAcceptableOrUnknown(data['rir']!, _rirMeta),
      );
    }
    if (data.containsKey('is_warmup')) {
      context.handle(
        _isWarmupMeta,
        isWarmup.isAcceptableOrUnknown(data['is_warmup']!, _isWarmupMeta),
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
  LocalSetLog map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalSetLog(
      clientId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}client_id'],
      )!,
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      )!,
      workoutClientId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}workout_client_id'],
      )!,
      planExerciseId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}plan_exercise_id'],
      ),
      exerciseId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}exercise_id'],
      )!,
      setIndex: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}set_index'],
      )!,
      reps: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}reps'],
      )!,
      loadKg: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}load_kg'],
      )!,
      rir: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}rir'],
      ),
      isWarmup: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_warmup'],
      )!,
      completedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}completed_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      status: $LocalSetLogsTable.$converterstatus.fromSql(
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
  $LocalSetLogsTable createAlias(String alias) {
    return $LocalSetLogsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<SetSyncStatus, String, String> $converterstatus =
      const EnumNameConverter<SetSyncStatus>(SetSyncStatus.values);
}

class LocalSetLog extends DataClass implements Insertable<LocalSetLog> {
  /// UUID v4 del dispositivo: clave de idempotencia de la serie.
  final String clientId;
  final String userId;
  final String workoutClientId;
  final String? planExerciseId;

  /// Ejercicio realmente hecho (puede ser un sustituto).
  final String exerciseId;
  final int setIndex;
  final int reps;
  final double loadKg;
  final int? rir;
  final bool isWarmup;
  final DateTime completedAt;
  final DateTime updatedAt;
  final SetSyncStatus status;
  final int attempts;
  final String? lastError;

  /// Momento a partir del cual se puede reintentar (backoff exponencial).
  final DateTime? nextAttemptAt;
  const LocalSetLog({
    required this.clientId,
    required this.userId,
    required this.workoutClientId,
    this.planExerciseId,
    required this.exerciseId,
    required this.setIndex,
    required this.reps,
    required this.loadKg,
    this.rir,
    required this.isWarmup,
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
    map['workout_client_id'] = Variable<String>(workoutClientId);
    if (!nullToAbsent || planExerciseId != null) {
      map['plan_exercise_id'] = Variable<String>(planExerciseId);
    }
    map['exercise_id'] = Variable<String>(exerciseId);
    map['set_index'] = Variable<int>(setIndex);
    map['reps'] = Variable<int>(reps);
    map['load_kg'] = Variable<double>(loadKg);
    if (!nullToAbsent || rir != null) {
      map['rir'] = Variable<int>(rir);
    }
    map['is_warmup'] = Variable<bool>(isWarmup);
    map['completed_at'] = Variable<DateTime>(completedAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    {
      map['status'] = Variable<String>(
        $LocalSetLogsTable.$converterstatus.toSql(status),
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

  LocalSetLogsCompanion toCompanion(bool nullToAbsent) {
    return LocalSetLogsCompanion(
      clientId: Value(clientId),
      userId: Value(userId),
      workoutClientId: Value(workoutClientId),
      planExerciseId: planExerciseId == null && nullToAbsent
          ? const Value.absent()
          : Value(planExerciseId),
      exerciseId: Value(exerciseId),
      setIndex: Value(setIndex),
      reps: Value(reps),
      loadKg: Value(loadKg),
      rir: rir == null && nullToAbsent ? const Value.absent() : Value(rir),
      isWarmup: Value(isWarmup),
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

  factory LocalSetLog.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalSetLog(
      clientId: serializer.fromJson<String>(json['clientId']),
      userId: serializer.fromJson<String>(json['userId']),
      workoutClientId: serializer.fromJson<String>(json['workoutClientId']),
      planExerciseId: serializer.fromJson<String?>(json['planExerciseId']),
      exerciseId: serializer.fromJson<String>(json['exerciseId']),
      setIndex: serializer.fromJson<int>(json['setIndex']),
      reps: serializer.fromJson<int>(json['reps']),
      loadKg: serializer.fromJson<double>(json['loadKg']),
      rir: serializer.fromJson<int?>(json['rir']),
      isWarmup: serializer.fromJson<bool>(json['isWarmup']),
      completedAt: serializer.fromJson<DateTime>(json['completedAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      status: $LocalSetLogsTable.$converterstatus.fromJson(
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
      'workoutClientId': serializer.toJson<String>(workoutClientId),
      'planExerciseId': serializer.toJson<String?>(planExerciseId),
      'exerciseId': serializer.toJson<String>(exerciseId),
      'setIndex': serializer.toJson<int>(setIndex),
      'reps': serializer.toJson<int>(reps),
      'loadKg': serializer.toJson<double>(loadKg),
      'rir': serializer.toJson<int?>(rir),
      'isWarmup': serializer.toJson<bool>(isWarmup),
      'completedAt': serializer.toJson<DateTime>(completedAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'status': serializer.toJson<String>(
        $LocalSetLogsTable.$converterstatus.toJson(status),
      ),
      'attempts': serializer.toJson<int>(attempts),
      'lastError': serializer.toJson<String?>(lastError),
      'nextAttemptAt': serializer.toJson<DateTime?>(nextAttemptAt),
    };
  }

  LocalSetLog copyWith({
    String? clientId,
    String? userId,
    String? workoutClientId,
    Value<String?> planExerciseId = const Value.absent(),
    String? exerciseId,
    int? setIndex,
    int? reps,
    double? loadKg,
    Value<int?> rir = const Value.absent(),
    bool? isWarmup,
    DateTime? completedAt,
    DateTime? updatedAt,
    SetSyncStatus? status,
    int? attempts,
    Value<String?> lastError = const Value.absent(),
    Value<DateTime?> nextAttemptAt = const Value.absent(),
  }) => LocalSetLog(
    clientId: clientId ?? this.clientId,
    userId: userId ?? this.userId,
    workoutClientId: workoutClientId ?? this.workoutClientId,
    planExerciseId: planExerciseId.present
        ? planExerciseId.value
        : this.planExerciseId,
    exerciseId: exerciseId ?? this.exerciseId,
    setIndex: setIndex ?? this.setIndex,
    reps: reps ?? this.reps,
    loadKg: loadKg ?? this.loadKg,
    rir: rir.present ? rir.value : this.rir,
    isWarmup: isWarmup ?? this.isWarmup,
    completedAt: completedAt ?? this.completedAt,
    updatedAt: updatedAt ?? this.updatedAt,
    status: status ?? this.status,
    attempts: attempts ?? this.attempts,
    lastError: lastError.present ? lastError.value : this.lastError,
    nextAttemptAt: nextAttemptAt.present
        ? nextAttemptAt.value
        : this.nextAttemptAt,
  );
  LocalSetLog copyWithCompanion(LocalSetLogsCompanion data) {
    return LocalSetLog(
      clientId: data.clientId.present ? data.clientId.value : this.clientId,
      userId: data.userId.present ? data.userId.value : this.userId,
      workoutClientId: data.workoutClientId.present
          ? data.workoutClientId.value
          : this.workoutClientId,
      planExerciseId: data.planExerciseId.present
          ? data.planExerciseId.value
          : this.planExerciseId,
      exerciseId: data.exerciseId.present
          ? data.exerciseId.value
          : this.exerciseId,
      setIndex: data.setIndex.present ? data.setIndex.value : this.setIndex,
      reps: data.reps.present ? data.reps.value : this.reps,
      loadKg: data.loadKg.present ? data.loadKg.value : this.loadKg,
      rir: data.rir.present ? data.rir.value : this.rir,
      isWarmup: data.isWarmup.present ? data.isWarmup.value : this.isWarmup,
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
    return (StringBuffer('LocalSetLog(')
          ..write('clientId: $clientId, ')
          ..write('userId: $userId, ')
          ..write('workoutClientId: $workoutClientId, ')
          ..write('planExerciseId: $planExerciseId, ')
          ..write('exerciseId: $exerciseId, ')
          ..write('setIndex: $setIndex, ')
          ..write('reps: $reps, ')
          ..write('loadKg: $loadKg, ')
          ..write('rir: $rir, ')
          ..write('isWarmup: $isWarmup, ')
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
    workoutClientId,
    planExerciseId,
    exerciseId,
    setIndex,
    reps,
    loadKg,
    rir,
    isWarmup,
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
      (other is LocalSetLog &&
          other.clientId == this.clientId &&
          other.userId == this.userId &&
          other.workoutClientId == this.workoutClientId &&
          other.planExerciseId == this.planExerciseId &&
          other.exerciseId == this.exerciseId &&
          other.setIndex == this.setIndex &&
          other.reps == this.reps &&
          other.loadKg == this.loadKg &&
          other.rir == this.rir &&
          other.isWarmup == this.isWarmup &&
          other.completedAt == this.completedAt &&
          other.updatedAt == this.updatedAt &&
          other.status == this.status &&
          other.attempts == this.attempts &&
          other.lastError == this.lastError &&
          other.nextAttemptAt == this.nextAttemptAt);
}

class LocalSetLogsCompanion extends UpdateCompanion<LocalSetLog> {
  final Value<String> clientId;
  final Value<String> userId;
  final Value<String> workoutClientId;
  final Value<String?> planExerciseId;
  final Value<String> exerciseId;
  final Value<int> setIndex;
  final Value<int> reps;
  final Value<double> loadKg;
  final Value<int?> rir;
  final Value<bool> isWarmup;
  final Value<DateTime> completedAt;
  final Value<DateTime> updatedAt;
  final Value<SetSyncStatus> status;
  final Value<int> attempts;
  final Value<String?> lastError;
  final Value<DateTime?> nextAttemptAt;
  final Value<int> rowid;
  const LocalSetLogsCompanion({
    this.clientId = const Value.absent(),
    this.userId = const Value.absent(),
    this.workoutClientId = const Value.absent(),
    this.planExerciseId = const Value.absent(),
    this.exerciseId = const Value.absent(),
    this.setIndex = const Value.absent(),
    this.reps = const Value.absent(),
    this.loadKg = const Value.absent(),
    this.rir = const Value.absent(),
    this.isWarmup = const Value.absent(),
    this.completedAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.status = const Value.absent(),
    this.attempts = const Value.absent(),
    this.lastError = const Value.absent(),
    this.nextAttemptAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalSetLogsCompanion.insert({
    required String clientId,
    required String userId,
    required String workoutClientId,
    this.planExerciseId = const Value.absent(),
    required String exerciseId,
    required int setIndex,
    required int reps,
    required double loadKg,
    this.rir = const Value.absent(),
    this.isWarmup = const Value.absent(),
    required DateTime completedAt,
    required DateTime updatedAt,
    this.status = const Value.absent(),
    this.attempts = const Value.absent(),
    this.lastError = const Value.absent(),
    this.nextAttemptAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : clientId = Value(clientId),
       userId = Value(userId),
       workoutClientId = Value(workoutClientId),
       exerciseId = Value(exerciseId),
       setIndex = Value(setIndex),
       reps = Value(reps),
       loadKg = Value(loadKg),
       completedAt = Value(completedAt),
       updatedAt = Value(updatedAt);
  static Insertable<LocalSetLog> custom({
    Expression<String>? clientId,
    Expression<String>? userId,
    Expression<String>? workoutClientId,
    Expression<String>? planExerciseId,
    Expression<String>? exerciseId,
    Expression<int>? setIndex,
    Expression<int>? reps,
    Expression<double>? loadKg,
    Expression<int>? rir,
    Expression<bool>? isWarmup,
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
      if (workoutClientId != null) 'workout_client_id': workoutClientId,
      if (planExerciseId != null) 'plan_exercise_id': planExerciseId,
      if (exerciseId != null) 'exercise_id': exerciseId,
      if (setIndex != null) 'set_index': setIndex,
      if (reps != null) 'reps': reps,
      if (loadKg != null) 'load_kg': loadKg,
      if (rir != null) 'rir': rir,
      if (isWarmup != null) 'is_warmup': isWarmup,
      if (completedAt != null) 'completed_at': completedAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (status != null) 'status': status,
      if (attempts != null) 'attempts': attempts,
      if (lastError != null) 'last_error': lastError,
      if (nextAttemptAt != null) 'next_attempt_at': nextAttemptAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalSetLogsCompanion copyWith({
    Value<String>? clientId,
    Value<String>? userId,
    Value<String>? workoutClientId,
    Value<String?>? planExerciseId,
    Value<String>? exerciseId,
    Value<int>? setIndex,
    Value<int>? reps,
    Value<double>? loadKg,
    Value<int?>? rir,
    Value<bool>? isWarmup,
    Value<DateTime>? completedAt,
    Value<DateTime>? updatedAt,
    Value<SetSyncStatus>? status,
    Value<int>? attempts,
    Value<String?>? lastError,
    Value<DateTime?>? nextAttemptAt,
    Value<int>? rowid,
  }) {
    return LocalSetLogsCompanion(
      clientId: clientId ?? this.clientId,
      userId: userId ?? this.userId,
      workoutClientId: workoutClientId ?? this.workoutClientId,
      planExerciseId: planExerciseId ?? this.planExerciseId,
      exerciseId: exerciseId ?? this.exerciseId,
      setIndex: setIndex ?? this.setIndex,
      reps: reps ?? this.reps,
      loadKg: loadKg ?? this.loadKg,
      rir: rir ?? this.rir,
      isWarmup: isWarmup ?? this.isWarmup,
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
    if (workoutClientId.present) {
      map['workout_client_id'] = Variable<String>(workoutClientId.value);
    }
    if (planExerciseId.present) {
      map['plan_exercise_id'] = Variable<String>(planExerciseId.value);
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
    if (isWarmup.present) {
      map['is_warmup'] = Variable<bool>(isWarmup.value);
    }
    if (completedAt.present) {
      map['completed_at'] = Variable<DateTime>(completedAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(
        $LocalSetLogsTable.$converterstatus.toSql(status.value),
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
    return (StringBuffer('LocalSetLogsCompanion(')
          ..write('clientId: $clientId, ')
          ..write('userId: $userId, ')
          ..write('workoutClientId: $workoutClientId, ')
          ..write('planExerciseId: $planExerciseId, ')
          ..write('exerciseId: $exerciseId, ')
          ..write('setIndex: $setIndex, ')
          ..write('reps: $reps, ')
          ..write('loadKg: $loadKg, ')
          ..write('rir: $rir, ')
          ..write('isWarmup: $isWarmup, ')
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

class $CachedPayloadsTable extends CachedPayloads
    with TableInfo<$CachedPayloadsTable, CachedPayload> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CachedPayloadsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'user_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _cacheKeyMeta = const VerificationMeta(
    'cacheKey',
  );
  @override
  late final GeneratedColumn<String> cacheKey = GeneratedColumn<String>(
    'cache_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _jsonMeta = const VerificationMeta('json');
  @override
  late final GeneratedColumn<String> json = GeneratedColumn<String>(
    'json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
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
  @override
  List<GeneratedColumn> get $columns => [userId, cacheKey, json, savedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cached_payloads';
  @override
  VerificationContext validateIntegrity(
    Insertable<CachedPayload> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('cache_key')) {
      context.handle(
        _cacheKeyMeta,
        cacheKey.isAcceptableOrUnknown(data['cache_key']!, _cacheKeyMeta),
      );
    } else if (isInserting) {
      context.missing(_cacheKeyMeta);
    }
    if (data.containsKey('json')) {
      context.handle(
        _jsonMeta,
        json.isAcceptableOrUnknown(data['json']!, _jsonMeta),
      );
    } else if (isInserting) {
      context.missing(_jsonMeta);
    }
    if (data.containsKey('saved_at')) {
      context.handle(
        _savedAtMeta,
        savedAt.isAcceptableOrUnknown(data['saved_at']!, _savedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_savedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {userId, cacheKey};
  @override
  CachedPayload map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CachedPayload(
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      )!,
      cacheKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cache_key'],
      )!,
      json: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}json'],
      )!,
      savedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}saved_at'],
      )!,
    );
  }

  @override
  $CachedPayloadsTable createAlias(String alias) {
    return $CachedPayloadsTable(attachedDatabase, alias);
  }
}

class CachedPayload extends DataClass implements Insertable<CachedPayload> {
  final String userId;

  /// Clave lógica (`CacheKeys`).
  final String cacheKey;
  final String json;
  final DateTime savedAt;
  const CachedPayload({
    required this.userId,
    required this.cacheKey,
    required this.json,
    required this.savedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['user_id'] = Variable<String>(userId);
    map['cache_key'] = Variable<String>(cacheKey);
    map['json'] = Variable<String>(json);
    map['saved_at'] = Variable<DateTime>(savedAt);
    return map;
  }

  CachedPayloadsCompanion toCompanion(bool nullToAbsent) {
    return CachedPayloadsCompanion(
      userId: Value(userId),
      cacheKey: Value(cacheKey),
      json: Value(json),
      savedAt: Value(savedAt),
    );
  }

  factory CachedPayload.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CachedPayload(
      userId: serializer.fromJson<String>(json['userId']),
      cacheKey: serializer.fromJson<String>(json['cacheKey']),
      json: serializer.fromJson<String>(json['json']),
      savedAt: serializer.fromJson<DateTime>(json['savedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'userId': serializer.toJson<String>(userId),
      'cacheKey': serializer.toJson<String>(cacheKey),
      'json': serializer.toJson<String>(json),
      'savedAt': serializer.toJson<DateTime>(savedAt),
    };
  }

  CachedPayload copyWith({
    String? userId,
    String? cacheKey,
    String? json,
    DateTime? savedAt,
  }) => CachedPayload(
    userId: userId ?? this.userId,
    cacheKey: cacheKey ?? this.cacheKey,
    json: json ?? this.json,
    savedAt: savedAt ?? this.savedAt,
  );
  CachedPayload copyWithCompanion(CachedPayloadsCompanion data) {
    return CachedPayload(
      userId: data.userId.present ? data.userId.value : this.userId,
      cacheKey: data.cacheKey.present ? data.cacheKey.value : this.cacheKey,
      json: data.json.present ? data.json.value : this.json,
      savedAt: data.savedAt.present ? data.savedAt.value : this.savedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CachedPayload(')
          ..write('userId: $userId, ')
          ..write('cacheKey: $cacheKey, ')
          ..write('json: $json, ')
          ..write('savedAt: $savedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(userId, cacheKey, json, savedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CachedPayload &&
          other.userId == this.userId &&
          other.cacheKey == this.cacheKey &&
          other.json == this.json &&
          other.savedAt == this.savedAt);
}

class CachedPayloadsCompanion extends UpdateCompanion<CachedPayload> {
  final Value<String> userId;
  final Value<String> cacheKey;
  final Value<String> json;
  final Value<DateTime> savedAt;
  final Value<int> rowid;
  const CachedPayloadsCompanion({
    this.userId = const Value.absent(),
    this.cacheKey = const Value.absent(),
    this.json = const Value.absent(),
    this.savedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CachedPayloadsCompanion.insert({
    required String userId,
    required String cacheKey,
    required String json,
    required DateTime savedAt,
    this.rowid = const Value.absent(),
  }) : userId = Value(userId),
       cacheKey = Value(cacheKey),
       json = Value(json),
       savedAt = Value(savedAt);
  static Insertable<CachedPayload> custom({
    Expression<String>? userId,
    Expression<String>? cacheKey,
    Expression<String>? json,
    Expression<DateTime>? savedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (userId != null) 'user_id': userId,
      if (cacheKey != null) 'cache_key': cacheKey,
      if (json != null) 'json': json,
      if (savedAt != null) 'saved_at': savedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CachedPayloadsCompanion copyWith({
    Value<String>? userId,
    Value<String>? cacheKey,
    Value<String>? json,
    Value<DateTime>? savedAt,
    Value<int>? rowid,
  }) {
    return CachedPayloadsCompanion(
      userId: userId ?? this.userId,
      cacheKey: cacheKey ?? this.cacheKey,
      json: json ?? this.json,
      savedAt: savedAt ?? this.savedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (cacheKey.present) {
      map['cache_key'] = Variable<String>(cacheKey.value);
    }
    if (json.present) {
      map['json'] = Variable<String>(json.value);
    }
    if (savedAt.present) {
      map['saved_at'] = Variable<DateTime>(savedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CachedPayloadsCompanion(')
          ..write('userId: $userId, ')
          ..write('cacheKey: $cacheKey, ')
          ..write('json: $json, ')
          ..write('savedAt: $savedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PendingMutationsTable extends PendingMutations
    with TableInfo<$PendingMutationsTable, PendingMutation> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PendingMutationsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'user_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _mutationKeyMeta = const VerificationMeta(
    'mutationKey',
  );
  @override
  late final GeneratedColumn<String> mutationKey = GeneratedColumn<String>(
    'mutation_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<MutationKind, String> kind =
      GeneratedColumn<String>(
        'kind',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<MutationKind>($PendingMutationsTable.$converterkind);
  static const VerificationMeta _payloadMeta = const VerificationMeta(
    'payload',
  );
  @override
  late final GeneratedColumn<String> payload = GeneratedColumn<String>(
    'payload',
    aliasedName,
    false,
    type: DriftSqlType.string,
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
  late final GeneratedColumnWithTypeConverter<SetSyncStatus, String> status =
      GeneratedColumn<String>(
        'status',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: Constant(SetSyncStatus.pending.name),
      ).withConverter<SetSyncStatus>($PendingMutationsTable.$converterstatus);
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
    userId,
    mutationKey,
    kind,
    payload,
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
  static const String $name = 'pending_mutations';
  @override
  VerificationContext validateIntegrity(
    Insertable<PendingMutation> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('mutation_key')) {
      context.handle(
        _mutationKeyMeta,
        mutationKey.isAcceptableOrUnknown(
          data['mutation_key']!,
          _mutationKeyMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_mutationKeyMeta);
    }
    if (data.containsKey('payload')) {
      context.handle(
        _payloadMeta,
        payload.isAcceptableOrUnknown(data['payload']!, _payloadMeta),
      );
    } else if (isInserting) {
      context.missing(_payloadMeta);
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
  Set<GeneratedColumn> get $primaryKey => {userId, mutationKey};
  @override
  PendingMutation map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PendingMutation(
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      )!,
      mutationKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}mutation_key'],
      )!,
      kind: $PendingMutationsTable.$converterkind.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}kind'],
        )!,
      ),
      payload: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      status: $PendingMutationsTable.$converterstatus.fromSql(
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
  $PendingMutationsTable createAlias(String alias) {
    return $PendingMutationsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<MutationKind, String, String> $converterkind =
      const EnumNameConverter<MutationKind>(MutationKind.values);
  static JsonTypeConverter2<SetSyncStatus, String, String> $converterstatus =
      const EnumNameConverter<SetSyncStatus>(SetSyncStatus.values);
}

class PendingMutation extends DataClass implements Insertable<PendingMutation> {
  final String userId;

  /// Clave lógica: `note:<exerciseId>` o `measurement:<YYYY-MM-DD>`.
  final String mutationKey;
  final MutationKind kind;

  /// Cuerpo de la petición (JSON) o datos para construirla.
  final String payload;

  /// Momento de la edición local (para la nota: `clientUpdatedAt`).
  final DateTime updatedAt;

  /// `pending`, `syncing` o `failed` (al confirmarse la fila se borra).
  final SetSyncStatus status;
  final int attempts;
  final String? lastError;
  final DateTime? nextAttemptAt;
  const PendingMutation({
    required this.userId,
    required this.mutationKey,
    required this.kind,
    required this.payload,
    required this.updatedAt,
    required this.status,
    required this.attempts,
    this.lastError,
    this.nextAttemptAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['user_id'] = Variable<String>(userId);
    map['mutation_key'] = Variable<String>(mutationKey);
    {
      map['kind'] = Variable<String>(
        $PendingMutationsTable.$converterkind.toSql(kind),
      );
    }
    map['payload'] = Variable<String>(payload);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    {
      map['status'] = Variable<String>(
        $PendingMutationsTable.$converterstatus.toSql(status),
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

  PendingMutationsCompanion toCompanion(bool nullToAbsent) {
    return PendingMutationsCompanion(
      userId: Value(userId),
      mutationKey: Value(mutationKey),
      kind: Value(kind),
      payload: Value(payload),
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

  factory PendingMutation.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PendingMutation(
      userId: serializer.fromJson<String>(json['userId']),
      mutationKey: serializer.fromJson<String>(json['mutationKey']),
      kind: $PendingMutationsTable.$converterkind.fromJson(
        serializer.fromJson<String>(json['kind']),
      ),
      payload: serializer.fromJson<String>(json['payload']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      status: $PendingMutationsTable.$converterstatus.fromJson(
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
      'userId': serializer.toJson<String>(userId),
      'mutationKey': serializer.toJson<String>(mutationKey),
      'kind': serializer.toJson<String>(
        $PendingMutationsTable.$converterkind.toJson(kind),
      ),
      'payload': serializer.toJson<String>(payload),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'status': serializer.toJson<String>(
        $PendingMutationsTable.$converterstatus.toJson(status),
      ),
      'attempts': serializer.toJson<int>(attempts),
      'lastError': serializer.toJson<String?>(lastError),
      'nextAttemptAt': serializer.toJson<DateTime?>(nextAttemptAt),
    };
  }

  PendingMutation copyWith({
    String? userId,
    String? mutationKey,
    MutationKind? kind,
    String? payload,
    DateTime? updatedAt,
    SetSyncStatus? status,
    int? attempts,
    Value<String?> lastError = const Value.absent(),
    Value<DateTime?> nextAttemptAt = const Value.absent(),
  }) => PendingMutation(
    userId: userId ?? this.userId,
    mutationKey: mutationKey ?? this.mutationKey,
    kind: kind ?? this.kind,
    payload: payload ?? this.payload,
    updatedAt: updatedAt ?? this.updatedAt,
    status: status ?? this.status,
    attempts: attempts ?? this.attempts,
    lastError: lastError.present ? lastError.value : this.lastError,
    nextAttemptAt: nextAttemptAt.present
        ? nextAttemptAt.value
        : this.nextAttemptAt,
  );
  PendingMutation copyWithCompanion(PendingMutationsCompanion data) {
    return PendingMutation(
      userId: data.userId.present ? data.userId.value : this.userId,
      mutationKey: data.mutationKey.present
          ? data.mutationKey.value
          : this.mutationKey,
      kind: data.kind.present ? data.kind.value : this.kind,
      payload: data.payload.present ? data.payload.value : this.payload,
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
    return (StringBuffer('PendingMutation(')
          ..write('userId: $userId, ')
          ..write('mutationKey: $mutationKey, ')
          ..write('kind: $kind, ')
          ..write('payload: $payload, ')
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
    userId,
    mutationKey,
    kind,
    payload,
    updatedAt,
    status,
    attempts,
    lastError,
    nextAttemptAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PendingMutation &&
          other.userId == this.userId &&
          other.mutationKey == this.mutationKey &&
          other.kind == this.kind &&
          other.payload == this.payload &&
          other.updatedAt == this.updatedAt &&
          other.status == this.status &&
          other.attempts == this.attempts &&
          other.lastError == this.lastError &&
          other.nextAttemptAt == this.nextAttemptAt);
}

class PendingMutationsCompanion extends UpdateCompanion<PendingMutation> {
  final Value<String> userId;
  final Value<String> mutationKey;
  final Value<MutationKind> kind;
  final Value<String> payload;
  final Value<DateTime> updatedAt;
  final Value<SetSyncStatus> status;
  final Value<int> attempts;
  final Value<String?> lastError;
  final Value<DateTime?> nextAttemptAt;
  final Value<int> rowid;
  const PendingMutationsCompanion({
    this.userId = const Value.absent(),
    this.mutationKey = const Value.absent(),
    this.kind = const Value.absent(),
    this.payload = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.status = const Value.absent(),
    this.attempts = const Value.absent(),
    this.lastError = const Value.absent(),
    this.nextAttemptAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PendingMutationsCompanion.insert({
    required String userId,
    required String mutationKey,
    required MutationKind kind,
    required String payload,
    required DateTime updatedAt,
    this.status = const Value.absent(),
    this.attempts = const Value.absent(),
    this.lastError = const Value.absent(),
    this.nextAttemptAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : userId = Value(userId),
       mutationKey = Value(mutationKey),
       kind = Value(kind),
       payload = Value(payload),
       updatedAt = Value(updatedAt);
  static Insertable<PendingMutation> custom({
    Expression<String>? userId,
    Expression<String>? mutationKey,
    Expression<String>? kind,
    Expression<String>? payload,
    Expression<DateTime>? updatedAt,
    Expression<String>? status,
    Expression<int>? attempts,
    Expression<String>? lastError,
    Expression<DateTime>? nextAttemptAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (userId != null) 'user_id': userId,
      if (mutationKey != null) 'mutation_key': mutationKey,
      if (kind != null) 'kind': kind,
      if (payload != null) 'payload': payload,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (status != null) 'status': status,
      if (attempts != null) 'attempts': attempts,
      if (lastError != null) 'last_error': lastError,
      if (nextAttemptAt != null) 'next_attempt_at': nextAttemptAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PendingMutationsCompanion copyWith({
    Value<String>? userId,
    Value<String>? mutationKey,
    Value<MutationKind>? kind,
    Value<String>? payload,
    Value<DateTime>? updatedAt,
    Value<SetSyncStatus>? status,
    Value<int>? attempts,
    Value<String?>? lastError,
    Value<DateTime?>? nextAttemptAt,
    Value<int>? rowid,
  }) {
    return PendingMutationsCompanion(
      userId: userId ?? this.userId,
      mutationKey: mutationKey ?? this.mutationKey,
      kind: kind ?? this.kind,
      payload: payload ?? this.payload,
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
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (mutationKey.present) {
      map['mutation_key'] = Variable<String>(mutationKey.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(
        $PendingMutationsTable.$converterkind.toSql(kind.value),
      );
    }
    if (payload.present) {
      map['payload'] = Variable<String>(payload.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(
        $PendingMutationsTable.$converterstatus.toSql(status.value),
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
    return (StringBuffer('PendingMutationsCompanion(')
          ..write('userId: $userId, ')
          ..write('mutationKey: $mutationKey, ')
          ..write('kind: $kind, ')
          ..write('payload: $payload, ')
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
  late final $LocalWorkoutsTable localWorkouts = $LocalWorkoutsTable(this);
  late final $LocalSetLogsTable localSetLogs = $LocalSetLogsTable(this);
  late final $CachedPayloadsTable cachedPayloads = $CachedPayloadsTable(this);
  late final $PendingMutationsTable pendingMutations = $PendingMutationsTable(
    this,
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    localWorkouts,
    localSetLogs,
    cachedPayloads,
    pendingMutations,
  ];
}

typedef $$LocalWorkoutsTableCreateCompanionBuilder =
    LocalWorkoutsCompanion Function({
      required String clientId,
      required String userId,
      required String planSessionId,
      Value<String?> serverId,
      required DateTime startedAt,
      Value<DateTime?> finishedAt,
      Value<bool> finishSynced,
      Value<int> attempts,
      Value<String?> lastError,
      Value<DateTime?> nextAttemptAt,
      Value<String?> adjustmentJson,
      Value<int> rowid,
    });
typedef $$LocalWorkoutsTableUpdateCompanionBuilder =
    LocalWorkoutsCompanion Function({
      Value<String> clientId,
      Value<String> userId,
      Value<String> planSessionId,
      Value<String?> serverId,
      Value<DateTime> startedAt,
      Value<DateTime?> finishedAt,
      Value<bool> finishSynced,
      Value<int> attempts,
      Value<String?> lastError,
      Value<DateTime?> nextAttemptAt,
      Value<String?> adjustmentJson,
      Value<int> rowid,
    });

class $$LocalWorkoutsTableFilterComposer
    extends Composer<_$AppDatabase, $LocalWorkoutsTable> {
  $$LocalWorkoutsTableFilterComposer({
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

  ColumnFilters<String> get planSessionId => $composableBuilder(
    column: $table.planSessionId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get serverId => $composableBuilder(
    column: $table.serverId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get finishedAt => $composableBuilder(
    column: $table.finishedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get finishSynced => $composableBuilder(
    column: $table.finishSynced,
    builder: (column) => ColumnFilters(column),
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

  ColumnFilters<String> get adjustmentJson => $composableBuilder(
    column: $table.adjustmentJson,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LocalWorkoutsTableOrderingComposer
    extends Composer<_$AppDatabase, $LocalWorkoutsTable> {
  $$LocalWorkoutsTableOrderingComposer({
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

  ColumnOrderings<String> get planSessionId => $composableBuilder(
    column: $table.planSessionId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get serverId => $composableBuilder(
    column: $table.serverId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get finishedAt => $composableBuilder(
    column: $table.finishedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get finishSynced => $composableBuilder(
    column: $table.finishSynced,
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

  ColumnOrderings<String> get adjustmentJson => $composableBuilder(
    column: $table.adjustmentJson,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LocalWorkoutsTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocalWorkoutsTable> {
  $$LocalWorkoutsTableAnnotationComposer({
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

  GeneratedColumn<String> get planSessionId => $composableBuilder(
    column: $table.planSessionId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get serverId =>
      $composableBuilder(column: $table.serverId, builder: (column) => column);

  GeneratedColumn<DateTime> get startedAt =>
      $composableBuilder(column: $table.startedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get finishedAt => $composableBuilder(
    column: $table.finishedAt,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get finishSynced => $composableBuilder(
    column: $table.finishSynced,
    builder: (column) => column,
  );

  GeneratedColumn<int> get attempts =>
      $composableBuilder(column: $table.attempts, builder: (column) => column);

  GeneratedColumn<String> get lastError =>
      $composableBuilder(column: $table.lastError, builder: (column) => column);

  GeneratedColumn<DateTime> get nextAttemptAt => $composableBuilder(
    column: $table.nextAttemptAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get adjustmentJson => $composableBuilder(
    column: $table.adjustmentJson,
    builder: (column) => column,
  );
}

class $$LocalWorkoutsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LocalWorkoutsTable,
          LocalWorkout,
          $$LocalWorkoutsTableFilterComposer,
          $$LocalWorkoutsTableOrderingComposer,
          $$LocalWorkoutsTableAnnotationComposer,
          $$LocalWorkoutsTableCreateCompanionBuilder,
          $$LocalWorkoutsTableUpdateCompanionBuilder,
          (
            LocalWorkout,
            BaseReferences<_$AppDatabase, $LocalWorkoutsTable, LocalWorkout>,
          ),
          LocalWorkout,
          PrefetchHooks Function()
        > {
  $$LocalWorkoutsTableTableManager(_$AppDatabase db, $LocalWorkoutsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalWorkoutsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalWorkoutsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocalWorkoutsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> clientId = const Value.absent(),
                Value<String> userId = const Value.absent(),
                Value<String> planSessionId = const Value.absent(),
                Value<String?> serverId = const Value.absent(),
                Value<DateTime> startedAt = const Value.absent(),
                Value<DateTime?> finishedAt = const Value.absent(),
                Value<bool> finishSynced = const Value.absent(),
                Value<int> attempts = const Value.absent(),
                Value<String?> lastError = const Value.absent(),
                Value<DateTime?> nextAttemptAt = const Value.absent(),
                Value<String?> adjustmentJson = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalWorkoutsCompanion(
                clientId: clientId,
                userId: userId,
                planSessionId: planSessionId,
                serverId: serverId,
                startedAt: startedAt,
                finishedAt: finishedAt,
                finishSynced: finishSynced,
                attempts: attempts,
                lastError: lastError,
                nextAttemptAt: nextAttemptAt,
                adjustmentJson: adjustmentJson,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String clientId,
                required String userId,
                required String planSessionId,
                Value<String?> serverId = const Value.absent(),
                required DateTime startedAt,
                Value<DateTime?> finishedAt = const Value.absent(),
                Value<bool> finishSynced = const Value.absent(),
                Value<int> attempts = const Value.absent(),
                Value<String?> lastError = const Value.absent(),
                Value<DateTime?> nextAttemptAt = const Value.absent(),
                Value<String?> adjustmentJson = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalWorkoutsCompanion.insert(
                clientId: clientId,
                userId: userId,
                planSessionId: planSessionId,
                serverId: serverId,
                startedAt: startedAt,
                finishedAt: finishedAt,
                finishSynced: finishSynced,
                attempts: attempts,
                lastError: lastError,
                nextAttemptAt: nextAttemptAt,
                adjustmentJson: adjustmentJson,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LocalWorkoutsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LocalWorkoutsTable,
      LocalWorkout,
      $$LocalWorkoutsTableFilterComposer,
      $$LocalWorkoutsTableOrderingComposer,
      $$LocalWorkoutsTableAnnotationComposer,
      $$LocalWorkoutsTableCreateCompanionBuilder,
      $$LocalWorkoutsTableUpdateCompanionBuilder,
      (
        LocalWorkout,
        BaseReferences<_$AppDatabase, $LocalWorkoutsTable, LocalWorkout>,
      ),
      LocalWorkout,
      PrefetchHooks Function()
    >;
typedef $$LocalSetLogsTableCreateCompanionBuilder =
    LocalSetLogsCompanion Function({
      required String clientId,
      required String userId,
      required String workoutClientId,
      Value<String?> planExerciseId,
      required String exerciseId,
      required int setIndex,
      required int reps,
      required double loadKg,
      Value<int?> rir,
      Value<bool> isWarmup,
      required DateTime completedAt,
      required DateTime updatedAt,
      Value<SetSyncStatus> status,
      Value<int> attempts,
      Value<String?> lastError,
      Value<DateTime?> nextAttemptAt,
      Value<int> rowid,
    });
typedef $$LocalSetLogsTableUpdateCompanionBuilder =
    LocalSetLogsCompanion Function({
      Value<String> clientId,
      Value<String> userId,
      Value<String> workoutClientId,
      Value<String?> planExerciseId,
      Value<String> exerciseId,
      Value<int> setIndex,
      Value<int> reps,
      Value<double> loadKg,
      Value<int?> rir,
      Value<bool> isWarmup,
      Value<DateTime> completedAt,
      Value<DateTime> updatedAt,
      Value<SetSyncStatus> status,
      Value<int> attempts,
      Value<String?> lastError,
      Value<DateTime?> nextAttemptAt,
      Value<int> rowid,
    });

class $$LocalSetLogsTableFilterComposer
    extends Composer<_$AppDatabase, $LocalSetLogsTable> {
  $$LocalSetLogsTableFilterComposer({
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

  ColumnFilters<String> get workoutClientId => $composableBuilder(
    column: $table.workoutClientId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get planExerciseId => $composableBuilder(
    column: $table.planExerciseId,
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

  ColumnFilters<bool> get isWarmup => $composableBuilder(
    column: $table.isWarmup,
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

  ColumnWithTypeConverterFilters<SetSyncStatus, SetSyncStatus, String>
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

class $$LocalSetLogsTableOrderingComposer
    extends Composer<_$AppDatabase, $LocalSetLogsTable> {
  $$LocalSetLogsTableOrderingComposer({
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

  ColumnOrderings<String> get workoutClientId => $composableBuilder(
    column: $table.workoutClientId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get planExerciseId => $composableBuilder(
    column: $table.planExerciseId,
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

  ColumnOrderings<bool> get isWarmup => $composableBuilder(
    column: $table.isWarmup,
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

class $$LocalSetLogsTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocalSetLogsTable> {
  $$LocalSetLogsTableAnnotationComposer({
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

  GeneratedColumn<String> get workoutClientId => $composableBuilder(
    column: $table.workoutClientId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get planExerciseId => $composableBuilder(
    column: $table.planExerciseId,
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

  GeneratedColumn<bool> get isWarmup =>
      $composableBuilder(column: $table.isWarmup, builder: (column) => column);

  GeneratedColumn<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumnWithTypeConverter<SetSyncStatus, String> get status =>
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

class $$LocalSetLogsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LocalSetLogsTable,
          LocalSetLog,
          $$LocalSetLogsTableFilterComposer,
          $$LocalSetLogsTableOrderingComposer,
          $$LocalSetLogsTableAnnotationComposer,
          $$LocalSetLogsTableCreateCompanionBuilder,
          $$LocalSetLogsTableUpdateCompanionBuilder,
          (
            LocalSetLog,
            BaseReferences<_$AppDatabase, $LocalSetLogsTable, LocalSetLog>,
          ),
          LocalSetLog,
          PrefetchHooks Function()
        > {
  $$LocalSetLogsTableTableManager(_$AppDatabase db, $LocalSetLogsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalSetLogsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalSetLogsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocalSetLogsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> clientId = const Value.absent(),
                Value<String> userId = const Value.absent(),
                Value<String> workoutClientId = const Value.absent(),
                Value<String?> planExerciseId = const Value.absent(),
                Value<String> exerciseId = const Value.absent(),
                Value<int> setIndex = const Value.absent(),
                Value<int> reps = const Value.absent(),
                Value<double> loadKg = const Value.absent(),
                Value<int?> rir = const Value.absent(),
                Value<bool> isWarmup = const Value.absent(),
                Value<DateTime> completedAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<SetSyncStatus> status = const Value.absent(),
                Value<int> attempts = const Value.absent(),
                Value<String?> lastError = const Value.absent(),
                Value<DateTime?> nextAttemptAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalSetLogsCompanion(
                clientId: clientId,
                userId: userId,
                workoutClientId: workoutClientId,
                planExerciseId: planExerciseId,
                exerciseId: exerciseId,
                setIndex: setIndex,
                reps: reps,
                loadKg: loadKg,
                rir: rir,
                isWarmup: isWarmup,
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
                required String workoutClientId,
                Value<String?> planExerciseId = const Value.absent(),
                required String exerciseId,
                required int setIndex,
                required int reps,
                required double loadKg,
                Value<int?> rir = const Value.absent(),
                Value<bool> isWarmup = const Value.absent(),
                required DateTime completedAt,
                required DateTime updatedAt,
                Value<SetSyncStatus> status = const Value.absent(),
                Value<int> attempts = const Value.absent(),
                Value<String?> lastError = const Value.absent(),
                Value<DateTime?> nextAttemptAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalSetLogsCompanion.insert(
                clientId: clientId,
                userId: userId,
                workoutClientId: workoutClientId,
                planExerciseId: planExerciseId,
                exerciseId: exerciseId,
                setIndex: setIndex,
                reps: reps,
                loadKg: loadKg,
                rir: rir,
                isWarmup: isWarmup,
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

typedef $$LocalSetLogsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LocalSetLogsTable,
      LocalSetLog,
      $$LocalSetLogsTableFilterComposer,
      $$LocalSetLogsTableOrderingComposer,
      $$LocalSetLogsTableAnnotationComposer,
      $$LocalSetLogsTableCreateCompanionBuilder,
      $$LocalSetLogsTableUpdateCompanionBuilder,
      (
        LocalSetLog,
        BaseReferences<_$AppDatabase, $LocalSetLogsTable, LocalSetLog>,
      ),
      LocalSetLog,
      PrefetchHooks Function()
    >;
typedef $$CachedPayloadsTableCreateCompanionBuilder =
    CachedPayloadsCompanion Function({
      required String userId,
      required String cacheKey,
      required String json,
      required DateTime savedAt,
      Value<int> rowid,
    });
typedef $$CachedPayloadsTableUpdateCompanionBuilder =
    CachedPayloadsCompanion Function({
      Value<String> userId,
      Value<String> cacheKey,
      Value<String> json,
      Value<DateTime> savedAt,
      Value<int> rowid,
    });

class $$CachedPayloadsTableFilterComposer
    extends Composer<_$AppDatabase, $CachedPayloadsTable> {
  $$CachedPayloadsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get cacheKey => $composableBuilder(
    column: $table.cacheKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get json => $composableBuilder(
    column: $table.json,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get savedAt => $composableBuilder(
    column: $table.savedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CachedPayloadsTableOrderingComposer
    extends Composer<_$AppDatabase, $CachedPayloadsTable> {
  $$CachedPayloadsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get cacheKey => $composableBuilder(
    column: $table.cacheKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get json => $composableBuilder(
    column: $table.json,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get savedAt => $composableBuilder(
    column: $table.savedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CachedPayloadsTableAnnotationComposer
    extends Composer<_$AppDatabase, $CachedPayloadsTable> {
  $$CachedPayloadsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get cacheKey =>
      $composableBuilder(column: $table.cacheKey, builder: (column) => column);

  GeneratedColumn<String> get json =>
      $composableBuilder(column: $table.json, builder: (column) => column);

  GeneratedColumn<DateTime> get savedAt =>
      $composableBuilder(column: $table.savedAt, builder: (column) => column);
}

class $$CachedPayloadsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CachedPayloadsTable,
          CachedPayload,
          $$CachedPayloadsTableFilterComposer,
          $$CachedPayloadsTableOrderingComposer,
          $$CachedPayloadsTableAnnotationComposer,
          $$CachedPayloadsTableCreateCompanionBuilder,
          $$CachedPayloadsTableUpdateCompanionBuilder,
          (
            CachedPayload,
            BaseReferences<_$AppDatabase, $CachedPayloadsTable, CachedPayload>,
          ),
          CachedPayload,
          PrefetchHooks Function()
        > {
  $$CachedPayloadsTableTableManager(
    _$AppDatabase db,
    $CachedPayloadsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CachedPayloadsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CachedPayloadsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CachedPayloadsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> userId = const Value.absent(),
                Value<String> cacheKey = const Value.absent(),
                Value<String> json = const Value.absent(),
                Value<DateTime> savedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CachedPayloadsCompanion(
                userId: userId,
                cacheKey: cacheKey,
                json: json,
                savedAt: savedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String userId,
                required String cacheKey,
                required String json,
                required DateTime savedAt,
                Value<int> rowid = const Value.absent(),
              }) => CachedPayloadsCompanion.insert(
                userId: userId,
                cacheKey: cacheKey,
                json: json,
                savedAt: savedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CachedPayloadsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CachedPayloadsTable,
      CachedPayload,
      $$CachedPayloadsTableFilterComposer,
      $$CachedPayloadsTableOrderingComposer,
      $$CachedPayloadsTableAnnotationComposer,
      $$CachedPayloadsTableCreateCompanionBuilder,
      $$CachedPayloadsTableUpdateCompanionBuilder,
      (
        CachedPayload,
        BaseReferences<_$AppDatabase, $CachedPayloadsTable, CachedPayload>,
      ),
      CachedPayload,
      PrefetchHooks Function()
    >;
typedef $$PendingMutationsTableCreateCompanionBuilder =
    PendingMutationsCompanion Function({
      required String userId,
      required String mutationKey,
      required MutationKind kind,
      required String payload,
      required DateTime updatedAt,
      Value<SetSyncStatus> status,
      Value<int> attempts,
      Value<String?> lastError,
      Value<DateTime?> nextAttemptAt,
      Value<int> rowid,
    });
typedef $$PendingMutationsTableUpdateCompanionBuilder =
    PendingMutationsCompanion Function({
      Value<String> userId,
      Value<String> mutationKey,
      Value<MutationKind> kind,
      Value<String> payload,
      Value<DateTime> updatedAt,
      Value<SetSyncStatus> status,
      Value<int> attempts,
      Value<String?> lastError,
      Value<DateTime?> nextAttemptAt,
      Value<int> rowid,
    });

class $$PendingMutationsTableFilterComposer
    extends Composer<_$AppDatabase, $PendingMutationsTable> {
  $$PendingMutationsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get mutationKey => $composableBuilder(
    column: $table.mutationKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<MutationKind, MutationKind, String> get kind =>
      $composableBuilder(
        column: $table.kind,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<SetSyncStatus, SetSyncStatus, String>
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

class $$PendingMutationsTableOrderingComposer
    extends Composer<_$AppDatabase, $PendingMutationsTable> {
  $$PendingMutationsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get mutationKey => $composableBuilder(
    column: $table.mutationKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payload => $composableBuilder(
    column: $table.payload,
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

class $$PendingMutationsTableAnnotationComposer
    extends Composer<_$AppDatabase, $PendingMutationsTable> {
  $$PendingMutationsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get mutationKey => $composableBuilder(
    column: $table.mutationKey,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<MutationKind, String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<String> get payload =>
      $composableBuilder(column: $table.payload, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumnWithTypeConverter<SetSyncStatus, String> get status =>
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

class $$PendingMutationsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PendingMutationsTable,
          PendingMutation,
          $$PendingMutationsTableFilterComposer,
          $$PendingMutationsTableOrderingComposer,
          $$PendingMutationsTableAnnotationComposer,
          $$PendingMutationsTableCreateCompanionBuilder,
          $$PendingMutationsTableUpdateCompanionBuilder,
          (
            PendingMutation,
            BaseReferences<
              _$AppDatabase,
              $PendingMutationsTable,
              PendingMutation
            >,
          ),
          PendingMutation,
          PrefetchHooks Function()
        > {
  $$PendingMutationsTableTableManager(
    _$AppDatabase db,
    $PendingMutationsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PendingMutationsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PendingMutationsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PendingMutationsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> userId = const Value.absent(),
                Value<String> mutationKey = const Value.absent(),
                Value<MutationKind> kind = const Value.absent(),
                Value<String> payload = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<SetSyncStatus> status = const Value.absent(),
                Value<int> attempts = const Value.absent(),
                Value<String?> lastError = const Value.absent(),
                Value<DateTime?> nextAttemptAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PendingMutationsCompanion(
                userId: userId,
                mutationKey: mutationKey,
                kind: kind,
                payload: payload,
                updatedAt: updatedAt,
                status: status,
                attempts: attempts,
                lastError: lastError,
                nextAttemptAt: nextAttemptAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String userId,
                required String mutationKey,
                required MutationKind kind,
                required String payload,
                required DateTime updatedAt,
                Value<SetSyncStatus> status = const Value.absent(),
                Value<int> attempts = const Value.absent(),
                Value<String?> lastError = const Value.absent(),
                Value<DateTime?> nextAttemptAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PendingMutationsCompanion.insert(
                userId: userId,
                mutationKey: mutationKey,
                kind: kind,
                payload: payload,
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

typedef $$PendingMutationsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PendingMutationsTable,
      PendingMutation,
      $$PendingMutationsTableFilterComposer,
      $$PendingMutationsTableOrderingComposer,
      $$PendingMutationsTableAnnotationComposer,
      $$PendingMutationsTableCreateCompanionBuilder,
      $$PendingMutationsTableUpdateCompanionBuilder,
      (
        PendingMutation,
        BaseReferences<_$AppDatabase, $PendingMutationsTable, PendingMutation>,
      ),
      PendingMutation,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$LocalWorkoutsTableTableManager get localWorkouts =>
      $$LocalWorkoutsTableTableManager(_db, _db.localWorkouts);
  $$LocalSetLogsTableTableManager get localSetLogs =>
      $$LocalSetLogsTableTableManager(_db, _db.localSetLogs);
  $$CachedPayloadsTableTableManager get cachedPayloads =>
      $$CachedPayloadsTableTableManager(_db, _db.cachedPayloads);
  $$PendingMutationsTableTableManager get pendingMutations =>
      $$PendingMutationsTableTableManager(_db, _db.pendingMutations);
}
