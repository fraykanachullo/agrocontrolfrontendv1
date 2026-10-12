// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'exceptions.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$ServerException {
  String get message => throw _privateConstructorUsedError;
  int? get statusCode => throw _privateConstructorUsedError;

  /// Create a copy of ServerException
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ServerExceptionCopyWith<ServerException> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ServerExceptionCopyWith<$Res> {
  factory $ServerExceptionCopyWith(
    ServerException value,
    $Res Function(ServerException) then,
  ) = _$ServerExceptionCopyWithImpl<$Res, ServerException>;
  @useResult
  $Res call({String message, int? statusCode});
}

/// @nodoc
class _$ServerExceptionCopyWithImpl<$Res, $Val extends ServerException>
    implements $ServerExceptionCopyWith<$Res> {
  _$ServerExceptionCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ServerException
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? message = null, Object? statusCode = freezed}) {
    return _then(
      _value.copyWith(
            message: null == message
                ? _value.message
                : message // ignore: cast_nullable_to_non_nullable
                      as String,
            statusCode: freezed == statusCode
                ? _value.statusCode
                : statusCode // ignore: cast_nullable_to_non_nullable
                      as int?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$ServerExceptionImplCopyWith<$Res>
    implements $ServerExceptionCopyWith<$Res> {
  factory _$$ServerExceptionImplCopyWith(
    _$ServerExceptionImpl value,
    $Res Function(_$ServerExceptionImpl) then,
  ) = __$$ServerExceptionImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String message, int? statusCode});
}

/// @nodoc
class __$$ServerExceptionImplCopyWithImpl<$Res>
    extends _$ServerExceptionCopyWithImpl<$Res, _$ServerExceptionImpl>
    implements _$$ServerExceptionImplCopyWith<$Res> {
  __$$ServerExceptionImplCopyWithImpl(
    _$ServerExceptionImpl _value,
    $Res Function(_$ServerExceptionImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of ServerException
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? message = null, Object? statusCode = freezed}) {
    return _then(
      _$ServerExceptionImpl(
        message: null == message
            ? _value.message
            : message // ignore: cast_nullable_to_non_nullable
                  as String,
        statusCode: freezed == statusCode
            ? _value.statusCode
            : statusCode // ignore: cast_nullable_to_non_nullable
                  as int?,
      ),
    );
  }
}

/// @nodoc

class _$ServerExceptionImpl implements _ServerException {
  const _$ServerExceptionImpl({required this.message, this.statusCode});

  @override
  final String message;
  @override
  final int? statusCode;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ServerExceptionImpl &&
            (identical(other.message, message) || other.message == message) &&
            (identical(other.statusCode, statusCode) ||
                other.statusCode == statusCode));
  }

  @override
  int get hashCode => Object.hash(runtimeType, message, statusCode);

  /// Create a copy of ServerException
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ServerExceptionImplCopyWith<_$ServerExceptionImpl> get copyWith =>
      __$$ServerExceptionImplCopyWithImpl<_$ServerExceptionImpl>(
        this,
        _$identity,
      );
}

abstract class _ServerException implements ServerException {
  const factory _ServerException({
    required final String message,
    final int? statusCode,
  }) = _$ServerExceptionImpl;

  @override
  String get message;
  @override
  int? get statusCode;

  /// Create a copy of ServerException
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ServerExceptionImplCopyWith<_$ServerExceptionImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
mixin _$CacheException {
  String get message => throw _privateConstructorUsedError;
  int? get statusCode => throw _privateConstructorUsedError;

  /// Create a copy of CacheException
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $CacheExceptionCopyWith<CacheException> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $CacheExceptionCopyWith<$Res> {
  factory $CacheExceptionCopyWith(
    CacheException value,
    $Res Function(CacheException) then,
  ) = _$CacheExceptionCopyWithImpl<$Res, CacheException>;
  @useResult
  $Res call({String message, int? statusCode});
}

/// @nodoc
class _$CacheExceptionCopyWithImpl<$Res, $Val extends CacheException>
    implements $CacheExceptionCopyWith<$Res> {
  _$CacheExceptionCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of CacheException
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? message = null, Object? statusCode = freezed}) {
    return _then(
      _value.copyWith(
            message: null == message
                ? _value.message
                : message // ignore: cast_nullable_to_non_nullable
                      as String,
            statusCode: freezed == statusCode
                ? _value.statusCode
                : statusCode // ignore: cast_nullable_to_non_nullable
                      as int?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$CacheExceptionImplCopyWith<$Res>
    implements $CacheExceptionCopyWith<$Res> {
  factory _$$CacheExceptionImplCopyWith(
    _$CacheExceptionImpl value,
    $Res Function(_$CacheExceptionImpl) then,
  ) = __$$CacheExceptionImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String message, int? statusCode});
}

/// @nodoc
class __$$CacheExceptionImplCopyWithImpl<$Res>
    extends _$CacheExceptionCopyWithImpl<$Res, _$CacheExceptionImpl>
    implements _$$CacheExceptionImplCopyWith<$Res> {
  __$$CacheExceptionImplCopyWithImpl(
    _$CacheExceptionImpl _value,
    $Res Function(_$CacheExceptionImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of CacheException
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? message = null, Object? statusCode = freezed}) {
    return _then(
      _$CacheExceptionImpl(
        message: null == message
            ? _value.message
            : message // ignore: cast_nullable_to_non_nullable
                  as String,
        statusCode: freezed == statusCode
            ? _value.statusCode
            : statusCode // ignore: cast_nullable_to_non_nullable
                  as int?,
      ),
    );
  }
}

/// @nodoc

class _$CacheExceptionImpl implements _CacheException {
  const _$CacheExceptionImpl({
    this.message = 'Error al acceder a los datos locales.',
    this.statusCode,
  });

  @override
  @JsonKey()
  final String message;
  @override
  final int? statusCode;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CacheExceptionImpl &&
            (identical(other.message, message) || other.message == message) &&
            (identical(other.statusCode, statusCode) ||
                other.statusCode == statusCode));
  }

  @override
  int get hashCode => Object.hash(runtimeType, message, statusCode);

  /// Create a copy of CacheException
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$CacheExceptionImplCopyWith<_$CacheExceptionImpl> get copyWith =>
      __$$CacheExceptionImplCopyWithImpl<_$CacheExceptionImpl>(
        this,
        _$identity,
      );
}

abstract class _CacheException implements CacheException {
  const factory _CacheException({final String message, final int? statusCode}) =
      _$CacheExceptionImpl;

  @override
  String get message;
  @override
  int? get statusCode;

  /// Create a copy of CacheException
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$CacheExceptionImplCopyWith<_$CacheExceptionImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
mixin _$NetworkException {
  String get message => throw _privateConstructorUsedError;
  int? get statusCode => throw _privateConstructorUsedError;

  /// Create a copy of NetworkException
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $NetworkExceptionCopyWith<NetworkException> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $NetworkExceptionCopyWith<$Res> {
  factory $NetworkExceptionCopyWith(
    NetworkException value,
    $Res Function(NetworkException) then,
  ) = _$NetworkExceptionCopyWithImpl<$Res, NetworkException>;
  @useResult
  $Res call({String message, int? statusCode});
}

/// @nodoc
class _$NetworkExceptionCopyWithImpl<$Res, $Val extends NetworkException>
    implements $NetworkExceptionCopyWith<$Res> {
  _$NetworkExceptionCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of NetworkException
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? message = null, Object? statusCode = freezed}) {
    return _then(
      _value.copyWith(
            message: null == message
                ? _value.message
                : message // ignore: cast_nullable_to_non_nullable
                      as String,
            statusCode: freezed == statusCode
                ? _value.statusCode
                : statusCode // ignore: cast_nullable_to_non_nullable
                      as int?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$NetworkExceptionImplCopyWith<$Res>
    implements $NetworkExceptionCopyWith<$Res> {
  factory _$$NetworkExceptionImplCopyWith(
    _$NetworkExceptionImpl value,
    $Res Function(_$NetworkExceptionImpl) then,
  ) = __$$NetworkExceptionImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String message, int? statusCode});
}

/// @nodoc
class __$$NetworkExceptionImplCopyWithImpl<$Res>
    extends _$NetworkExceptionCopyWithImpl<$Res, _$NetworkExceptionImpl>
    implements _$$NetworkExceptionImplCopyWith<$Res> {
  __$$NetworkExceptionImplCopyWithImpl(
    _$NetworkExceptionImpl _value,
    $Res Function(_$NetworkExceptionImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of NetworkException
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? message = null, Object? statusCode = freezed}) {
    return _then(
      _$NetworkExceptionImpl(
        message: null == message
            ? _value.message
            : message // ignore: cast_nullable_to_non_nullable
                  as String,
        statusCode: freezed == statusCode
            ? _value.statusCode
            : statusCode // ignore: cast_nullable_to_non_nullable
                  as int?,
      ),
    );
  }
}

/// @nodoc

class _$NetworkExceptionImpl implements _NetworkException {
  const _$NetworkExceptionImpl({
    this.message = 'Sin conexión a internet.',
    this.statusCode,
  });

  @override
  @JsonKey()
  final String message;
  @override
  final int? statusCode;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$NetworkExceptionImpl &&
            (identical(other.message, message) || other.message == message) &&
            (identical(other.statusCode, statusCode) ||
                other.statusCode == statusCode));
  }

  @override
  int get hashCode => Object.hash(runtimeType, message, statusCode);

  /// Create a copy of NetworkException
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$NetworkExceptionImplCopyWith<_$NetworkExceptionImpl> get copyWith =>
      __$$NetworkExceptionImplCopyWithImpl<_$NetworkExceptionImpl>(
        this,
        _$identity,
      );
}

abstract class _NetworkException implements NetworkException {
  const factory _NetworkException({
    final String message,
    final int? statusCode,
  }) = _$NetworkExceptionImpl;

  @override
  String get message;
  @override
  int? get statusCode;

  /// Create a copy of NetworkException
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$NetworkExceptionImplCopyWith<_$NetworkExceptionImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
mixin _$AuthException {
  String get message => throw _privateConstructorUsedError;
  int? get statusCode => throw _privateConstructorUsedError;

  /// Create a copy of AuthException
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $AuthExceptionCopyWith<AuthException> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AuthExceptionCopyWith<$Res> {
  factory $AuthExceptionCopyWith(
    AuthException value,
    $Res Function(AuthException) then,
  ) = _$AuthExceptionCopyWithImpl<$Res, AuthException>;
  @useResult
  $Res call({String message, int? statusCode});
}

/// @nodoc
class _$AuthExceptionCopyWithImpl<$Res, $Val extends AuthException>
    implements $AuthExceptionCopyWith<$Res> {
  _$AuthExceptionCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of AuthException
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? message = null, Object? statusCode = freezed}) {
    return _then(
      _value.copyWith(
            message: null == message
                ? _value.message
                : message // ignore: cast_nullable_to_non_nullable
                      as String,
            statusCode: freezed == statusCode
                ? _value.statusCode
                : statusCode // ignore: cast_nullable_to_non_nullable
                      as int?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$AuthExceptionImplCopyWith<$Res>
    implements $AuthExceptionCopyWith<$Res> {
  factory _$$AuthExceptionImplCopyWith(
    _$AuthExceptionImpl value,
    $Res Function(_$AuthExceptionImpl) then,
  ) = __$$AuthExceptionImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String message, int? statusCode});
}

/// @nodoc
class __$$AuthExceptionImplCopyWithImpl<$Res>
    extends _$AuthExceptionCopyWithImpl<$Res, _$AuthExceptionImpl>
    implements _$$AuthExceptionImplCopyWith<$Res> {
  __$$AuthExceptionImplCopyWithImpl(
    _$AuthExceptionImpl _value,
    $Res Function(_$AuthExceptionImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of AuthException
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? message = null, Object? statusCode = freezed}) {
    return _then(
      _$AuthExceptionImpl(
        message: null == message
            ? _value.message
            : message // ignore: cast_nullable_to_non_nullable
                  as String,
        statusCode: freezed == statusCode
            ? _value.statusCode
            : statusCode // ignore: cast_nullable_to_non_nullable
                  as int?,
      ),
    );
  }
}

/// @nodoc

class _$AuthExceptionImpl implements _AuthException {
  const _$AuthExceptionImpl({
    this.message = 'Sesión expirada. Inicia sesión nuevamente.',
    this.statusCode,
  });

  @override
  @JsonKey()
  final String message;
  @override
  final int? statusCode;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AuthExceptionImpl &&
            (identical(other.message, message) || other.message == message) &&
            (identical(other.statusCode, statusCode) ||
                other.statusCode == statusCode));
  }

  @override
  int get hashCode => Object.hash(runtimeType, message, statusCode);

  /// Create a copy of AuthException
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$AuthExceptionImplCopyWith<_$AuthExceptionImpl> get copyWith =>
      __$$AuthExceptionImplCopyWithImpl<_$AuthExceptionImpl>(this, _$identity);
}

abstract class _AuthException implements AuthException {
  const factory _AuthException({final String message, final int? statusCode}) =
      _$AuthExceptionImpl;

  @override
  String get message;
  @override
  int? get statusCode;

  /// Create a copy of AuthException
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$AuthExceptionImplCopyWith<_$AuthExceptionImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
