// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $TelemetryRowsTable extends TelemetryRows
    with TableInfo<$TelemetryRowsTable, TelemetryRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TelemetryRowsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _tsMeta = const VerificationMeta('ts');
  @override
  late final GeneratedColumn<int> ts = GeneratedColumn<int>(
    'ts',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _rpmMeta = const VerificationMeta('rpm');
  @override
  late final GeneratedColumn<double> rpm = GeneratedColumn<double>(
    'rpm',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _temperatureMeta = const VerificationMeta(
    'temperature',
  );
  @override
  late final GeneratedColumn<double> temperature = GeneratedColumn<double>(
    'temperature',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _vibrationMeta = const VerificationMeta(
    'vibration',
  );
  @override
  late final GeneratedColumn<double> vibration = GeneratedColumn<double>(
    'vibration',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _currentMeta = const VerificationMeta(
    'current',
  );
  @override
  late final GeneratedColumn<double> current = GeneratedColumn<double>(
    'current',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _healthMeta = const VerificationMeta('health');
  @override
  late final GeneratedColumn<double> health = GeneratedColumn<double>(
    'health',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _faultMeta = const VerificationMeta('fault');
  @override
  late final GeneratedColumn<String> fault = GeneratedColumn<String>(
    'fault',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _levelMeta = const VerificationMeta('level');
  @override
  late final GeneratedColumn<int> level = GeneratedColumn<int>(
    'level',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _buzzerOnMeta = const VerificationMeta(
    'buzzerOn',
  );
  @override
  late final GeneratedColumn<bool> buzzerOn = GeneratedColumn<bool>(
    'buzzer_on',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("buzzer_on" IN (0, 1))',
    ),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    ts,
    rpm,
    temperature,
    vibration,
    current,
    health,
    fault,
    level,
    buzzerOn,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'telemetry';
  @override
  VerificationContext validateIntegrity(
    Insertable<TelemetryRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('ts')) {
      context.handle(_tsMeta, ts.isAcceptableOrUnknown(data['ts']!, _tsMeta));
    } else if (isInserting) {
      context.missing(_tsMeta);
    }
    if (data.containsKey('rpm')) {
      context.handle(
        _rpmMeta,
        rpm.isAcceptableOrUnknown(data['rpm']!, _rpmMeta),
      );
    } else if (isInserting) {
      context.missing(_rpmMeta);
    }
    if (data.containsKey('temperature')) {
      context.handle(
        _temperatureMeta,
        temperature.isAcceptableOrUnknown(
          data['temperature']!,
          _temperatureMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_temperatureMeta);
    }
    if (data.containsKey('vibration')) {
      context.handle(
        _vibrationMeta,
        vibration.isAcceptableOrUnknown(data['vibration']!, _vibrationMeta),
      );
    }
    if (data.containsKey('current')) {
      context.handle(
        _currentMeta,
        current.isAcceptableOrUnknown(data['current']!, _currentMeta),
      );
    }
    if (data.containsKey('health')) {
      context.handle(
        _healthMeta,
        health.isAcceptableOrUnknown(data['health']!, _healthMeta),
      );
    }
    if (data.containsKey('fault')) {
      context.handle(
        _faultMeta,
        fault.isAcceptableOrUnknown(data['fault']!, _faultMeta),
      );
    }
    if (data.containsKey('level')) {
      context.handle(
        _levelMeta,
        level.isAcceptableOrUnknown(data['level']!, _levelMeta),
      );
    } else if (isInserting) {
      context.missing(_levelMeta);
    }
    if (data.containsKey('buzzer_on')) {
      context.handle(
        _buzzerOnMeta,
        buzzerOn.isAcceptableOrUnknown(data['buzzer_on']!, _buzzerOnMeta),
      );
    } else if (isInserting) {
      context.missing(_buzzerOnMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TelemetryRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TelemetryRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      ts: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}ts'],
      )!,
      rpm: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}rpm'],
      )!,
      temperature: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}temperature'],
      )!,
      vibration: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}vibration'],
      ),
      current: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}current'],
      ),
      health: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}health'],
      ),
      fault: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}fault'],
      ),
      level: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}level'],
      )!,
      buzzerOn: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}buzzer_on'],
      )!,
    );
  }

  @override
  $TelemetryRowsTable createAlias(String alias) {
    return $TelemetryRowsTable(attachedDatabase, alias);
  }
}

class TelemetryRow extends DataClass implements Insertable<TelemetryRow> {
  final int id;

  /// Thời điểm đo, epoch millisecond.
  final int ts;
  final double rpm;
  final double temperature;
  final double? vibration;
  final double? current;
  final double? health;
  final String? fault;

  /// WarningLevel.index (0 ok, 1 warn, 2 danger).
  final int level;
  final bool buzzerOn;
  const TelemetryRow({
    required this.id,
    required this.ts,
    required this.rpm,
    required this.temperature,
    this.vibration,
    this.current,
    this.health,
    this.fault,
    required this.level,
    required this.buzzerOn,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['ts'] = Variable<int>(ts);
    map['rpm'] = Variable<double>(rpm);
    map['temperature'] = Variable<double>(temperature);
    if (!nullToAbsent || vibration != null) {
      map['vibration'] = Variable<double>(vibration);
    }
    if (!nullToAbsent || current != null) {
      map['current'] = Variable<double>(current);
    }
    if (!nullToAbsent || health != null) {
      map['health'] = Variable<double>(health);
    }
    if (!nullToAbsent || fault != null) {
      map['fault'] = Variable<String>(fault);
    }
    map['level'] = Variable<int>(level);
    map['buzzer_on'] = Variable<bool>(buzzerOn);
    return map;
  }

  TelemetryRowsCompanion toCompanion(bool nullToAbsent) {
    return TelemetryRowsCompanion(
      id: Value(id),
      ts: Value(ts),
      rpm: Value(rpm),
      temperature: Value(temperature),
      vibration: vibration == null && nullToAbsent
          ? const Value.absent()
          : Value(vibration),
      current: current == null && nullToAbsent
          ? const Value.absent()
          : Value(current),
      health: health == null && nullToAbsent
          ? const Value.absent()
          : Value(health),
      fault: fault == null && nullToAbsent
          ? const Value.absent()
          : Value(fault),
      level: Value(level),
      buzzerOn: Value(buzzerOn),
    );
  }

  factory TelemetryRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TelemetryRow(
      id: serializer.fromJson<int>(json['id']),
      ts: serializer.fromJson<int>(json['ts']),
      rpm: serializer.fromJson<double>(json['rpm']),
      temperature: serializer.fromJson<double>(json['temperature']),
      vibration: serializer.fromJson<double?>(json['vibration']),
      current: serializer.fromJson<double?>(json['current']),
      health: serializer.fromJson<double?>(json['health']),
      fault: serializer.fromJson<String?>(json['fault']),
      level: serializer.fromJson<int>(json['level']),
      buzzerOn: serializer.fromJson<bool>(json['buzzerOn']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'ts': serializer.toJson<int>(ts),
      'rpm': serializer.toJson<double>(rpm),
      'temperature': serializer.toJson<double>(temperature),
      'vibration': serializer.toJson<double?>(vibration),
      'current': serializer.toJson<double?>(current),
      'health': serializer.toJson<double?>(health),
      'fault': serializer.toJson<String?>(fault),
      'level': serializer.toJson<int>(level),
      'buzzerOn': serializer.toJson<bool>(buzzerOn),
    };
  }

  TelemetryRow copyWith({
    int? id,
    int? ts,
    double? rpm,
    double? temperature,
    Value<double?> vibration = const Value.absent(),
    Value<double?> current = const Value.absent(),
    Value<double?> health = const Value.absent(),
    Value<String?> fault = const Value.absent(),
    int? level,
    bool? buzzerOn,
  }) => TelemetryRow(
    id: id ?? this.id,
    ts: ts ?? this.ts,
    rpm: rpm ?? this.rpm,
    temperature: temperature ?? this.temperature,
    vibration: vibration.present ? vibration.value : this.vibration,
    current: current.present ? current.value : this.current,
    health: health.present ? health.value : this.health,
    fault: fault.present ? fault.value : this.fault,
    level: level ?? this.level,
    buzzerOn: buzzerOn ?? this.buzzerOn,
  );
  TelemetryRow copyWithCompanion(TelemetryRowsCompanion data) {
    return TelemetryRow(
      id: data.id.present ? data.id.value : this.id,
      ts: data.ts.present ? data.ts.value : this.ts,
      rpm: data.rpm.present ? data.rpm.value : this.rpm,
      temperature: data.temperature.present
          ? data.temperature.value
          : this.temperature,
      vibration: data.vibration.present ? data.vibration.value : this.vibration,
      current: data.current.present ? data.current.value : this.current,
      health: data.health.present ? data.health.value : this.health,
      fault: data.fault.present ? data.fault.value : this.fault,
      level: data.level.present ? data.level.value : this.level,
      buzzerOn: data.buzzerOn.present ? data.buzzerOn.value : this.buzzerOn,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TelemetryRow(')
          ..write('id: $id, ')
          ..write('ts: $ts, ')
          ..write('rpm: $rpm, ')
          ..write('temperature: $temperature, ')
          ..write('vibration: $vibration, ')
          ..write('current: $current, ')
          ..write('health: $health, ')
          ..write('fault: $fault, ')
          ..write('level: $level, ')
          ..write('buzzerOn: $buzzerOn')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    ts,
    rpm,
    temperature,
    vibration,
    current,
    health,
    fault,
    level,
    buzzerOn,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TelemetryRow &&
          other.id == this.id &&
          other.ts == this.ts &&
          other.rpm == this.rpm &&
          other.temperature == this.temperature &&
          other.vibration == this.vibration &&
          other.current == this.current &&
          other.health == this.health &&
          other.fault == this.fault &&
          other.level == this.level &&
          other.buzzerOn == this.buzzerOn);
}

class TelemetryRowsCompanion extends UpdateCompanion<TelemetryRow> {
  final Value<int> id;
  final Value<int> ts;
  final Value<double> rpm;
  final Value<double> temperature;
  final Value<double?> vibration;
  final Value<double?> current;
  final Value<double?> health;
  final Value<String?> fault;
  final Value<int> level;
  final Value<bool> buzzerOn;
  const TelemetryRowsCompanion({
    this.id = const Value.absent(),
    this.ts = const Value.absent(),
    this.rpm = const Value.absent(),
    this.temperature = const Value.absent(),
    this.vibration = const Value.absent(),
    this.current = const Value.absent(),
    this.health = const Value.absent(),
    this.fault = const Value.absent(),
    this.level = const Value.absent(),
    this.buzzerOn = const Value.absent(),
  });
  TelemetryRowsCompanion.insert({
    this.id = const Value.absent(),
    required int ts,
    required double rpm,
    required double temperature,
    this.vibration = const Value.absent(),
    this.current = const Value.absent(),
    this.health = const Value.absent(),
    this.fault = const Value.absent(),
    required int level,
    required bool buzzerOn,
  }) : ts = Value(ts),
       rpm = Value(rpm),
       temperature = Value(temperature),
       level = Value(level),
       buzzerOn = Value(buzzerOn);
  static Insertable<TelemetryRow> custom({
    Expression<int>? id,
    Expression<int>? ts,
    Expression<double>? rpm,
    Expression<double>? temperature,
    Expression<double>? vibration,
    Expression<double>? current,
    Expression<double>? health,
    Expression<String>? fault,
    Expression<int>? level,
    Expression<bool>? buzzerOn,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (ts != null) 'ts': ts,
      if (rpm != null) 'rpm': rpm,
      if (temperature != null) 'temperature': temperature,
      if (vibration != null) 'vibration': vibration,
      if (current != null) 'current': current,
      if (health != null) 'health': health,
      if (fault != null) 'fault': fault,
      if (level != null) 'level': level,
      if (buzzerOn != null) 'buzzer_on': buzzerOn,
    });
  }

  TelemetryRowsCompanion copyWith({
    Value<int>? id,
    Value<int>? ts,
    Value<double>? rpm,
    Value<double>? temperature,
    Value<double?>? vibration,
    Value<double?>? current,
    Value<double?>? health,
    Value<String?>? fault,
    Value<int>? level,
    Value<bool>? buzzerOn,
  }) {
    return TelemetryRowsCompanion(
      id: id ?? this.id,
      ts: ts ?? this.ts,
      rpm: rpm ?? this.rpm,
      temperature: temperature ?? this.temperature,
      vibration: vibration ?? this.vibration,
      current: current ?? this.current,
      health: health ?? this.health,
      fault: fault ?? this.fault,
      level: level ?? this.level,
      buzzerOn: buzzerOn ?? this.buzzerOn,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (ts.present) {
      map['ts'] = Variable<int>(ts.value);
    }
    if (rpm.present) {
      map['rpm'] = Variable<double>(rpm.value);
    }
    if (temperature.present) {
      map['temperature'] = Variable<double>(temperature.value);
    }
    if (vibration.present) {
      map['vibration'] = Variable<double>(vibration.value);
    }
    if (current.present) {
      map['current'] = Variable<double>(current.value);
    }
    if (health.present) {
      map['health'] = Variable<double>(health.value);
    }
    if (fault.present) {
      map['fault'] = Variable<String>(fault.value);
    }
    if (level.present) {
      map['level'] = Variable<int>(level.value);
    }
    if (buzzerOn.present) {
      map['buzzer_on'] = Variable<bool>(buzzerOn.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TelemetryRowsCompanion(')
          ..write('id: $id, ')
          ..write('ts: $ts, ')
          ..write('rpm: $rpm, ')
          ..write('temperature: $temperature, ')
          ..write('vibration: $vibration, ')
          ..write('current: $current, ')
          ..write('health: $health, ')
          ..write('fault: $fault, ')
          ..write('level: $level, ')
          ..write('buzzerOn: $buzzerOn')
          ..write(')'))
        .toString();
  }
}

class $AlertRowsTable extends AlertRows
    with TableInfo<$AlertRowsTable, AlertRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AlertRowsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _tsMeta = const VerificationMeta('ts');
  @override
  late final GeneratedColumn<int> ts = GeneratedColumn<int>(
    'ts',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _levelMeta = const VerificationMeta('level');
  @override
  late final GeneratedColumn<int> level = GeneratedColumn<int>(
    'level',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<double> value = GeneratedColumn<double>(
    'value',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _messageMeta = const VerificationMeta(
    'message',
  );
  @override
  late final GeneratedColumn<String> message = GeneratedColumn<String>(
    'message',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [id, ts, level, type, value, message];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'alerts';
  @override
  VerificationContext validateIntegrity(
    Insertable<AlertRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('ts')) {
      context.handle(_tsMeta, ts.isAcceptableOrUnknown(data['ts']!, _tsMeta));
    } else if (isInserting) {
      context.missing(_tsMeta);
    }
    if (data.containsKey('level')) {
      context.handle(
        _levelMeta,
        level.isAcceptableOrUnknown(data['level']!, _levelMeta),
      );
    } else if (isInserting) {
      context.missing(_levelMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    }
    if (data.containsKey('message')) {
      context.handle(
        _messageMeta,
        message.isAcceptableOrUnknown(data['message']!, _messageMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AlertRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AlertRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      ts: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}ts'],
      )!,
      level: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}level'],
      )!,
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}value'],
      ),
      message: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}message'],
      ),
    );
  }

  @override
  $AlertRowsTable createAlias(String alias) {
    return $AlertRowsTable(attachedDatabase, alias);
  }
}

class AlertRow extends DataClass implements Insertable<AlertRow> {
  final int id;
  final int ts;
  final int level;

  /// AlertType.name
  final String type;
  final double? value;
  final String? message;
  const AlertRow({
    required this.id,
    required this.ts,
    required this.level,
    required this.type,
    this.value,
    this.message,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['ts'] = Variable<int>(ts);
    map['level'] = Variable<int>(level);
    map['type'] = Variable<String>(type);
    if (!nullToAbsent || value != null) {
      map['value'] = Variable<double>(value);
    }
    if (!nullToAbsent || message != null) {
      map['message'] = Variable<String>(message);
    }
    return map;
  }

  AlertRowsCompanion toCompanion(bool nullToAbsent) {
    return AlertRowsCompanion(
      id: Value(id),
      ts: Value(ts),
      level: Value(level),
      type: Value(type),
      value: value == null && nullToAbsent
          ? const Value.absent()
          : Value(value),
      message: message == null && nullToAbsent
          ? const Value.absent()
          : Value(message),
    );
  }

  factory AlertRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AlertRow(
      id: serializer.fromJson<int>(json['id']),
      ts: serializer.fromJson<int>(json['ts']),
      level: serializer.fromJson<int>(json['level']),
      type: serializer.fromJson<String>(json['type']),
      value: serializer.fromJson<double?>(json['value']),
      message: serializer.fromJson<String?>(json['message']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'ts': serializer.toJson<int>(ts),
      'level': serializer.toJson<int>(level),
      'type': serializer.toJson<String>(type),
      'value': serializer.toJson<double?>(value),
      'message': serializer.toJson<String?>(message),
    };
  }

  AlertRow copyWith({
    int? id,
    int? ts,
    int? level,
    String? type,
    Value<double?> value = const Value.absent(),
    Value<String?> message = const Value.absent(),
  }) => AlertRow(
    id: id ?? this.id,
    ts: ts ?? this.ts,
    level: level ?? this.level,
    type: type ?? this.type,
    value: value.present ? value.value : this.value,
    message: message.present ? message.value : this.message,
  );
  AlertRow copyWithCompanion(AlertRowsCompanion data) {
    return AlertRow(
      id: data.id.present ? data.id.value : this.id,
      ts: data.ts.present ? data.ts.value : this.ts,
      level: data.level.present ? data.level.value : this.level,
      type: data.type.present ? data.type.value : this.type,
      value: data.value.present ? data.value.value : this.value,
      message: data.message.present ? data.message.value : this.message,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AlertRow(')
          ..write('id: $id, ')
          ..write('ts: $ts, ')
          ..write('level: $level, ')
          ..write('type: $type, ')
          ..write('value: $value, ')
          ..write('message: $message')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, ts, level, type, value, message);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AlertRow &&
          other.id == this.id &&
          other.ts == this.ts &&
          other.level == this.level &&
          other.type == this.type &&
          other.value == this.value &&
          other.message == this.message);
}

class AlertRowsCompanion extends UpdateCompanion<AlertRow> {
  final Value<int> id;
  final Value<int> ts;
  final Value<int> level;
  final Value<String> type;
  final Value<double?> value;
  final Value<String?> message;
  const AlertRowsCompanion({
    this.id = const Value.absent(),
    this.ts = const Value.absent(),
    this.level = const Value.absent(),
    this.type = const Value.absent(),
    this.value = const Value.absent(),
    this.message = const Value.absent(),
  });
  AlertRowsCompanion.insert({
    this.id = const Value.absent(),
    required int ts,
    required int level,
    required String type,
    this.value = const Value.absent(),
    this.message = const Value.absent(),
  }) : ts = Value(ts),
       level = Value(level),
       type = Value(type);
  static Insertable<AlertRow> custom({
    Expression<int>? id,
    Expression<int>? ts,
    Expression<int>? level,
    Expression<String>? type,
    Expression<double>? value,
    Expression<String>? message,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (ts != null) 'ts': ts,
      if (level != null) 'level': level,
      if (type != null) 'type': type,
      if (value != null) 'value': value,
      if (message != null) 'message': message,
    });
  }

  AlertRowsCompanion copyWith({
    Value<int>? id,
    Value<int>? ts,
    Value<int>? level,
    Value<String>? type,
    Value<double?>? value,
    Value<String?>? message,
  }) {
    return AlertRowsCompanion(
      id: id ?? this.id,
      ts: ts ?? this.ts,
      level: level ?? this.level,
      type: type ?? this.type,
      value: value ?? this.value,
      message: message ?? this.message,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (ts.present) {
      map['ts'] = Variable<int>(ts.value);
    }
    if (level.present) {
      map['level'] = Variable<int>(level.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (value.present) {
      map['value'] = Variable<double>(value.value);
    }
    if (message.present) {
      map['message'] = Variable<String>(message.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AlertRowsCompanion(')
          ..write('id: $id, ')
          ..write('ts: $ts, ')
          ..write('level: $level, ')
          ..write('type: $type, ')
          ..write('value: $value, ')
          ..write('message: $message')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $TelemetryRowsTable telemetryRows = $TelemetryRowsTable(this);
  late final $AlertRowsTable alertRows = $AlertRowsTable(this);
  late final Index telemetryTs = Index(
    'telemetry_ts',
    'CREATE INDEX telemetry_ts ON telemetry (ts)',
  );
  late final Index alertsTs = Index(
    'alerts_ts',
    'CREATE INDEX alerts_ts ON alerts (ts)',
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    telemetryRows,
    alertRows,
    telemetryTs,
    alertsTs,
  ];
}

typedef $$TelemetryRowsTableCreateCompanionBuilder =
    TelemetryRowsCompanion Function({
      Value<int> id,
      required int ts,
      required double rpm,
      required double temperature,
      Value<double?> vibration,
      Value<double?> current,
      Value<double?> health,
      Value<String?> fault,
      required int level,
      required bool buzzerOn,
    });
typedef $$TelemetryRowsTableUpdateCompanionBuilder =
    TelemetryRowsCompanion Function({
      Value<int> id,
      Value<int> ts,
      Value<double> rpm,
      Value<double> temperature,
      Value<double?> vibration,
      Value<double?> current,
      Value<double?> health,
      Value<String?> fault,
      Value<int> level,
      Value<bool> buzzerOn,
    });

class $$TelemetryRowsTableFilterComposer
    extends Composer<_$AppDatabase, $TelemetryRowsTable> {
  $$TelemetryRowsTableFilterComposer({
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

  ColumnFilters<int> get ts => $composableBuilder(
    column: $table.ts,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get rpm => $composableBuilder(
    column: $table.rpm,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get temperature => $composableBuilder(
    column: $table.temperature,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get vibration => $composableBuilder(
    column: $table.vibration,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get current => $composableBuilder(
    column: $table.current,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get health => $composableBuilder(
    column: $table.health,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fault => $composableBuilder(
    column: $table.fault,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get level => $composableBuilder(
    column: $table.level,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get buzzerOn => $composableBuilder(
    column: $table.buzzerOn,
    builder: (column) => ColumnFilters(column),
  );
}

class $$TelemetryRowsTableOrderingComposer
    extends Composer<_$AppDatabase, $TelemetryRowsTable> {
  $$TelemetryRowsTableOrderingComposer({
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

  ColumnOrderings<int> get ts => $composableBuilder(
    column: $table.ts,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get rpm => $composableBuilder(
    column: $table.rpm,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get temperature => $composableBuilder(
    column: $table.temperature,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get vibration => $composableBuilder(
    column: $table.vibration,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get current => $composableBuilder(
    column: $table.current,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get health => $composableBuilder(
    column: $table.health,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fault => $composableBuilder(
    column: $table.fault,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get level => $composableBuilder(
    column: $table.level,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get buzzerOn => $composableBuilder(
    column: $table.buzzerOn,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$TelemetryRowsTableAnnotationComposer
    extends Composer<_$AppDatabase, $TelemetryRowsTable> {
  $$TelemetryRowsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get ts =>
      $composableBuilder(column: $table.ts, builder: (column) => column);

  GeneratedColumn<double> get rpm =>
      $composableBuilder(column: $table.rpm, builder: (column) => column);

  GeneratedColumn<double> get temperature => $composableBuilder(
    column: $table.temperature,
    builder: (column) => column,
  );

  GeneratedColumn<double> get vibration =>
      $composableBuilder(column: $table.vibration, builder: (column) => column);

  GeneratedColumn<double> get current =>
      $composableBuilder(column: $table.current, builder: (column) => column);

  GeneratedColumn<double> get health =>
      $composableBuilder(column: $table.health, builder: (column) => column);

  GeneratedColumn<String> get fault =>
      $composableBuilder(column: $table.fault, builder: (column) => column);

  GeneratedColumn<int> get level =>
      $composableBuilder(column: $table.level, builder: (column) => column);

  GeneratedColumn<bool> get buzzerOn =>
      $composableBuilder(column: $table.buzzerOn, builder: (column) => column);
}

class $$TelemetryRowsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TelemetryRowsTable,
          TelemetryRow,
          $$TelemetryRowsTableFilterComposer,
          $$TelemetryRowsTableOrderingComposer,
          $$TelemetryRowsTableAnnotationComposer,
          $$TelemetryRowsTableCreateCompanionBuilder,
          $$TelemetryRowsTableUpdateCompanionBuilder,
          (
            TelemetryRow,
            BaseReferences<_$AppDatabase, $TelemetryRowsTable, TelemetryRow>,
          ),
          TelemetryRow,
          PrefetchHooks Function()
        > {
  $$TelemetryRowsTableTableManager(_$AppDatabase db, $TelemetryRowsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TelemetryRowsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TelemetryRowsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TelemetryRowsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> ts = const Value.absent(),
                Value<double> rpm = const Value.absent(),
                Value<double> temperature = const Value.absent(),
                Value<double?> vibration = const Value.absent(),
                Value<double?> current = const Value.absent(),
                Value<double?> health = const Value.absent(),
                Value<String?> fault = const Value.absent(),
                Value<int> level = const Value.absent(),
                Value<bool> buzzerOn = const Value.absent(),
              }) => TelemetryRowsCompanion(
                id: id,
                ts: ts,
                rpm: rpm,
                temperature: temperature,
                vibration: vibration,
                current: current,
                health: health,
                fault: fault,
                level: level,
                buzzerOn: buzzerOn,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int ts,
                required double rpm,
                required double temperature,
                Value<double?> vibration = const Value.absent(),
                Value<double?> current = const Value.absent(),
                Value<double?> health = const Value.absent(),
                Value<String?> fault = const Value.absent(),
                required int level,
                required bool buzzerOn,
              }) => TelemetryRowsCompanion.insert(
                id: id,
                ts: ts,
                rpm: rpm,
                temperature: temperature,
                vibration: vibration,
                current: current,
                health: health,
                fault: fault,
                level: level,
                buzzerOn: buzzerOn,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$TelemetryRowsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TelemetryRowsTable,
      TelemetryRow,
      $$TelemetryRowsTableFilterComposer,
      $$TelemetryRowsTableOrderingComposer,
      $$TelemetryRowsTableAnnotationComposer,
      $$TelemetryRowsTableCreateCompanionBuilder,
      $$TelemetryRowsTableUpdateCompanionBuilder,
      (
        TelemetryRow,
        BaseReferences<_$AppDatabase, $TelemetryRowsTable, TelemetryRow>,
      ),
      TelemetryRow,
      PrefetchHooks Function()
    >;
typedef $$AlertRowsTableCreateCompanionBuilder =
    AlertRowsCompanion Function({
      Value<int> id,
      required int ts,
      required int level,
      required String type,
      Value<double?> value,
      Value<String?> message,
    });
typedef $$AlertRowsTableUpdateCompanionBuilder =
    AlertRowsCompanion Function({
      Value<int> id,
      Value<int> ts,
      Value<int> level,
      Value<String> type,
      Value<double?> value,
      Value<String?> message,
    });

class $$AlertRowsTableFilterComposer
    extends Composer<_$AppDatabase, $AlertRowsTable> {
  $$AlertRowsTableFilterComposer({
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

  ColumnFilters<int> get ts => $composableBuilder(
    column: $table.ts,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get level => $composableBuilder(
    column: $table.level,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get message => $composableBuilder(
    column: $table.message,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AlertRowsTableOrderingComposer
    extends Composer<_$AppDatabase, $AlertRowsTable> {
  $$AlertRowsTableOrderingComposer({
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

  ColumnOrderings<int> get ts => $composableBuilder(
    column: $table.ts,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get level => $composableBuilder(
    column: $table.level,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get message => $composableBuilder(
    column: $table.message,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AlertRowsTableAnnotationComposer
    extends Composer<_$AppDatabase, $AlertRowsTable> {
  $$AlertRowsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get ts =>
      $composableBuilder(column: $table.ts, builder: (column) => column);

  GeneratedColumn<int> get level =>
      $composableBuilder(column: $table.level, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<double> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);

  GeneratedColumn<String> get message =>
      $composableBuilder(column: $table.message, builder: (column) => column);
}

class $$AlertRowsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AlertRowsTable,
          AlertRow,
          $$AlertRowsTableFilterComposer,
          $$AlertRowsTableOrderingComposer,
          $$AlertRowsTableAnnotationComposer,
          $$AlertRowsTableCreateCompanionBuilder,
          $$AlertRowsTableUpdateCompanionBuilder,
          (AlertRow, BaseReferences<_$AppDatabase, $AlertRowsTable, AlertRow>),
          AlertRow,
          PrefetchHooks Function()
        > {
  $$AlertRowsTableTableManager(_$AppDatabase db, $AlertRowsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AlertRowsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AlertRowsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AlertRowsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> ts = const Value.absent(),
                Value<int> level = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<double?> value = const Value.absent(),
                Value<String?> message = const Value.absent(),
              }) => AlertRowsCompanion(
                id: id,
                ts: ts,
                level: level,
                type: type,
                value: value,
                message: message,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int ts,
                required int level,
                required String type,
                Value<double?> value = const Value.absent(),
                Value<String?> message = const Value.absent(),
              }) => AlertRowsCompanion.insert(
                id: id,
                ts: ts,
                level: level,
                type: type,
                value: value,
                message: message,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AlertRowsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AlertRowsTable,
      AlertRow,
      $$AlertRowsTableFilterComposer,
      $$AlertRowsTableOrderingComposer,
      $$AlertRowsTableAnnotationComposer,
      $$AlertRowsTableCreateCompanionBuilder,
      $$AlertRowsTableUpdateCompanionBuilder,
      (AlertRow, BaseReferences<_$AppDatabase, $AlertRowsTable, AlertRow>),
      AlertRow,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$TelemetryRowsTableTableManager get telemetryRows =>
      $$TelemetryRowsTableTableManager(_db, _db.telemetryRows);
  $$AlertRowsTableTableManager get alertRows =>
      $$AlertRowsTableTableManager(_db, _db.alertRows);
}
