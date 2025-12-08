import 'dart:convert';
import 'dart:typed_data';

/// Bencode format constants
class _BencodeConstants {
  static const int integerStart = 0x69; // 'i'
  static const int stringDelimiter = 0x3A; // ':'
  static const int dictionaryStart = 0x64; // 'd'
  static const int listStart = 0x6C; // 'l'
  static const int end = 0x65; // 'e'

  // Pre-encoded buffers for common tokens
  static final Uint8List endBuffer = Uint8List.fromList(utf8.encode('e'));
  static final Uint8List dictBuffer = Uint8List.fromList(utf8.encode('d'));
  static final Uint8List listBuffer = Uint8List.fromList(utf8.encode('l'));
}

/// Exception thrown when Bencode decoding fails.
class BencodeDecodeException implements Exception {
  final String message;
  final int? position;

  BencodeDecodeException(this.message, [this.position]);

  @override
  String toString() => position != null
      ? 'BencodeDecodeException: $message (at position $position)'
      : 'BencodeDecodeException: $message';
}

/// Encodes a Dart object to Bencode format.
///
/// Supports encoding:
/// - [String]: Encoded as `<length>:<string>`
/// - [int] or [double]: Encoded as `i<number>e`
/// - [bool]: Encoded as `i1e` (true) or `i0e` (false)
/// - [List]: Encoded as `l<items>e`
/// - [Map<String, dynamic>]: Encoded as `d<key><value>e` (keys are sorted)
/// - [Uint8List]: Encoded as `<length>:<bytes>`
///
/// [stringEncoding] specifies the encoding to use for strings (e.g., 'utf-8', 'latin1').
/// If null, strings are encoded using UTF-8.
///
/// [buffer] and [offset] allow encoding into an existing buffer at a specific offset.
/// If provided, the encoded data will be written to [buffer] starting at [offset].
///
/// Returns an empty [Uint8List] if [data] is null.
///
/// Example:
/// ```dart
/// encode('hello')           // => Uint8List([54, 58, 104, 101, 108, 108, 111])
/// encode(42)                // => Uint8List([105, 52, 50, 101])
/// encode(['a', 1])          // => Uint8List([108, 49, 58, 97, 105, 49, 101, 101])
/// encode({'key': 'value'})   // => Uint8List([100, 51, 58, 107, 101, 121, 53, 58, 118, 97, 108, 117, 101, 101])
/// ```
Uint8List encode(
  dynamic data, [
  String? stringEncoding,
  Uint8List? buffer,
  int? offset,
]) {
  if (data == null) return Uint8List(0);
  return _Encode(data, stringEncoding, buffer, offset).encoding();
}

class _Encode {
  int bytes = -1;
  final dynamic _data;
  final Uint8List? _buffer;
  final String? _stringEncoding;
  final int? _offset;

  _Encode(this._data, [String? stringEncoding, this._buffer, this._offset])
      : _stringEncoding = stringEncoding?.toLowerCase();

  Uint8List encoding() {
    final buffers = <Uint8List>[];
    _encode(buffers, _data);

    // Calculate total length for efficient allocation
    final totalLength =
        buffers.fold<int>(0, (sum, buffer) => sum + buffer.length);
    final result = Uint8List(totalLength);

    // Copy all buffers into result
    int offset = 0;
    for (final buffer in buffers) {
      result.setRange(offset, offset + buffer.length, buffer);
      offset += buffer.length;
    }

    bytes = result.length;

    if (_buffer != null) {
      final startOffset = _offset ?? 0;
      if (startOffset + result.length > _buffer!.length) {
        throw ArgumentError(
          'Buffer too small: need ${startOffset + result.length} bytes, '
          'but buffer has ${_buffer!.length} bytes',
        );
      }
      _buffer!.setRange(startOffset, startOffset + result.length, result);
      return _buffer!;
    }

    return result;
  }

  void _encode(buffers, data) {
    if (data == null) {
      return;
    }

    if (data is Uint8List) {
      buffer(buffers, data);
      return;
    }
    if (data is String) {
      string(buffers, data);
      return;
    }
    if (data is num) {
      number(buffers, data);
      return;
    }
    if (data is List) {
      list(buffers, data);
      return;
    }
    if (data is bool) {
      number(buffers, data ? 1 : 0);
      return;
    }
    if (data is Map) {
      dict(buffers, data);
      return;
    }
    // bencode.js can access ArrayBufferView and ArrayBuffer, I ignore these type:
    // case 'arraybufferview': buffer(buffers, Buffer.from(data.buffer, data.byteOffset, data.byteLength)); break;
    // case 'arraybuffer': buffer(buffers, Buffer.from(data)); break;
  }

  void buffer(List<Uint8List> buffers, Uint8List data) {
    final lengthPrefix = utf8.encode('${data.length}:');
    buffers.add(Uint8List.fromList(lengthPrefix));
    buffers.add(data);
  }

  void string(List<Uint8List> buffers, String data) {
    final encoder =
        _stringEncoding != null ? Encoding.getByName(_stringEncoding) : null;

    if (encoder != null) {
      final encodedData = encoder.encode(data);
      final lengthPrefix = utf8.encode('${encodedData.length}:');
      buffers.add(Uint8List.fromList(lengthPrefix));
      buffers.add(Uint8List.fromList(encodedData));
    } else {
      // Preserve original behavior: use codeUnits directly (not UTF-8 encoded)
      // This matches the original implementation for backward compatibility
      // Note: This is technically incorrect but maintained for compatibility
      final bytesLength = Uint8List.fromList(data.codeUnits).lengthInBytes;
      buffers.add(Uint8List.fromList('$bytesLength:$data'.codeUnits));
    }
  }

  void number(List<Uint8List> buffers, num data) {
    final encoded = utf8.encode('i${data}e');
    buffers.add(Uint8List.fromList(encoded));
  }

  void dict(List<Uint8List> buffers, Map data) {
    buffers.add(_BencodeConstants.dictBuffer);

    // Sort keys as required by Bencode specification
    final keys = (data.keys.toList()..sort()).cast<String>();

    for (final key in keys) {
      final value = data[key];
      if (value == null) continue;
      string(buffers, key);
      _encode(buffers, value);
    }

    buffers.add(_BencodeConstants.endBuffer);
  }

  void list(List<Uint8List> buffers, List data) {
    buffers.add(_BencodeConstants.listBuffer);

    for (final item in data) {
      if (item == null) continue;
      _encode(buffers, item);
    }

    buffers.add(_BencodeConstants.endBuffer);
  }
}

/// Decodes Bencode-encoded data to Dart objects.
///
/// Returns:
/// - [String] if a string was decoded and [stringEncoding] is provided
/// - [Uint8List] if a string was decoded but [stringEncoding] is null
/// - [int] for integers
/// - [List] for lists
/// - [Map<String, dynamic>] for dictionaries
/// - `null` if [data] is empty
///
/// [start] and [end] allow decoding a subrange of the input data.
/// If provided, only bytes from [start] (inclusive) to [end] (exclusive) are decoded.
///
/// [stringEncoding] specifies how to decode string values (e.g., 'utf-8', 'latin1').
/// If null, string values are returned as [Uint8List] instead of [String].
///
/// Throws [BencodeDecodeException] if the data is invalid.
///
/// Example:
/// ```dart
/// final encoded = encode({'key': 'value'});
/// final decoded = decode(encoded, stringEncoding: 'utf-8');
/// // => {'key': 'value'}
/// ```
dynamic decode(Uint8List data, {int? start, int? end, String? stringEncoding}) {
  if (data.isEmpty) {
    return null;
  }
  return _Decode(data, start: start, end: end, stringEncoding: stringEncoding)
      .next();
}

class _Decode {
  int _position = 0;
  final String? _stringEncoding;
  final Uint8List _data;

  _Decode(Uint8List data, {int? start, int? end, String? stringEncoding})
      : _stringEncoding = stringEncoding?.toLowerCase(),
        _data = (start != null)
            ? (() {
                final actualStart = start;
                final actualEnd = end ?? data.length;
                if (actualStart < 0 ||
                    actualEnd > data.length ||
                    actualStart > actualEnd) {
                  throw ArgumentError(
                    'Invalid range: start=$actualStart, end=$actualEnd, data length=${data.length}',
                  );
                }
                return data.sublist(actualStart, actualEnd);
              })()
            : data;

  /// Parses an integer from the buffer.
  ///
  /// Supports positive and negative integers.
  /// Throws [BencodeDecodeException] if the data is not a valid integer.
  int _getIntFromBuffer(Uint8List buffer, int start, int end) {
    if (start >= end) {
      throw BencodeDecodeException('Empty integer at position $start', start);
    }

    int sum = 0;
    int sign = 1;

    for (int i = start; i < end; i++) {
      final byte = buffer[i];

      // Digit 0-9
      if (byte >= 48 && byte < 58) {
        sum = sum * 10 + (byte - 48);
        continue;
      }

      // Plus sign at start
      if (i == start && byte == 43) {
        continue;
      }

      // Minus sign at start
      if (i == start && byte == 45) {
        sign = -1;
        continue;
      }

      // Decimal point (not supported in Bencode integers)
      if (byte == 46) {
        throw BencodeDecodeException(
          'Floating point numbers are not supported in Bencode',
          i,
        );
      }

      throw BencodeDecodeException(
        'Invalid character in integer: ${String.fromCharCode(byte)} (0x${byte.toRadixString(16)})',
        i,
      );
    }
    return sum * sign;
  }

  dynamic next() {
    if (_position >= _data.length) {
      return null;
    }

    switch (_data[_position]) {
      case _BencodeConstants.dictionaryStart:
        return dictionary();
      case _BencodeConstants.listStart:
        return list();
      case _BencodeConstants.integerStart:
        return integer();
      default:
        return buffer();
    }
  }

  /// Finds the next occurrence of [chr] starting from [_position].
  ///
  /// Throws [BencodeDecodeException] if the character is not found.
  int _find(int chr) {
    for (int i = _position; i < _data.length; i++) {
      if (_data[i] == chr) {
        return i;
      }
    }
    throw BencodeDecodeException(
      'Missing delimiter "${String.fromCharCode(chr)}" (0x${chr.toRadixString(16)})',
      _position,
    );
  }

  Map<String, dynamic> dictionary() {
    _position++; // Skip 'd'

    final dict = <String, dynamic>{};

    while (
        _position < _data.length && _data[_position] != _BencodeConstants.end) {
      final keyBuffer = buffer();

      // Convert key to String
      // Note: Dictionary keys should be strings, but sometimes they're encoded
      // in different encodings (e.g., latin1 for infohash). We try UTF-8 first,
      // then fall back to char codes if that fails.
      final key = keyBuffer is String
          ? keyBuffer
          : (() {
              try {
                return utf8.decode(keyBuffer);
              } catch (e) {
                // Fallback for non-UTF-8 keys (e.g., infohash)
                return String.fromCharCodes(keyBuffer);
              }
            })();

      dict[key] = next();
    }

    if (_position >= _data.length) {
      throw BencodeDecodeException(
        'Unexpected end of data while parsing dictionary',
        _position,
      );
    }

    _position++; // Skip 'e'
    return dict;
  }

  List<dynamic> list() {
    _position++; // Skip 'l'

    final lst = <dynamic>[];

    while (
        _position < _data.length && _data[_position] != _BencodeConstants.end) {
      lst.add(next());
    }

    if (_position >= _data.length) {
      throw BencodeDecodeException(
        'Unexpected end of data while parsing list',
        _position,
      );
    }

    _position++; // Skip 'e'
    return lst;
  }

  int integer() {
    final end = _find(_BencodeConstants.end);
    final number = _getIntFromBuffer(_data, _position + 1, end);

    _position = end + 1;
    return number;
  }

  dynamic buffer() {
    final sep = _find(_BencodeConstants.stringDelimiter);
    final length = _getIntFromBuffer(_data, _position, sep);

    if (length < 0) {
      throw BencodeDecodeException(
        'Invalid string length: $length',
        _position,
      );
    }

    final dataStart = sep + 1;
    final dataEnd = dataStart + length;

    if (dataEnd > _data.length) {
      throw BencodeDecodeException(
        'String length ($length) exceeds available data (${_data.length - dataStart} bytes)',
        _position,
      );
    }

    _position = dataEnd;
    final sublist = _data.sublist(dataStart, dataEnd);

    if (_stringEncoding != null) {
      final encoder = Encoding.getByName(_stringEncoding);
      if (encoder == null) {
        throw ArgumentError('Unknown encoding: $_stringEncoding');
      }
      return encoder.decode(sublist);
    }

    return sublist;
  }
}
