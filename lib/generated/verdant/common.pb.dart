// This is a generated file - do not edit.
//
// Generated from verdant/common.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

/// Snowflake ID — stored as string because JS can't handle u64 natively.
/// Rust side: parse to i64, client side: treat as opaque string.
class Snowflake extends $pb.GeneratedMessage {
  factory Snowflake({
    $core.String? id,
  }) {
    final result = create();
    if (id != null) result.id = id;
    return result;
  }

  Snowflake._();

  factory Snowflake.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory Snowflake.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Snowflake',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'verdant'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'id')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Snowflake clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Snowflake copyWith(void Function(Snowflake) updates) =>
      super.copyWith((message) => updates(message as Snowflake)) as Snowflake;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static Snowflake create() => Snowflake._();
  @$core.override
  Snowflake createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static Snowflake getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Snowflake>(create);
  static Snowflake? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get id => $_getSZ(0);
  @$pb.TagNumber(1)
  set id($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => $_clearField(1);
}

/// ISO-8601 timestamp string (matches existing JSON format).
class Timestamp extends $pb.GeneratedMessage {
  factory Timestamp({
    $core.String? iso,
  }) {
    final result = create();
    if (iso != null) result.iso = iso;
    return result;
  }

  Timestamp._();

  factory Timestamp.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory Timestamp.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Timestamp',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'verdant'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'iso')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Timestamp clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Timestamp copyWith(void Function(Timestamp) updates) =>
      super.copyWith((message) => updates(message as Timestamp)) as Timestamp;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static Timestamp create() => Timestamp._();
  @$core.override
  Timestamp createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static Timestamp getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Timestamp>(create);
  static Timestamp? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get iso => $_getSZ(0);
  @$pb.TagNumber(1)
  set iso($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasIso() => $_has(0);
  @$pb.TagNumber(1)
  void clearIso() => $_clearField(1);
}

enum OptionalString_Value { str, notSet }

/// Reusable nullable string wrapper (proto3 has no null).
class OptionalString extends $pb.GeneratedMessage {
  factory OptionalString({
    $core.String? str,
  }) {
    final result = create();
    if (str != null) result.str = str;
    return result;
  }

  OptionalString._();

  factory OptionalString.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory OptionalString.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static const $core.Map<$core.int, OptionalString_Value>
      _OptionalString_ValueByTag = {
    1: OptionalString_Value.str,
    0: OptionalString_Value.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'OptionalString',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'verdant'),
      createEmptyInstance: create)
    ..oo(0, [1])
    ..aOS(1, _omitFieldNames ? '' : 'str')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  OptionalString clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  OptionalString copyWith(void Function(OptionalString) updates) =>
      super.copyWith((message) => updates(message as OptionalString))
          as OptionalString;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static OptionalString create() => OptionalString._();
  @$core.override
  OptionalString createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static OptionalString getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<OptionalString>(create);
  static OptionalString? _defaultInstance;

  @$pb.TagNumber(1)
  OptionalString_Value whichValue() =>
      _OptionalString_ValueByTag[$_whichOneof(0)]!;
  @$pb.TagNumber(1)
  void clearValue() => $_clearField($_whichOneof(0));

  @$pb.TagNumber(1)
  $core.String get str => $_getSZ(0);
  @$pb.TagNumber(1)
  set str($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasStr() => $_has(0);
  @$pb.TagNumber(1)
  void clearStr() => $_clearField(1);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
