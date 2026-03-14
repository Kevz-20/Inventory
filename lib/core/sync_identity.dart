import 'dart:math';

class SyncIdentity {
  SyncIdentity._();

  static final Random _random = Random();

  static String newLocalUuid() {
    final micros = DateTime.now().microsecondsSinceEpoch;
    final randomPart = _random.nextInt(1 << 32).toRadixString(16);
    return 'local_${micros}_$randomPart';
  }
}
