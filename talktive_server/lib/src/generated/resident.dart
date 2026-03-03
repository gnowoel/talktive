/* AUTOMATICALLY GENERATED CODE DO NOT MODIFY */
/*   To generate run: "serverpod generate"    */

// ignore_for_file: implementation_imports
// ignore_for_file: library_private_types_in_public_api
// ignore_for_file: non_constant_identifier_names
// ignore_for_file: public_member_api_docs
// ignore_for_file: type_literal_in_constant_pattern
// ignore_for_file: use_super_parameters
// ignore_for_file: invalid_use_of_internal_member

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:serverpod/serverpod.dart' as _i1;
import 'package:talktive_server/src/generated/protocol.dart' as _i2;

abstract class Resident
    implements _i1.TableRow<int?>, _i1.ProtocolSerialization {
  Resident._({
    this.id,
    required this.userInfoId,
    int? trustScore,
    this.lastReputationIncrease,
    this.mutedUntil,
    bool? suspended,
    int? xp,
    int? level,
    int? currentStreak,
    int? longestStreak,
    this.lastLoginDate,
    this.lastMessageDate,
    int? experienceMessageCount,
    this.userName,
    this.gender,
    this.country,
    this.bio,
    this.mood,
    this.avatar,
    this.interests,
    this.languages,
    this.role,
    bool? isAdmin,
  }) : trustScore = trustScore ?? 100,
       suspended = suspended ?? false,
       xp = xp ?? 0,
       level = level ?? 0,
       currentStreak = currentStreak ?? 0,
       longestStreak = longestStreak ?? 0,
       experienceMessageCount = experienceMessageCount ?? 0,
       isAdmin = isAdmin ?? false;

  factory Resident({
    int? id,
    required _i1.UuidValue userInfoId,
    int? trustScore,
    DateTime? lastReputationIncrease,
    DateTime? mutedUntil,
    bool? suspended,
    int? xp,
    int? level,
    int? currentStreak,
    int? longestStreak,
    DateTime? lastLoginDate,
    DateTime? lastMessageDate,
    int? experienceMessageCount,
    String? userName,
    String? gender,
    String? country,
    String? bio,
    String? mood,
    String? avatar,
    List<String>? interests,
    List<String>? languages,
    String? role,
    bool? isAdmin,
  }) = _ResidentImpl;

  factory Resident.fromJson(Map<String, dynamic> jsonSerialization) {
    return Resident(
      id: jsonSerialization['id'] as int?,
      userInfoId: _i1.UuidValueJsonExtension.fromJson(
        jsonSerialization['userInfoId'],
      ),
      trustScore: jsonSerialization['trustScore'] as int?,
      lastReputationIncrease:
          jsonSerialization['lastReputationIncrease'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(
              jsonSerialization['lastReputationIncrease'],
            ),
      mutedUntil: jsonSerialization['mutedUntil'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(jsonSerialization['mutedUntil']),
      suspended: jsonSerialization['suspended'] as bool?,
      xp: jsonSerialization['xp'] as int?,
      level: jsonSerialization['level'] as int?,
      currentStreak: jsonSerialization['currentStreak'] as int?,
      longestStreak: jsonSerialization['longestStreak'] as int?,
      lastLoginDate: jsonSerialization['lastLoginDate'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(
              jsonSerialization['lastLoginDate'],
            ),
      lastMessageDate: jsonSerialization['lastMessageDate'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(
              jsonSerialization['lastMessageDate'],
            ),
      experienceMessageCount:
          jsonSerialization['experienceMessageCount'] as int?,
      userName: jsonSerialization['userName'] as String?,
      gender: jsonSerialization['gender'] as String?,
      country: jsonSerialization['country'] as String?,
      bio: jsonSerialization['bio'] as String?,
      mood: jsonSerialization['mood'] as String?,
      avatar: jsonSerialization['avatar'] as String?,
      interests: jsonSerialization['interests'] == null
          ? null
          : _i2.Protocol().deserialize<List<String>>(
              jsonSerialization['interests'],
            ),
      languages: jsonSerialization['languages'] == null
          ? null
          : _i2.Protocol().deserialize<List<String>>(
              jsonSerialization['languages'],
            ),
      role: jsonSerialization['role'] as String?,
      isAdmin: jsonSerialization['isAdmin'] as bool?,
    );
  }

  static final t = ResidentTable();

  static const db = ResidentRepository._();

  @override
  int? id;

  _i1.UuidValue userInfoId;

  int trustScore;

  DateTime? lastReputationIncrease;

  DateTime? mutedUntil;

  bool suspended;

  int xp;

  int level;

  int currentStreak;

  int longestStreak;

  DateTime? lastLoginDate;

  DateTime? lastMessageDate;

  int experienceMessageCount;

  String? userName;

  String? gender;

  String? country;

  String? bio;

  String? mood;

  String? avatar;

  List<String>? interests;

  List<String>? languages;

  String? role;

  bool isAdmin;

  @override
  _i1.Table<int?> get table => t;

  /// Returns a shallow copy of this [Resident]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  Resident copyWith({
    int? id,
    _i1.UuidValue? userInfoId,
    int? trustScore,
    DateTime? lastReputationIncrease,
    DateTime? mutedUntil,
    bool? suspended,
    int? xp,
    int? level,
    int? currentStreak,
    int? longestStreak,
    DateTime? lastLoginDate,
    DateTime? lastMessageDate,
    int? experienceMessageCount,
    String? userName,
    String? gender,
    String? country,
    String? bio,
    String? mood,
    String? avatar,
    List<String>? interests,
    List<String>? languages,
    String? role,
    bool? isAdmin,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'Resident',
      if (id != null) 'id': id,
      'userInfoId': userInfoId.toJson(),
      'trustScore': trustScore,
      if (lastReputationIncrease != null)
        'lastReputationIncrease': lastReputationIncrease?.toJson(),
      if (mutedUntil != null) 'mutedUntil': mutedUntil?.toJson(),
      'suspended': suspended,
      'xp': xp,
      'level': level,
      'currentStreak': currentStreak,
      'longestStreak': longestStreak,
      if (lastLoginDate != null) 'lastLoginDate': lastLoginDate?.toJson(),
      if (lastMessageDate != null) 'lastMessageDate': lastMessageDate?.toJson(),
      'experienceMessageCount': experienceMessageCount,
      if (userName != null) 'userName': userName,
      if (gender != null) 'gender': gender,
      if (country != null) 'country': country,
      if (bio != null) 'bio': bio,
      if (mood != null) 'mood': mood,
      if (avatar != null) 'avatar': avatar,
      if (interests != null) 'interests': interests?.toJson(),
      if (languages != null) 'languages': languages?.toJson(),
      if (role != null) 'role': role,
      'isAdmin': isAdmin,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'Resident',
      if (id != null) 'id': id,
      'userInfoId': userInfoId.toJson(),
      'trustScore': trustScore,
      if (lastReputationIncrease != null)
        'lastReputationIncrease': lastReputationIncrease?.toJson(),
      if (mutedUntil != null) 'mutedUntil': mutedUntil?.toJson(),
      'suspended': suspended,
      'xp': xp,
      'level': level,
      'currentStreak': currentStreak,
      'longestStreak': longestStreak,
      if (lastLoginDate != null) 'lastLoginDate': lastLoginDate?.toJson(),
      if (lastMessageDate != null) 'lastMessageDate': lastMessageDate?.toJson(),
      'experienceMessageCount': experienceMessageCount,
      if (userName != null) 'userName': userName,
      if (gender != null) 'gender': gender,
      if (country != null) 'country': country,
      if (bio != null) 'bio': bio,
      if (mood != null) 'mood': mood,
      if (avatar != null) 'avatar': avatar,
      if (interests != null) 'interests': interests?.toJson(),
      if (languages != null) 'languages': languages?.toJson(),
      if (role != null) 'role': role,
      'isAdmin': isAdmin,
    };
  }

  static ResidentInclude include() {
    return ResidentInclude._();
  }

  static ResidentIncludeList includeList({
    _i1.WhereExpressionBuilder<ResidentTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<ResidentTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<ResidentTable>? orderByList,
    ResidentInclude? include,
  }) {
    return ResidentIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(Resident.t),
      orderDescending: orderDescending,
      orderByList: orderByList?.call(Resident.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _ResidentImpl extends Resident {
  _ResidentImpl({
    int? id,
    required _i1.UuidValue userInfoId,
    int? trustScore,
    DateTime? lastReputationIncrease,
    DateTime? mutedUntil,
    bool? suspended,
    int? xp,
    int? level,
    int? currentStreak,
    int? longestStreak,
    DateTime? lastLoginDate,
    DateTime? lastMessageDate,
    int? experienceMessageCount,
    String? userName,
    String? gender,
    String? country,
    String? bio,
    String? mood,
    String? avatar,
    List<String>? interests,
    List<String>? languages,
    String? role,
    bool? isAdmin,
  }) : super._(
         id: id,
         userInfoId: userInfoId,
         trustScore: trustScore,
         lastReputationIncrease: lastReputationIncrease,
         mutedUntil: mutedUntil,
         suspended: suspended,
         xp: xp,
         level: level,
         currentStreak: currentStreak,
         longestStreak: longestStreak,
         lastLoginDate: lastLoginDate,
         lastMessageDate: lastMessageDate,
         experienceMessageCount: experienceMessageCount,
         userName: userName,
         gender: gender,
         country: country,
         bio: bio,
         mood: mood,
         avatar: avatar,
         interests: interests,
         languages: languages,
         role: role,
         isAdmin: isAdmin,
       );

  /// Returns a shallow copy of this [Resident]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  Resident copyWith({
    Object? id = _Undefined,
    _i1.UuidValue? userInfoId,
    int? trustScore,
    Object? lastReputationIncrease = _Undefined,
    Object? mutedUntil = _Undefined,
    bool? suspended,
    int? xp,
    int? level,
    int? currentStreak,
    int? longestStreak,
    Object? lastLoginDate = _Undefined,
    Object? lastMessageDate = _Undefined,
    int? experienceMessageCount,
    Object? userName = _Undefined,
    Object? gender = _Undefined,
    Object? country = _Undefined,
    Object? bio = _Undefined,
    Object? mood = _Undefined,
    Object? avatar = _Undefined,
    Object? interests = _Undefined,
    Object? languages = _Undefined,
    Object? role = _Undefined,
    bool? isAdmin,
  }) {
    return Resident(
      id: id is int? ? id : this.id,
      userInfoId: userInfoId ?? this.userInfoId,
      trustScore: trustScore ?? this.trustScore,
      lastReputationIncrease: lastReputationIncrease is DateTime?
          ? lastReputationIncrease
          : this.lastReputationIncrease,
      mutedUntil: mutedUntil is DateTime? ? mutedUntil : this.mutedUntil,
      suspended: suspended ?? this.suspended,
      xp: xp ?? this.xp,
      level: level ?? this.level,
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      lastLoginDate: lastLoginDate is DateTime?
          ? lastLoginDate
          : this.lastLoginDate,
      lastMessageDate: lastMessageDate is DateTime?
          ? lastMessageDate
          : this.lastMessageDate,
      experienceMessageCount:
          experienceMessageCount ?? this.experienceMessageCount,
      userName: userName is String? ? userName : this.userName,
      gender: gender is String? ? gender : this.gender,
      country: country is String? ? country : this.country,
      bio: bio is String? ? bio : this.bio,
      mood: mood is String? ? mood : this.mood,
      avatar: avatar is String? ? avatar : this.avatar,
      interests: interests is List<String>?
          ? interests
          : this.interests?.map((e0) => e0).toList(),
      languages: languages is List<String>?
          ? languages
          : this.languages?.map((e0) => e0).toList(),
      role: role is String? ? role : this.role,
      isAdmin: isAdmin ?? this.isAdmin,
    );
  }
}

class ResidentUpdateTable extends _i1.UpdateTable<ResidentTable> {
  ResidentUpdateTable(super.table);

  _i1.ColumnValue<_i1.UuidValue, _i1.UuidValue> userInfoId(
    _i1.UuidValue value,
  ) => _i1.ColumnValue(
    table.userInfoId,
    value,
  );

  _i1.ColumnValue<int, int> trustScore(int value) => _i1.ColumnValue(
    table.trustScore,
    value,
  );

  _i1.ColumnValue<DateTime, DateTime> lastReputationIncrease(DateTime? value) =>
      _i1.ColumnValue(
        table.lastReputationIncrease,
        value,
      );

  _i1.ColumnValue<DateTime, DateTime> mutedUntil(DateTime? value) =>
      _i1.ColumnValue(
        table.mutedUntil,
        value,
      );

  _i1.ColumnValue<bool, bool> suspended(bool value) => _i1.ColumnValue(
    table.suspended,
    value,
  );

  _i1.ColumnValue<int, int> xp(int value) => _i1.ColumnValue(
    table.xp,
    value,
  );

  _i1.ColumnValue<int, int> level(int value) => _i1.ColumnValue(
    table.level,
    value,
  );

  _i1.ColumnValue<int, int> currentStreak(int value) => _i1.ColumnValue(
    table.currentStreak,
    value,
  );

  _i1.ColumnValue<int, int> longestStreak(int value) => _i1.ColumnValue(
    table.longestStreak,
    value,
  );

  _i1.ColumnValue<DateTime, DateTime> lastLoginDate(DateTime? value) =>
      _i1.ColumnValue(
        table.lastLoginDate,
        value,
      );

  _i1.ColumnValue<DateTime, DateTime> lastMessageDate(DateTime? value) =>
      _i1.ColumnValue(
        table.lastMessageDate,
        value,
      );

  _i1.ColumnValue<int, int> experienceMessageCount(int value) =>
      _i1.ColumnValue(
        table.experienceMessageCount,
        value,
      );

  _i1.ColumnValue<String, String> userName(String? value) => _i1.ColumnValue(
    table.userName,
    value,
  );

  _i1.ColumnValue<String, String> gender(String? value) => _i1.ColumnValue(
    table.gender,
    value,
  );

  _i1.ColumnValue<String, String> country(String? value) => _i1.ColumnValue(
    table.country,
    value,
  );

  _i1.ColumnValue<String, String> bio(String? value) => _i1.ColumnValue(
    table.bio,
    value,
  );

  _i1.ColumnValue<String, String> mood(String? value) => _i1.ColumnValue(
    table.mood,
    value,
  );

  _i1.ColumnValue<String, String> avatar(String? value) => _i1.ColumnValue(
    table.avatar,
    value,
  );

  _i1.ColumnValue<List<String>, List<String>> interests(List<String>? value) =>
      _i1.ColumnValue(
        table.interests,
        value,
      );

  _i1.ColumnValue<List<String>, List<String>> languages(List<String>? value) =>
      _i1.ColumnValue(
        table.languages,
        value,
      );

  _i1.ColumnValue<String, String> role(String? value) => _i1.ColumnValue(
    table.role,
    value,
  );

  _i1.ColumnValue<bool, bool> isAdmin(bool value) => _i1.ColumnValue(
    table.isAdmin,
    value,
  );
}

class ResidentTable extends _i1.Table<int?> {
  ResidentTable({super.tableRelation}) : super(tableName: 'resident') {
    updateTable = ResidentUpdateTable(this);
    userInfoId = _i1.ColumnUuid(
      'userInfoId',
      this,
    );
    trustScore = _i1.ColumnInt(
      'trustScore',
      this,
      hasDefault: true,
    );
    lastReputationIncrease = _i1.ColumnDateTime(
      'lastReputationIncrease',
      this,
    );
    mutedUntil = _i1.ColumnDateTime(
      'mutedUntil',
      this,
    );
    suspended = _i1.ColumnBool(
      'suspended',
      this,
      hasDefault: true,
    );
    xp = _i1.ColumnInt(
      'xp',
      this,
      hasDefault: true,
    );
    level = _i1.ColumnInt(
      'level',
      this,
      hasDefault: true,
    );
    currentStreak = _i1.ColumnInt(
      'currentStreak',
      this,
      hasDefault: true,
    );
    longestStreak = _i1.ColumnInt(
      'longestStreak',
      this,
      hasDefault: true,
    );
    lastLoginDate = _i1.ColumnDateTime(
      'lastLoginDate',
      this,
    );
    lastMessageDate = _i1.ColumnDateTime(
      'lastMessageDate',
      this,
    );
    experienceMessageCount = _i1.ColumnInt(
      'experienceMessageCount',
      this,
      hasDefault: true,
    );
    userName = _i1.ColumnString(
      'userName',
      this,
    );
    gender = _i1.ColumnString(
      'gender',
      this,
    );
    country = _i1.ColumnString(
      'country',
      this,
    );
    bio = _i1.ColumnString(
      'bio',
      this,
    );
    mood = _i1.ColumnString(
      'mood',
      this,
    );
    avatar = _i1.ColumnString(
      'avatar',
      this,
    );
    interests = _i1.ColumnSerializable<List<String>>(
      'interests',
      this,
    );
    languages = _i1.ColumnSerializable<List<String>>(
      'languages',
      this,
    );
    role = _i1.ColumnString(
      'role',
      this,
    );
    isAdmin = _i1.ColumnBool(
      'isAdmin',
      this,
      hasDefault: true,
    );
  }

  late final ResidentUpdateTable updateTable;

  late final _i1.ColumnUuid userInfoId;

  late final _i1.ColumnInt trustScore;

  late final _i1.ColumnDateTime lastReputationIncrease;

  late final _i1.ColumnDateTime mutedUntil;

  late final _i1.ColumnBool suspended;

  late final _i1.ColumnInt xp;

  late final _i1.ColumnInt level;

  late final _i1.ColumnInt currentStreak;

  late final _i1.ColumnInt longestStreak;

  late final _i1.ColumnDateTime lastLoginDate;

  late final _i1.ColumnDateTime lastMessageDate;

  late final _i1.ColumnInt experienceMessageCount;

  late final _i1.ColumnString userName;

  late final _i1.ColumnString gender;

  late final _i1.ColumnString country;

  late final _i1.ColumnString bio;

  late final _i1.ColumnString mood;

  late final _i1.ColumnString avatar;

  late final _i1.ColumnSerializable<List<String>> interests;

  late final _i1.ColumnSerializable<List<String>> languages;

  late final _i1.ColumnString role;

  late final _i1.ColumnBool isAdmin;

  @override
  List<_i1.Column> get columns => [
    id,
    userInfoId,
    trustScore,
    lastReputationIncrease,
    mutedUntil,
    suspended,
    xp,
    level,
    currentStreak,
    longestStreak,
    lastLoginDate,
    lastMessageDate,
    experienceMessageCount,
    userName,
    gender,
    country,
    bio,
    mood,
    avatar,
    interests,
    languages,
    role,
    isAdmin,
  ];
}

class ResidentInclude extends _i1.IncludeObject {
  ResidentInclude._();

  @override
  Map<String, _i1.Include?> get includes => {};

  @override
  _i1.Table<int?> get table => Resident.t;
}

class ResidentIncludeList extends _i1.IncludeList {
  ResidentIncludeList._({
    _i1.WhereExpressionBuilder<ResidentTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderDescending,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(Resident.t);
  }

  @override
  Map<String, _i1.Include?> get includes => include?.includes ?? {};

  @override
  _i1.Table<int?> get table => Resident.t;
}

class ResidentRepository {
  const ResidentRepository._();

  /// Returns a list of [Resident]s matching the given query parameters.
  ///
  /// Use [where] to specify which items to include in the return value.
  /// If none is specified, all items will be returned.
  ///
  /// To specify the order of the items use [orderBy] or [orderByList]
  /// when sorting by multiple columns.
  ///
  /// The maximum number of items can be set by [limit]. If no limit is set,
  /// all items matching the query will be returned.
  ///
  /// [offset] defines how many items to skip, after which [limit] (or all)
  /// items are read from the database.
  ///
  /// ```dart
  /// var persons = await Persons.db.find(
  ///   session,
  ///   where: (t) => t.lastName.equals('Jones'),
  ///   orderBy: (t) => t.firstName,
  ///   limit: 100,
  /// );
  /// ```
  Future<List<Resident>> find(
    _i1.Session session, {
    _i1.WhereExpressionBuilder<ResidentTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<ResidentTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<ResidentTable>? orderByList,
    _i1.Transaction? transaction,
  }) async {
    return session.db.find<Resident>(
      where: where?.call(Resident.t),
      orderBy: orderBy?.call(Resident.t),
      orderByList: orderByList?.call(Resident.t),
      orderDescending: orderDescending,
      limit: limit,
      offset: offset,
      transaction: transaction,
    );
  }

  /// Returns the first matching [Resident] matching the given query parameters.
  ///
  /// Use [where] to specify which items to include in the return value.
  /// If none is specified, all items will be returned.
  ///
  /// To specify the order use [orderBy] or [orderByList]
  /// when sorting by multiple columns.
  ///
  /// [offset] defines how many items to skip, after which the next one will be picked.
  ///
  /// ```dart
  /// var youngestPerson = await Persons.db.findFirstRow(
  ///   session,
  ///   where: (t) => t.lastName.equals('Jones'),
  ///   orderBy: (t) => t.age,
  /// );
  /// ```
  Future<Resident?> findFirstRow(
    _i1.Session session, {
    _i1.WhereExpressionBuilder<ResidentTable>? where,
    int? offset,
    _i1.OrderByBuilder<ResidentTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<ResidentTable>? orderByList,
    _i1.Transaction? transaction,
  }) async {
    return session.db.findFirstRow<Resident>(
      where: where?.call(Resident.t),
      orderBy: orderBy?.call(Resident.t),
      orderByList: orderByList?.call(Resident.t),
      orderDescending: orderDescending,
      offset: offset,
      transaction: transaction,
    );
  }

  /// Finds a single [Resident] by its [id] or null if no such row exists.
  Future<Resident?> findById(
    _i1.Session session,
    int id, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.findById<Resident>(
      id,
      transaction: transaction,
    );
  }

  /// Inserts all [Resident]s in the list and returns the inserted rows.
  ///
  /// The returned [Resident]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// insert, none of the rows will be inserted.
  Future<List<Resident>> insert(
    _i1.Session session,
    List<Resident> rows, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.insert<Resident>(
      rows,
      transaction: transaction,
    );
  }

  /// Inserts a single [Resident] and returns the inserted row.
  ///
  /// The returned [Resident] will have its `id` field set.
  Future<Resident> insertRow(
    _i1.Session session,
    Resident row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.insertRow<Resident>(
      row,
      transaction: transaction,
    );
  }

  /// Updates all [Resident]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  Future<List<Resident>> update(
    _i1.Session session,
    List<Resident> rows, {
    _i1.ColumnSelections<ResidentTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.update<Resident>(
      rows,
      columns: columns?.call(Resident.t),
      transaction: transaction,
    );
  }

  /// Updates a single [Resident]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<Resident> updateRow(
    _i1.Session session,
    Resident row, {
    _i1.ColumnSelections<ResidentTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateRow<Resident>(
      row,
      columns: columns?.call(Resident.t),
      transaction: transaction,
    );
  }

  /// Updates a single [Resident] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<Resident?> updateById(
    _i1.Session session,
    int id, {
    required _i1.ColumnValueListBuilder<ResidentUpdateTable> columnValues,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateById<Resident>(
      id,
      columnValues: columnValues(Resident.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [Resident]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  Future<List<Resident>> updateWhere(
    _i1.Session session, {
    required _i1.ColumnValueListBuilder<ResidentUpdateTable> columnValues,
    required _i1.WhereExpressionBuilder<ResidentTable> where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<ResidentTable>? orderBy,
    _i1.OrderByListBuilder<ResidentTable>? orderByList,
    bool orderDescending = false,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateWhere<Resident>(
      columnValues: columnValues(Resident.t.updateTable),
      where: where(Resident.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(Resident.t),
      orderByList: orderByList?.call(Resident.t),
      orderDescending: orderDescending,
      transaction: transaction,
    );
  }

  /// Deletes all [Resident]s in the list and returns the deleted rows.
  /// This is an atomic operation, meaning that if one of the rows fail to
  /// be deleted, none of the rows will be deleted.
  Future<List<Resident>> delete(
    _i1.Session session,
    List<Resident> rows, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.delete<Resident>(
      rows,
      transaction: transaction,
    );
  }

  /// Deletes a single [Resident].
  Future<Resident> deleteRow(
    _i1.Session session,
    Resident row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteRow<Resident>(
      row,
      transaction: transaction,
    );
  }

  /// Deletes all rows matching the [where] expression.
  Future<List<Resident>> deleteWhere(
    _i1.Session session, {
    required _i1.WhereExpressionBuilder<ResidentTable> where,
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteWhere<Resident>(
      where: where(Resident.t),
      transaction: transaction,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _i1.Session session, {
    _i1.WhereExpressionBuilder<ResidentTable>? where,
    int? limit,
    _i1.Transaction? transaction,
  }) async {
    return session.db.count<Resident>(
      where: where?.call(Resident.t),
      limit: limit,
      transaction: transaction,
    );
  }
}
