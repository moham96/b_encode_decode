/// A Dart library for encoding and decoding data in the Bencode format.
///
/// Bencode is the encoding format used by the BitTorrent protocol.
/// This library provides functions to encode Dart objects (String, int, List, Map)
/// to Bencode format and decode Bencode-encoded data back to Dart objects.
///
/// ## Usage
///
/// ```dart
/// import 'package:b_encode_decode/b_encode_decode.dart' as bencode;
///
/// // Encode data
/// final encoded = bencode.encode({'key': 'value', 'number': 42});
///
/// // Decode data
/// final decoded = bencode.decode(encoded);
/// ```
library b_encode_decode;

export 'src/b_encode_decode_base.dart';
