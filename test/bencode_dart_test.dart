import 'dart:convert';
import 'dart:typed_data';

import 'package:b_encode_decode/b_encode_decode.dart';
import 'package:test/test.dart';

/// All tests come from https://github.com/benjreinhart/bencode-js/blob/master/test
///
/// I just transfer JS to Dart
void main() {
  group('Tests for decoding - ', () {
    test('It with a basic value returns the string', () {
      var code = decode(stringToBytes('10:helloworld'));
      var str = (code is Uint8List) ? bytesToString(code) : code;
      assert(str == 'helloworld');
    });

    test('It with a colon in them returns the correct string', () {
      var code = decode(stringToBytes('12:0.0.0.0:3000'));
      var str = (code is Uint8List) ? bytesToString(code) : code;
      assert(str == '0.0.0.0:3000');
    });

    test('It is the integer between i and e', () {
      var code = decode(stringToBytes('i42e'));
      assert(code == 42);
    });

    test('It allows negative numbers', () {
      var code = decode(stringToBytes('i-42e'));
      assert(code == -42);
    });

    test('It allows zeros', () {
      var code = decode(stringToBytes('i0e'));
      assert(code == 0);
    });

    test('It creates a list with strings and integers', () {
      var re = decode(stringToBytes('l5:helloi42ee'));
      var c = ['hello', 42];
      assert(myEqauls(re, c));
    });

    test('It creates a list with nested lists of strings and integers', () {
      var re = decode(stringToBytes('l5:helloi42eli-1ei0ei1ei2ei3e4:fouree'));
      var c = [
        'hello',
        42,
        [-1, 0, 1, 2, 3, 'four']
      ];
      assert(myEqauls(re, c));
    });

    test('It has no problem with multiple empty lists or objects', () {
      var re = decode(stringToBytes('lllleeee'));
      var c = [
        [
          [[]]
        ]
      ];
      assert(myEqauls(re, c));

      re = decode(stringToBytes('llelelelleee'));
      var c1 = [
        [],
        [],
        [],
        [[]]
      ];
      assert(myEqauls(re, c1));

      re = decode(stringToBytes('ldededee'));
      var c2 = [{}, {}, {}];
      assert(myEqauls(re, c2));
    });

    test('It creates an object with strings and integers', () {
      var re = decode(stringToBytes('d3:agei100e4:name8:the dudee'));
      var c = {'age': 100, 'name': 'the dude'};
      assert(myEqauls(re, c));
    });

    test('It creates an object with nested objects of strings and integers',
        () {
      var re = decode(stringToBytes(
          'd3:agei100e4:infod5:email13:dude@dude.com6:numberi2488081446ee4:name8:the dudee'));
      var c = {
        'age': 100,
        'info': {'email': 'dude@dude.com', 'number': 2488081446},
        'name': 'the dude'
      };
      assert(myEqauls(re, c));
    });

    test('It has no problem with an empty object', () {
      var re = decode(stringToBytes('de'));
      var c = {};
      assert(myEqauls(re, c));
    });

    test('It creates an object with a list of objects', () {
      var re = decode(stringToBytes(
          'd9:locationsld7:address10:484 streeted7:address10:828 streeteee'));
      var c = {
        'locations': [
          {'address': '484 street'},
          {'address': '828 street'}
        ]
      };
      assert(myEqauls(re, c));
    });

    test('It has no problem when there are multiple "e"s in a row', () {
      var re = decode(stringToBytes('lld9:favoritesleeei500ee'));
      var c = [
        [
          {'favorites': []}
        ],
        500
      ];
      assert(myEqauls(re, c));
    });
  });

  // encoding:
  group('Tests for encoding - ', () {
    test('It encodes a string as <lenOfString>:<string>', () {
      var re = encode('omg hay thurrr');
      var c = '14:omg hay thurrr';
      assert(c == bytesToString(re));
    });

    test('It encodes integers as i<integer>e', () {
      var re = encode(2234);
      var c = 'i2234e';
      assert(c == bytesToString(re));
    });

    test('It encodes negative integers', () {
      var re = bytesToString(encode(-2234));
      var c = 'i-2234e';
      assert(c == re);
    });

    test('It encodes large-ish integers', () {
      var re = encode(2222222222);
      var c = 'i2222222222e';
      assert(c == bytesToString(re));
    });
    test('It encodes -0 as i0e', () {
      expect(String.fromCharCodes(encode(-0)), equals('i0e'));
    });
    test('It encodes integers with leading zeros', () {
      var re = encode(00002);
      var c = 'i2e';
      assert(c == bytesToString(re));
    });
    test('It encodes a list as l<list items>e', () {
      var re = encode(['a string', 23]);
      var c = 'l8:a stringi23ee';
      assert(c == bytesToString(re));
    });

    test('It encodes empty lists', () {
      var re = encode([]);
      var c = 'le';
      assert(c == bytesToString(re));
    });

    test('It encodes nested lists', () {
      var re = encode([
        ['james', 'john'],
        [
          ['jordin', 12]
        ]
      ]);
      var c = 'll5:james4:johnell6:jordini12eeee';
      assert(c == bytesToString(re));
    });

    test('It encodes an object as d<key><value>e where keys are sorted', () {
      var re = encode({'name': 'ben', 'age': 23});
      var c = 'd3:agei23e4:name3:bene';
      assert(c == bytesToString(re));
    });

    test('It encodes empty objects', () {
      var re = encode({});
      var c = 'de';
      assert(c == bytesToString(re));
    });

    test('It nested objects and lists', () {
      var re = encode({
        'people': [
          {'name': 'j', 'age': 20}
        ]
      });
      var c = 'd6:peopleld3:agei20e4:name1:jeee';
      assert(c == bytesToString(re));
    });
  });

  group('Edge cases and error handling', () {
    test('encode(null) returns empty Uint8List', () {
      var result = encode(null);
      expect(result, isA<Uint8List>());
      expect(result.length, 0);
    });

    test('decode(Uint8List(0)) returns null', () {
      var result = decode(Uint8List(0));
      expect(result, isNull);
    });

    test('decode throws on invalid bencode (missing delimiter)', () {
      expect(() => decode(stringToBytes('i42')), throwsA(isA<Exception>()));
      expect(() => decode(stringToBytes('5hello')), throwsA(isA<Exception>()));
    });

    test('decode throws on invalid number', () {
      expect(() => decode(stringToBytes('i4a2e')), throwsA(isA<Exception>()));
      expect(() => decode(stringToBytes('i--42e')), throwsA(isA<Exception>()));
    });

    test('decode with start/end parameters decodes subrange', () {
      var bytes = stringToBytes('i1ei2ei3e');
      // Only decode the second integer (i2e)
      var result = decode(bytes, start: 3, end: 6);
      expect(result, 2);
    });

    test('decode with invalid range throws ArgumentError', () {
      var bytes = stringToBytes('i42e');
      expect(
        () => decode(bytes, start: -1, end: 4),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        () => decode(bytes, start: 0, end: 100),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        () => decode(bytes, start: 5, end: 3),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('decode throws BencodeDecodeException with position info', () {
      try {
        decode(stringToBytes('i42'));
        fail('Should have thrown an exception');
      } catch (e) {
        expect(e, isA<BencodeDecodeException>());
        final exception = e as BencodeDecodeException;
        expect(exception.message, contains('Missing delimiter'));
        expect(exception.position, isNotNull);
      }
    });

    test('decode throws on empty integer', () {
      expect(
        () => decode(stringToBytes('ie')),
        throwsA(isA<BencodeDecodeException>()),
      );
    });

    test('decode throws on floating point number', () {
      expect(
        () => decode(stringToBytes('i3.14e')),
        throwsA(isA<BencodeDecodeException>()),
      );
      try {
        decode(stringToBytes('i3.14e'));
      } catch (e) {
        expect(e, isA<BencodeDecodeException>());
        final exception = e as BencodeDecodeException;
        expect(exception.message, contains('Floating point'));
      }
    });

    test('decode handles positive sign in integer', () {
      var result = decode(stringToBytes('i+42e'));
      expect(result, 42);
    });

    test('decode throws on negative string length', () {
      expect(
        () => decode(stringToBytes('-5:hello')),
        throwsA(isA<BencodeDecodeException>()),
      );
      try {
        decode(stringToBytes('-5:hello'));
      } catch (e) {
        expect(e, isA<BencodeDecodeException>());
        final exception = e as BencodeDecodeException;
        expect(exception.message, contains('Invalid string length'));
      }
    });

    test('decode throws when string length exceeds available data', () {
      expect(
        () => decode(stringToBytes('100:hello')),
        throwsA(isA<BencodeDecodeException>()),
      );
      try {
        decode(stringToBytes('100:hello'));
      } catch (e) {
        expect(e, isA<BencodeDecodeException>());
        final exception = e as BencodeDecodeException;
        expect(exception.message, contains('exceeds available data'));
      }
    });

    test('decode throws on incomplete dictionary', () {
      expect(
        () => decode(stringToBytes('d3:key5:value')),
        throwsA(isA<BencodeDecodeException>()),
      );
      try {
        decode(stringToBytes('d3:key5:value'));
      } catch (e) {
        expect(e, isA<BencodeDecodeException>());
        final exception = e as BencodeDecodeException;
        expect(exception.message, contains('Unexpected end of data'));
        expect(exception.message, contains('dictionary'));
      }
    });

    test('decode throws on incomplete list', () {
      expect(
        () => decode(stringToBytes('l5:hello')),
        throwsA(isA<BencodeDecodeException>()),
      );
      try {
        decode(stringToBytes('l5:hello'));
      } catch (e) {
        expect(e, isA<BencodeDecodeException>());
        final exception = e as BencodeDecodeException;
        expect(exception.message, contains('Unexpected end of data'));
        expect(exception.message, contains('list'));
      }
    });

    test('decode throws on unknown encoding', () {
      var encoded = encode('hello', 'utf-8');
      expect(
        () => decode(encoded, stringEncoding: 'unknown-encoding-12345'),
        throwsA(isA<ArgumentError>()),
      );
    });
    test('can encode infoHash', () {
      var infoHashBytes = [
        221,
        130,
        85,
        236,
        220,
        124,
        165,
        95,
        176,
        187,
        248,
        19,
        35,
        216,
        112,
        98,
        219,
        31,
        109,
        28
      ];
      var infoHashAsString = String.fromCharCodes(infoHashBytes);

      var encoded = encode(infoHashAsString);
      var decoded = decode(encoded);
      var decodeBytes = Uint8List.fromList(decoded);

      expect(infoHashBytes, equals(decodeBytes));
      expect(infoHashAsString, equals(String.fromCharCodes(decodeBytes)));
    });
    test('can encode utf8 string with stringEncoding', () {
      var str = 'gâteau';
      var encoded = encode(str, 'utf-8');
      expect(encoded, equals(stringToBytes('7:gâteau')));
      var decoded = decode(encoded, stringEncoding: 'utf-8');
      expect(str, equals(decoded));
    });

    test('can encode latin1 string with stringEncoding - byte length matches',
        () {
      // Use a string that has different byte lengths in UTF-8 vs Latin1
      // Latin1 uses 1 byte per character, UTF-8 uses 2 bytes for some characters
      var str = 'café'; // 'é' is 1 byte in Latin1, 2 bytes in UTF-8
      var encoded = encode(str, 'latin1');
      var decoded = decode(encoded, stringEncoding: 'latin1');
      expect(str, equals(decoded));

      // Verify the byte length in the encoding matches the actual data bytes
      // 'café' in Latin1 is 4 bytes, so the encoding should be "4:café" (prefix) + 4 bytes
      var latin1Encoder = Encoding.getByName('latin1')!;
      var expectedBytes = latin1Encoder.encode(str);
      expect(expectedBytes.length, equals(4));

      // The encoded result should have: "4:" (2 bytes) + 4 data bytes = 6 bytes total
      expect(encoded.length, equals(6));

      // Verify we can decode it back correctly
      expect(decoded, equals(str));
    });
  });

  group('Encoding features', () {
    test('encode bool true as i1e', () {
      var result = encode(true);
      expect(bytesToString(result), equals('i1e'));
    });

    test('encode bool false as i0e', () {
      var result = encode(false);
      expect(bytesToString(result), equals('i0e'));
    });

    test('encode Uint8List', () {
      var bytes = Uint8List.fromList([1, 2, 3, 4, 5]);
      var result = encode(bytes);
      expect(result, equals(stringToBytes('5:${String.fromCharCodes(bytes)}')));
    });

    test('encode with buffer and offset', () {
      var buffer = Uint8List(20);
      var data = {'key': 'value'};
      var encoded = encode(data, null, buffer, 5);
      expect(encoded, same(buffer));
      // Verify the data was written at offset 5
      // Need to find where the encoded data ends
      var encodedData = encode(data);
      // Decode from the buffer starting at offset 5
      var decoded = decode(buffer,
          start: 5, end: 5 + encodedData.length, stringEncoding: 'utf-8');
      expect(decoded, equals(data));
    });

    test('encode with buffer too small throws ArgumentError', () {
      var buffer = Uint8List(5);
      var data = {'key': 'value'};
      expect(
        () => encode(data, null, buffer, 0),
        throwsA(isA<ArgumentError>()),
      );
      try {
        encode(data, null, buffer, 0);
      } catch (e) {
        expect(e, isA<ArgumentError>());
        final error = e as ArgumentError;
        expect(error.message, contains('Buffer too small'));
      }
    });

    test('encode double preserves decimal representation', () {
      var result = encode(42.0);
      // Doubles are encoded with their string representation
      expect(bytesToString(result), equals('i42.0e'));
    });

    test('encode list with null values skips nulls', () {
      var result = encode([1, null, 2, null, 3]);
      expect(bytesToString(result), equals('li1ei2ei3ee'));
    });

    test('encode map with null values skips nulls', () {
      var result = encode({'a': 1, 'b': null, 'c': 2});
      expect(bytesToString(result), equals('d1:ai1e1:ci2ee'));
    });

    test('encode map keys are sorted', () {
      var result = encode({'z': 1, 'a': 2, 'm': 3});
      expect(bytesToString(result), equals('d1:ai2e1:mi3e1:zi1ee'));
    });
  });

  group('Decoding features', () {
    test('decode returns Uint8List for strings when no encoding specified', () {
      var encoded = encode('hello');
      var decoded = decode(encoded);
      expect(decoded, isA<Uint8List>());
      expect(bytesToString(decoded), equals('hello'));
    });

    test('decode returns String when encoding is specified', () {
      var encoded = encode('hello', 'utf-8');
      var decoded = decode(encoded, stringEncoding: 'utf-8');
      expect(decoded, isA<String>());
      expect(decoded, equals('hello'));
    });

    test('decode handles empty string', () {
      var encoded = encode('');
      var decoded = decode(encoded);
      expect(decoded, isA<Uint8List>());
      expect((decoded as Uint8List).length, equals(0));
    });

    test('decode handles zero integer', () {
      var result = decode(stringToBytes('i0e'));
      expect(result, equals(0));
    });

    test('decode handles large integers', () {
      var result = decode(stringToBytes('i9223372036854775807e'));
      expect(result, equals(9223372036854775807));
    });

    test('decode handles very negative integers', () {
      var result = decode(stringToBytes('i-9223372036854775808e'));
      expect(result, equals(-9223372036854775808));
    });

    test('decode with start parameter only decodes from start to end', () {
      var bytes = stringToBytes('i1ei2ei3e');
      // When only start is provided, it decodes from start to end of buffer
      // So starting at position 3 (after 'i1e') should decode 'i2e' (first complete value)
      var result = decode(bytes, start: 3);
      expect(result, equals(2));
    });

    test('decode handles nested structures deeply', () {
      var encoded = encode([
        [
          [
            {'deep': 'value'}
          ]
        ]
      ]);
      var decoded = decode(encoded);
      expect(decoded, isA<List>());
      expect((decoded as List).length, equals(1));
    });

    test('decode handles dictionary with non-UTF8 keys', () {
      // Create a dictionary with a key that's not valid UTF-8
      var bytes = Uint8List.fromList([
        100, // 'd'
        50, 58, // '2:'
        255, 255, // Invalid UTF-8 key
        49, 58, 97, // '1:a'
        101, // 'e'
      ]);
      var result = decode(bytes);
      expect(result, isA<Map>());
    });
  });

  group('BencodeDecodeException', () {
    test('BencodeDecodeException without position', () {
      var exception = BencodeDecodeException('Test error');
      expect(exception.message, equals('Test error'));
      expect(exception.position, isNull);
      expect(exception.toString(), contains('BencodeDecodeException'));
      expect(exception.toString(), contains('Test error'));
      expect(exception.toString(), isNot(contains('position')));
    });

    test('BencodeDecodeException with position', () {
      var exception = BencodeDecodeException('Test error', 42);
      expect(exception.message, equals('Test error'));
      expect(exception.position, equals(42));
      expect(exception.toString(), contains('BencodeDecodeException'));
      expect(exception.toString(), contains('Test error'));
      expect(exception.toString(), contains('position 42'));
    });
  });

  group('Edge cases for encoding', () {
    test('encode empty string', () {
      var result = encode('');
      expect(bytesToString(result), equals('0:'));
    });

    test('encode string with special characters', () {
      var str = 'hello\nworld\t!';
      var encoded = encode(str);
      var decoded = decode(encoded);
      var decodedStr = decoded is String ? decoded : bytesToString(decoded);
      expect(decodedStr, equals(str));
    });

    test('encode very long string', () {
      var longStr = 'a' * 10000;
      var encoded = encode(longStr);
      var decoded = decode(encoded);
      var decodedStr = decoded is String ? decoded : bytesToString(decoded);
      expect(decodedStr, equals(longStr));
    });

    test('encode list with mixed types', () {
      var data = [
        'string',
        42,
        true,
        false,
        [1, 2, 3],
        {'key': 'value'},
        Uint8List.fromList([1, 2, 3])
      ];
      var encoded = encode(data);
      var decoded = decode(encoded);
      expect(decoded, isA<List>());
      expect((decoded as List).length, equals(7));
    });

    test('encode complex nested structure', () {
      var data = {
        'list': [
          {'nested': 'value'},
          [
            1,
            2,
            {'inner': 3}
          ]
        ],
        'number': 42,
        'bool': true
      };
      var encoded = encode(data);
      var decoded = decode(encoded);
      expect(decoded, isA<Map>());
      expect((decoded as Map)['number'], equals(42));
    });
  });
}

Uint8List stringToBytes(str) {
  return Uint8List.fromList(utf8.encode(str));
}

int bytesToInt(bytes) {
  return bytes[0];
}

bool myEqauls(s, t) {
  if (t is List) {
    if (s is! List) return false;
    if (s.length != t.length) return false;
    for (var i = 0; i < s.length; i++) {
      if (!myEqauls(s[i], t[i])) return false;
    }
    return true;
  }
  if (t is Map) {
    if (s is! Map) return false;
    if (s.length != t.length) return false;
    var keys = t.keys.toList();
    var keys2 = s.keys.toList();
    if (!myEqauls(keys, keys2)) return false;
    for (var key in keys) {
      if (!myEqauls(s[key], t[key])) return false;
    }
    return true;
  }
  if (t is String) {
    if (s is! String) return bytesToString(s) == t;
    return s == t;
  }
  if (t is num) return s == t;
  return false;
}

String bytesToString(bytes) {
  return utf8.decode(bytes);
}
