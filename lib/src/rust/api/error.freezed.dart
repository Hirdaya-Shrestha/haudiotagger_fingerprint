// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'error.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$FingerprintError {
  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is FingerprintError);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() {
    return 'FingerprintError()';
  }
}

/// @nodoc
class $FingerprintErrorCopyWith<$Res> {
  $FingerprintErrorCopyWith(
      FingerprintError _, $Res Function(FingerprintError) __);
}

/// Adds pattern-matching-related methods to [FingerprintError].
extension FingerprintErrorPatterns on FingerprintError {
  /// A variant of `map` that fallback to returning `orElse`.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case _:
  ///     return orElse();
  /// }
  /// ```

  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(FingerprintError_OpenFile value)? openFile,
    TResult Function(FingerprintError_Decode value)? decode,
    TResult Function(FingerprintError_Unsupported value)? unsupported,
    TResult Function(FingerprintError_Fingerprint value)? fingerprint,
    TResult Function(FingerprintError_Cancelled value)? cancelled,
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case FingerprintError_OpenFile() when openFile != null:
        return openFile(_that);
      case FingerprintError_Decode() when decode != null:
        return decode(_that);
      case FingerprintError_Unsupported() when unsupported != null:
        return unsupported(_that);
      case FingerprintError_Fingerprint() when fingerprint != null:
        return fingerprint(_that);
      case FingerprintError_Cancelled() when cancelled != null:
        return cancelled(_that);
      case _:
        return orElse();
    }
  }

  /// A `switch`-like method, using callbacks.
  ///
  /// Callbacks receives the raw object, upcasted.
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case final Subclass2 value:
  ///     return ...;
  /// }
  /// ```

  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(FingerprintError_OpenFile value) openFile,
    required TResult Function(FingerprintError_Decode value) decode,
    required TResult Function(FingerprintError_Unsupported value) unsupported,
    required TResult Function(FingerprintError_Fingerprint value) fingerprint,
    required TResult Function(FingerprintError_Cancelled value) cancelled,
  }) {
    final _that = this;
    switch (_that) {
      case FingerprintError_OpenFile():
        return openFile(_that);
      case FingerprintError_Decode():
        return decode(_that);
      case FingerprintError_Unsupported():
        return unsupported(_that);
      case FingerprintError_Fingerprint():
        return fingerprint(_that);
      case FingerprintError_Cancelled():
        return cancelled(_that);
    }
  }

  /// A variant of `map` that fallback to returning `null`.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case _:
  ///     return null;
  /// }
  /// ```

  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(FingerprintError_OpenFile value)? openFile,
    TResult? Function(FingerprintError_Decode value)? decode,
    TResult? Function(FingerprintError_Unsupported value)? unsupported,
    TResult? Function(FingerprintError_Fingerprint value)? fingerprint,
    TResult? Function(FingerprintError_Cancelled value)? cancelled,
  }) {
    final _that = this;
    switch (_that) {
      case FingerprintError_OpenFile() when openFile != null:
        return openFile(_that);
      case FingerprintError_Decode() when decode != null:
        return decode(_that);
      case FingerprintError_Unsupported() when unsupported != null:
        return unsupported(_that);
      case FingerprintError_Fingerprint() when fingerprint != null:
        return fingerprint(_that);
      case FingerprintError_Cancelled() when cancelled != null:
        return cancelled(_that);
      case _:
        return null;
    }
  }

  /// A variant of `when` that fallback to an `orElse` callback.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case _:
  ///     return orElse();
  /// }
  /// ```

  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String message)? openFile,
    TResult Function(String message)? decode,
    TResult Function(String message)? unsupported,
    TResult Function(String message)? fingerprint,
    TResult Function()? cancelled,
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case FingerprintError_OpenFile() when openFile != null:
        return openFile(_that.message);
      case FingerprintError_Decode() when decode != null:
        return decode(_that.message);
      case FingerprintError_Unsupported() when unsupported != null:
        return unsupported(_that.message);
      case FingerprintError_Fingerprint() when fingerprint != null:
        return fingerprint(_that.message);
      case FingerprintError_Cancelled() when cancelled != null:
        return cancelled();
      case _:
        return orElse();
    }
  }

  /// A `switch`-like method, using callbacks.
  ///
  /// As opposed to `map`, this offers destructuring.
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case Subclass2(:final field2):
  ///     return ...;
  /// }
  /// ```

  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String message) openFile,
    required TResult Function(String message) decode,
    required TResult Function(String message) unsupported,
    required TResult Function(String message) fingerprint,
    required TResult Function() cancelled,
  }) {
    final _that = this;
    switch (_that) {
      case FingerprintError_OpenFile():
        return openFile(_that.message);
      case FingerprintError_Decode():
        return decode(_that.message);
      case FingerprintError_Unsupported():
        return unsupported(_that.message);
      case FingerprintError_Fingerprint():
        return fingerprint(_that.message);
      case FingerprintError_Cancelled():
        return cancelled();
    }
  }

  /// A variant of `when` that fallback to returning `null`
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case _:
  ///     return null;
  /// }
  /// ```

  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String message)? openFile,
    TResult? Function(String message)? decode,
    TResult? Function(String message)? unsupported,
    TResult? Function(String message)? fingerprint,
    TResult? Function()? cancelled,
  }) {
    final _that = this;
    switch (_that) {
      case FingerprintError_OpenFile() when openFile != null:
        return openFile(_that.message);
      case FingerprintError_Decode() when decode != null:
        return decode(_that.message);
      case FingerprintError_Unsupported() when unsupported != null:
        return unsupported(_that.message);
      case FingerprintError_Fingerprint() when fingerprint != null:
        return fingerprint(_that.message);
      case FingerprintError_Cancelled() when cancelled != null:
        return cancelled();
      case _:
        return null;
    }
  }
}

/// @nodoc

class FingerprintError_OpenFile extends FingerprintError {
  const FingerprintError_OpenFile({required this.message}) : super._();

  final String message;

  /// Create a copy of FingerprintError
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $FingerprintError_OpenFileCopyWith<FingerprintError_OpenFile> get copyWith =>
      _$FingerprintError_OpenFileCopyWithImpl<FingerprintError_OpenFile>(
          this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is FingerprintError_OpenFile &&
            (identical(other.message, message) || other.message == message));
  }

  @override
  int get hashCode {
    return Object.hash(runtimeType, message);
  }

  @override
  String toString() {
    return 'FingerprintError.openFile(message: $message)';
  }
}

/// @nodoc
abstract mixin class $FingerprintError_OpenFileCopyWith<$Res>
    implements $FingerprintErrorCopyWith<$Res> {
  factory $FingerprintError_OpenFileCopyWith(FingerprintError_OpenFile value,
          $Res Function(FingerprintError_OpenFile) _then) =
      _$FingerprintError_OpenFileCopyWithImpl;
  @useResult
  $Res call({String message});
}

/// @nodoc
class _$FingerprintError_OpenFileCopyWithImpl<$Res>
    implements $FingerprintError_OpenFileCopyWith<$Res> {
  _$FingerprintError_OpenFileCopyWithImpl(this._self, this._then);

  final FingerprintError_OpenFile _self;
  final $Res Function(FingerprintError_OpenFile) _then;

  /// Create a copy of FingerprintError
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  $Res call({
    Object? message = null,
  }) {
    return _then(FingerprintError_OpenFile(
      message: null == message
          ? _self.message
          : message // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc

class FingerprintError_Decode extends FingerprintError {
  const FingerprintError_Decode({required this.message}) : super._();

  final String message;

  /// Create a copy of FingerprintError
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $FingerprintError_DecodeCopyWith<FingerprintError_Decode> get copyWith =>
      _$FingerprintError_DecodeCopyWithImpl<FingerprintError_Decode>(
          this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is FingerprintError_Decode &&
            (identical(other.message, message) || other.message == message));
  }

  @override
  int get hashCode {
    return Object.hash(runtimeType, message);
  }

  @override
  String toString() {
    return 'FingerprintError.decode(message: $message)';
  }
}

/// @nodoc
abstract mixin class $FingerprintError_DecodeCopyWith<$Res>
    implements $FingerprintErrorCopyWith<$Res> {
  factory $FingerprintError_DecodeCopyWith(FingerprintError_Decode value,
          $Res Function(FingerprintError_Decode) _then) =
      _$FingerprintError_DecodeCopyWithImpl;
  @useResult
  $Res call({String message});
}

/// @nodoc
class _$FingerprintError_DecodeCopyWithImpl<$Res>
    implements $FingerprintError_DecodeCopyWith<$Res> {
  _$FingerprintError_DecodeCopyWithImpl(this._self, this._then);

  final FingerprintError_Decode _self;
  final $Res Function(FingerprintError_Decode) _then;

  /// Create a copy of FingerprintError
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  $Res call({
    Object? message = null,
  }) {
    return _then(FingerprintError_Decode(
      message: null == message
          ? _self.message
          : message // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc

class FingerprintError_Unsupported extends FingerprintError {
  const FingerprintError_Unsupported({required this.message}) : super._();

  final String message;

  /// Create a copy of FingerprintError
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $FingerprintError_UnsupportedCopyWith<FingerprintError_Unsupported>
      get copyWith => _$FingerprintError_UnsupportedCopyWithImpl<
          FingerprintError_Unsupported>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is FingerprintError_Unsupported &&
            (identical(other.message, message) || other.message == message));
  }

  @override
  int get hashCode {
    return Object.hash(runtimeType, message);
  }

  @override
  String toString() {
    return 'FingerprintError.unsupported(message: $message)';
  }
}

/// @nodoc
abstract mixin class $FingerprintError_UnsupportedCopyWith<$Res>
    implements $FingerprintErrorCopyWith<$Res> {
  factory $FingerprintError_UnsupportedCopyWith(
          FingerprintError_Unsupported value,
          $Res Function(FingerprintError_Unsupported) _then) =
      _$FingerprintError_UnsupportedCopyWithImpl;
  @useResult
  $Res call({String message});
}

/// @nodoc
class _$FingerprintError_UnsupportedCopyWithImpl<$Res>
    implements $FingerprintError_UnsupportedCopyWith<$Res> {
  _$FingerprintError_UnsupportedCopyWithImpl(this._self, this._then);

  final FingerprintError_Unsupported _self;
  final $Res Function(FingerprintError_Unsupported) _then;

  /// Create a copy of FingerprintError
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  $Res call({
    Object? message = null,
  }) {
    return _then(FingerprintError_Unsupported(
      message: null == message
          ? _self.message
          : message // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc

class FingerprintError_Fingerprint extends FingerprintError {
  const FingerprintError_Fingerprint({required this.message}) : super._();

  final String message;

  /// Create a copy of FingerprintError
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $FingerprintError_FingerprintCopyWith<FingerprintError_Fingerprint>
      get copyWith => _$FingerprintError_FingerprintCopyWithImpl<
          FingerprintError_Fingerprint>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is FingerprintError_Fingerprint &&
            (identical(other.message, message) || other.message == message));
  }

  @override
  int get hashCode {
    return Object.hash(runtimeType, message);
  }

  @override
  String toString() {
    return 'FingerprintError.fingerprint(message: $message)';
  }
}

/// @nodoc
abstract mixin class $FingerprintError_FingerprintCopyWith<$Res>
    implements $FingerprintErrorCopyWith<$Res> {
  factory $FingerprintError_FingerprintCopyWith(
          FingerprintError_Fingerprint value,
          $Res Function(FingerprintError_Fingerprint) _then) =
      _$FingerprintError_FingerprintCopyWithImpl;
  @useResult
  $Res call({String message});
}

/// @nodoc
class _$FingerprintError_FingerprintCopyWithImpl<$Res>
    implements $FingerprintError_FingerprintCopyWith<$Res> {
  _$FingerprintError_FingerprintCopyWithImpl(this._self, this._then);

  final FingerprintError_Fingerprint _self;
  final $Res Function(FingerprintError_Fingerprint) _then;

  /// Create a copy of FingerprintError
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  $Res call({
    Object? message = null,
  }) {
    return _then(FingerprintError_Fingerprint(
      message: null == message
          ? _self.message
          : message // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc

class FingerprintError_Cancelled extends FingerprintError {
  const FingerprintError_Cancelled() : super._();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is FingerprintError_Cancelled);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() {
    return 'FingerprintError.cancelled()';
  }
}

// dart format on
