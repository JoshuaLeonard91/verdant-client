// This is a generated file - do not edit.
//
// Generated from verdant/common.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports
// ignore_for_file: unused_import

import 'dart:convert' as $convert;
import 'dart:core' as $core;
import 'dart:typed_data' as $typed_data;

@$core.Deprecated('Use snowflakeDescriptor instead')
const Snowflake$json = {
  '1': 'Snowflake',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
  ],
};

/// Descriptor for `Snowflake`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List snowflakeDescriptor =
    $convert.base64Decode('CglTbm93Zmxha2USDgoCaWQYASABKAlSAmlk');

@$core.Deprecated('Use timestampDescriptor instead')
const Timestamp$json = {
  '1': 'Timestamp',
  '2': [
    {'1': 'iso', '3': 1, '4': 1, '5': 9, '10': 'iso'},
  ],
};

/// Descriptor for `Timestamp`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List timestampDescriptor =
    $convert.base64Decode('CglUaW1lc3RhbXASEAoDaXNvGAEgASgJUgNpc28=');

@$core.Deprecated('Use optionalStringDescriptor instead')
const OptionalString$json = {
  '1': 'OptionalString',
  '2': [
    {'1': 'str', '3': 1, '4': 1, '5': 9, '9': 0, '10': 'str'},
  ],
  '8': [
    {'1': 'value'},
  ],
};

/// Descriptor for `OptionalString`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List optionalStringDescriptor = $convert.base64Decode(
    'Cg5PcHRpb25hbFN0cmluZxISCgNzdHIYASABKAlIAFIDc3RyQgcKBXZhbHVl');
