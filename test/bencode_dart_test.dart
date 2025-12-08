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
