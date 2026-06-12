// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'blocked_contracts.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$BlockedRouteDecision {

 String get blockedBy; String get artifactRoute; List<String> get nextActions;
/// Create a copy of BlockedRouteDecision
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BlockedRouteDecisionCopyWith<BlockedRouteDecision> get copyWith => _$BlockedRouteDecisionCopyWithImpl<BlockedRouteDecision>(this as BlockedRouteDecision, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BlockedRouteDecision&&(identical(other.blockedBy, blockedBy) || other.blockedBy == blockedBy)&&(identical(other.artifactRoute, artifactRoute) || other.artifactRoute == artifactRoute)&&const DeepCollectionEquality().equals(other.nextActions, nextActions));
}


@override
int get hashCode => Object.hash(runtimeType,blockedBy,artifactRoute,const DeepCollectionEquality().hash(nextActions));

@override
String toString() {
  return 'BlockedRouteDecision(blockedBy: $blockedBy, artifactRoute: $artifactRoute, nextActions: $nextActions)';
}


}

/// @nodoc
abstract mixin class $BlockedRouteDecisionCopyWith<$Res>  {
  factory $BlockedRouteDecisionCopyWith(BlockedRouteDecision value, $Res Function(BlockedRouteDecision) _then) = _$BlockedRouteDecisionCopyWithImpl;
@useResult
$Res call({
 String blockedBy, String artifactRoute, List<String> nextActions
});




}
/// @nodoc
class _$BlockedRouteDecisionCopyWithImpl<$Res>
    implements $BlockedRouteDecisionCopyWith<$Res> {
  _$BlockedRouteDecisionCopyWithImpl(this._self, this._then);

  final BlockedRouteDecision _self;
  final $Res Function(BlockedRouteDecision) _then;

/// Create a copy of BlockedRouteDecision
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? blockedBy = null,Object? artifactRoute = null,Object? nextActions = null,}) {
  return _then(_self.copyWith(
blockedBy: null == blockedBy ? _self.blockedBy : blockedBy // ignore: cast_nullable_to_non_nullable
as String,artifactRoute: null == artifactRoute ? _self.artifactRoute : artifactRoute // ignore: cast_nullable_to_non_nullable
as String,nextActions: null == nextActions ? _self.nextActions : nextActions // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}

}


/// Adds pattern-matching-related methods to [BlockedRouteDecision].
extension BlockedRouteDecisionPatterns on BlockedRouteDecision {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BlockedRouteDecision value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BlockedRouteDecision() when $default != null:
return $default(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BlockedRouteDecision value)  $default,){
final _that = this;
switch (_that) {
case _BlockedRouteDecision():
return $default(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BlockedRouteDecision value)?  $default,){
final _that = this;
switch (_that) {
case _BlockedRouteDecision() when $default != null:
return $default(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String blockedBy,  String artifactRoute,  List<String> nextActions)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BlockedRouteDecision() when $default != null:
return $default(_that.blockedBy,_that.artifactRoute,_that.nextActions);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String blockedBy,  String artifactRoute,  List<String> nextActions)  $default,) {final _that = this;
switch (_that) {
case _BlockedRouteDecision():
return $default(_that.blockedBy,_that.artifactRoute,_that.nextActions);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String blockedBy,  String artifactRoute,  List<String> nextActions)?  $default,) {final _that = this;
switch (_that) {
case _BlockedRouteDecision() when $default != null:
return $default(_that.blockedBy,_that.artifactRoute,_that.nextActions);case _:
  return null;

}
}

}

/// @nodoc


class _BlockedRouteDecision implements BlockedRouteDecision {
  const _BlockedRouteDecision({required this.blockedBy, required this.artifactRoute, required final  List<String> nextActions}): _nextActions = nextActions;
  

@override final  String blockedBy;
@override final  String artifactRoute;
 final  List<String> _nextActions;
@override List<String> get nextActions {
  if (_nextActions is EqualUnmodifiableListView) return _nextActions;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_nextActions);
}


/// Create a copy of BlockedRouteDecision
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BlockedRouteDecisionCopyWith<_BlockedRouteDecision> get copyWith => __$BlockedRouteDecisionCopyWithImpl<_BlockedRouteDecision>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _BlockedRouteDecision&&(identical(other.blockedBy, blockedBy) || other.blockedBy == blockedBy)&&(identical(other.artifactRoute, artifactRoute) || other.artifactRoute == artifactRoute)&&const DeepCollectionEquality().equals(other._nextActions, _nextActions));
}


@override
int get hashCode => Object.hash(runtimeType,blockedBy,artifactRoute,const DeepCollectionEquality().hash(_nextActions));

@override
String toString() {
  return 'BlockedRouteDecision(blockedBy: $blockedBy, artifactRoute: $artifactRoute, nextActions: $nextActions)';
}


}

/// @nodoc
abstract mixin class _$BlockedRouteDecisionCopyWith<$Res> implements $BlockedRouteDecisionCopyWith<$Res> {
  factory _$BlockedRouteDecisionCopyWith(_BlockedRouteDecision value, $Res Function(_BlockedRouteDecision) _then) = __$BlockedRouteDecisionCopyWithImpl;
@override @useResult
$Res call({
 String blockedBy, String artifactRoute, List<String> nextActions
});




}
/// @nodoc
class __$BlockedRouteDecisionCopyWithImpl<$Res>
    implements _$BlockedRouteDecisionCopyWith<$Res> {
  __$BlockedRouteDecisionCopyWithImpl(this._self, this._then);

  final _BlockedRouteDecision _self;
  final $Res Function(_BlockedRouteDecision) _then;

/// Create a copy of BlockedRouteDecision
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? blockedBy = null,Object? artifactRoute = null,Object? nextActions = null,}) {
  return _then(_BlockedRouteDecision(
blockedBy: null == blockedBy ? _self.blockedBy : blockedBy // ignore: cast_nullable_to_non_nullable
as String,artifactRoute: null == artifactRoute ? _self.artifactRoute : artifactRoute // ignore: cast_nullable_to_non_nullable
as String,nextActions: null == nextActions ? _self._nextActions : nextActions // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}


}

// dart format on
