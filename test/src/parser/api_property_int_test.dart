// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library api_property_int_tests;

import 'dart:mirrors';

import 'package:rpc/rpc.dart';
import 'package:rpc/src/config.dart';
import 'package:rpc/src/parser.dart';
import 'package:rpc/src/discovery/config.dart' as discovery;
import 'package:test/test.dart';

class CorrectInt {
  int anInt;

  @ApiProperty(name: 'anotherName', description: 'Description of an integer.')
  int aNamedInt;

  @ApiProperty(defaultValue: 42)
  int anIntWithDefault;

  @ApiProperty(required: true)
  int aRequiredInt;

  @ApiProperty(minValue: 0, maxValue: 2, defaultValue: 1)
  int aBoundedInt;

  @ApiProperty(
      format: 'int32',
      minValue: -0x80000000, // -2^31
      maxValue: 0x7FFFFFFF, // 2^31-1,
      defaultValue: -0x80000000)
  int aBoundedInt32;

  @ApiProperty(
      format: 'uint32',
      minValue: 0,
      maxValue: 0xFFFFFFFF, // 2^32-1,
      defaultValue: 0xFFFFFFFF)
  int aBoundedUInt32;

  @ApiProperty(ignore: true)
  int ignored;
}

class WrongInt {
  @ApiProperty(values: const {'enumKey': 'enumValue'})
  int anIntWithEnumValues;

  @ApiProperty(minValue: 0, maxValue: 2, defaultValue: 3)
  int aBoundedIntWithTooHighDefault;

  @ApiProperty(minValue: 0, maxValue: 2, defaultValue: -1)
  int aBoundedIntWithTooLowDefault;

  @ApiProperty(minValue: 2, maxValue: 0)
  int aBoundedIntWithMaxLessThanMin;

  @ApiProperty(
      format: 'int32',
      minValue: -0x80000001, // -2^31-1
      maxValue: 0x7FFFFFFF, // 2^31-1,
      defaultValue: 0x7FFFFFFF)
  int anInt32TooSmallMin;

  @ApiProperty(
      format: 'int32',
      minValue: -0x80000000, // -2^31
      maxValue: 0x80000000, // 2^31,
      defaultValue: 0x80000000)
  int anInt32TooLargeMax;

  @ApiProperty(
      format: 'int32',
      minValue: -0x80000000, // -2^31
      maxValue: 0x7FFFFFFF, // 2^31-1,
      defaultValue: 0x80000000)
  int anInt32TooLargeDefault;

  @ApiProperty(
      format: 'int32',
      minValue: -0x80000000, // -2^31
      maxValue: 0x7FFFFFFF, // 2^31-1,
      defaultValue: -0x80000001)
  int anInt32TooSmallDefault;

  @ApiProperty(
      format: 'uint32',
      minValue: -1,
      maxValue: 0xFFFFFFFF, // 2^32-1,
      defaultValue: 0xFFFFFFFF)
  int anUInt32TooSmallMin;

  @ApiProperty(
      format: 'uint32',
      minValue: 0,
      maxValue: 0x100000000, // 2^32,
      defaultValue: 0xFFFFFFFF)
  int anUInt32TooLargeMax;

  @ApiProperty(
      format: 'uint32',
      minValue: 0,
      maxValue: 0xFFFFFFFF, // 2^32-1,
      defaultValue: 0x100000000) // 2^32
  int anUInt32TooLargeDefault;

  @ApiProperty(
      format: 'uint32',
      minValue: 0,
      maxValue: 0xFFFFFFFF, // 2^32-1,
      defaultValue: -1)
  int anUInt32TooSmallDefault;
}

final ApiConfigSchema jsonSchema =
    new ApiParser().parseSchema(reflectClass(discovery.JsonSchema), false);

void main() {
  group('api-integer-property-correct', () {
    test('simple', () {
      var parser = new ApiParser();
      ApiConfigSchema apiSchema =
          parser.parseSchema(reflectClass(CorrectInt), true);
      expect(parser.isValid, isTrue);
      expect(parser.apiSchemas.length, 1);
      expect(parser.apiSchemas['CorrectInt'], apiSchema);
      var json = jsonSchema.toResponse(apiSchema.asDiscovery);
      var expectedJson = {
        'id': 'CorrectInt',
        'type': 'object',
        'properties': {
          'anInt': {'type': 'integer', 'format': 'int32'},
          'anotherName': {
            'type': 'integer',
            'description': 'Description of an integer.',
            'format': 'int32'
          },
          'anIntWithDefault': {
            'type': 'integer',
            'default': '42',
            'format': 'int32'
          },
          'aRequiredInt': {
            'type': 'integer',
            'required': true,
            'format': 'int32'
          },
          'aBoundedInt': {
            'type': 'integer',
            'default': '1',
            'format': 'int32',
            'minimum': '0',
            'maximum': '2'
          },
          'aBoundedInt32': {
            'type': 'integer',
            'default': '-2147483648',
            'format': 'int32',
            'minimum': '-2147483648',
            'maximum': '2147483647'
          },
          'aBoundedUInt32': {
            'type': 'integer',
            'default': '4294967295',
            'format': 'uint32',
            'minimum': '0',
            'maximum': '4294967295'
          },
        }
      };
      expect(json, expectedJson);
    });
  });

  group('api-integer-property-wrong', () {
    test('simple', () {
      var parser = new ApiParser();
      parser.parseSchema(reflectClass(WrongInt), true);
      expect(parser.isValid, isFalse);
      var expectedErrors = [
        new ApiConfigError('WrongInt: anIntWithEnumValues: Invalid property '
            'annotation. Property of type integer does not support the '
            'ApiProperty field: values'),
        new ApiConfigError(
            'WrongInt: aBoundedIntWithTooHighDefault: Default value must be '
            '<= 2.'),
        new ApiConfigError(
            'WrongInt: aBoundedIntWithTooLowDefault: Default value must be '
            '>= 0.'),
        new ApiConfigError(
            'WrongInt: aBoundedIntWithMaxLessThanMin: Invalid min/max range: '
            '[2, 0]. Min must be less than max.'),
        new ApiConfigError(
            'WrongInt: anInt32TooSmallMin: Min value: \'-2147483649\' not in '
            'the range of an \'int32\''),
        new ApiConfigError(
            'WrongInt: anInt32TooLargeMax: Max value: \'2147483648\' not in '
            'the range of an \'int32\''),
        new ApiConfigError(
            'WrongInt: anInt32TooLargeDefault: Default value: \'2147483648\' '
            'not in the range of an \'int32\''),
        new ApiConfigError(
            'WrongInt: anInt32TooSmallDefault: Default value: \'-2147483649\' '
            'not in the range of an \'int32\''),
        new ApiConfigError(
            'WrongInt: anUInt32TooSmallMin: Min value: \'-1\' not in the range '
            'of an \'uint32\''),
        new ApiConfigError(
            'WrongInt: anUInt32TooLargeMax: Max value: \'4294967296\' not in '
            'the range of an \'uint32\''),
        new ApiConfigError(
            'WrongInt: anUInt32TooLargeDefault: Default value: \'4294967296\' '
            'not in the range of an \'uint32\''),
        new ApiConfigError(
            'WrongInt: anUInt32TooSmallDefault: Default value: \'-1\' not in '
            'the range of an \'uint32\''),
      ];
      expect(parser.errors.toString(), expectedErrors.toString());
    });
  });
}
