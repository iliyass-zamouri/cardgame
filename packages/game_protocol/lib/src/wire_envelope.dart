import 'dart:convert';

/// Top-level WebSocket frame: `{ "event": "...", "payload": { ... } }`.
class WireEnvelope {
  const WireEnvelope({
    required this.event,
    required this.payload,
  });

  final String event;
  final Map<String, dynamic> payload;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'event': event,
        'payload': payload,
      };

  String encode() => jsonEncode(toJson());

  static WireEnvelope decode(String raw) {
    final decoded = jsonDecode(raw);
    if (decoded is! Map) {
      throw FormatException('Wire envelope must be a JSON object');
    }
    final map = Map<String, dynamic>.from(decoded);
    final event = map['event'];
    final payload = map['payload'];
    if (event is! String || event.isEmpty) {
      throw FormatException('Wire envelope missing event');
    }
    if (payload is! Map) {
      throw FormatException('Wire envelope missing payload object');
    }
    return WireEnvelope(
      event: event,
      payload: Map<String, dynamic>.from(payload),
    );
  }

  static WireEnvelope? tryDecode(String raw) {
    try {
      return decode(raw);
    } on Object {
      return null;
    }
  }
}
