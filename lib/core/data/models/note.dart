import 'package:uuid/uuid.dart';

class Note {
  final String id;
  final String content;
  final String? deviceId;
  final DateTime timestamp;

  Note({
    String? id,
    required this.content,
    this.deviceId,
    DateTime? timestamp,
  })  : id = id ?? const Uuid().v4(),
        timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'content': content,
      'deviceId': deviceId,
      'timestamp': timestamp.millisecondsSinceEpoch,
    };
  }

  factory Note.fromMap(Map<String, dynamic> map) {
    return Note(
      id: map['id'],
      content: map['content'],
      deviceId: map['deviceId'],
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp']),
    );
  }

  Note copyWith({
    String? content,
    String? deviceId,
    DateTime? timestamp,
  }) {
    return Note(
      id: id,
      content: content ?? this.content,
      deviceId: deviceId ?? this.deviceId,
      timestamp: timestamp ?? this.timestamp,
    );
  }
}