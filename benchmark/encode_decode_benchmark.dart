import 'package:benchmark_harness/benchmark_harness.dart';
import 'package:b_encode_decode/b_encode_decode.dart';

class EncodeSmallStringBenchmark extends BenchmarkBase {
  EncodeSmallStringBenchmark() : super('EncodeSmallString');
  final data = 'hello world';
  @override
  void run() {
    encode(data);
  }
}

class DecodeSmallStringBenchmark extends BenchmarkBase {
  DecodeSmallStringBenchmark() : super('DecodeSmallString');
  final data = encode('hello world');
  @override
  void run() {
    decode(data);
  }
}

class EncodeLargeStringBenchmark extends BenchmarkBase {
  EncodeLargeStringBenchmark() : super('EncodeLargeString');
  final data = 'a' * 100000;
  @override
  void run() {
    encode(data);
  }
}

class DecodeLargeStringBenchmark extends BenchmarkBase {
  DecodeLargeStringBenchmark() : super('DecodeLargeString');
  final data = encode('a' * 100000);
  @override
  void run() {
    decode(data);
  }
}

class EncodeSmallListBenchmark extends BenchmarkBase {
  EncodeSmallListBenchmark() : super('EncodeSmallList');
  final data = List.generate(100, (i) => i);
  @override
  void run() {
    encode(data);
  }
}

class DecodeSmallListBenchmark extends BenchmarkBase {
  DecodeSmallListBenchmark() : super('DecodeSmallList');
  final data = encode(List.generate(100, (i) => i));
  @override
  void run() {
    decode(data);
  }
}

class EncodeLargeListBenchmark extends BenchmarkBase {
  EncodeLargeListBenchmark() : super('EncodeLargeList');
  final data = List.generate(10000, (i) => i);
  @override
  void run() {
    encode(data);
  }
}

class DecodeLargeListBenchmark extends BenchmarkBase {
  DecodeLargeListBenchmark() : super('DecodeLargeList');
  final data = encode(List.generate(10000, (i) => i));
  @override
  void run() {
    decode(data);
  }
}

class EncodeSmallMapBenchmark extends BenchmarkBase {
  EncodeSmallMapBenchmark() : super('EncodeSmallMap');
  final data = {for (var i = 0; i < 100; i++) 'key$i': i};
  @override
  void run() {
    encode(data);
  }
}

class DecodeSmallMapBenchmark extends BenchmarkBase {
  DecodeSmallMapBenchmark() : super('DecodeSmallMap');
  final data = encode({for (var i = 0; i < 100; i++) 'key$i': i});
  @override
  void run() {
    decode(data);
  }
}

class EncodeLargeMapBenchmark extends BenchmarkBase {
  EncodeLargeMapBenchmark() : super('EncodeLargeMap');
  final data = {for (var i = 0; i < 10000; i++) 'key$i': i};
  @override
  void run() {
    encode(data);
  }
}

class DecodeLargeMapBenchmark extends BenchmarkBase {
  DecodeLargeMapBenchmark() : super('DecodeLargeMap');
  final data = encode({for (var i = 0; i < 10000; i++) 'key$i': i});
  @override
  void run() {
    decode(data);
  }
}

void main() {
  EncodeSmallStringBenchmark().report();
  DecodeSmallStringBenchmark().report();
  EncodeLargeStringBenchmark().report();
  DecodeLargeStringBenchmark().report();
  EncodeSmallListBenchmark().report();
  DecodeSmallListBenchmark().report();
  EncodeLargeListBenchmark().report();
  DecodeLargeListBenchmark().report();
  EncodeSmallMapBenchmark().report();
  DecodeSmallMapBenchmark().report();
  EncodeLargeMapBenchmark().report();
  DecodeLargeMapBenchmark().report();
}
