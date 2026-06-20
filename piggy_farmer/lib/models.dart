import 'package:json_annotation/json_annotation.dart';

part 'models.g.dart';

@JsonEnum()
enum TaskStatus {
  @JsonValue('pending') pending,
  @JsonValue('processing') processing,
  @JsonValue('completed') completed,
  @JsonValue('failed') failed,
}

@JsonSerializable(explicitToJson: true)
class Task {
  final int id;
  final String topic;
  final TaskStatus status;
  final Map<String, dynamic>? payload;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final String? errorMessage;
  final int maxRetries;
  final int retryCount;
  final int timeoutSeconds;

  Task({
    required this.id,
    required this.topic,
    required this.status,
    this.payload,
    required this.createdAt,
    required this.updatedAt,
    this.startedAt,
    this.completedAt,
    this.errorMessage,
    this.maxRetries = 3,
    this.retryCount = 0,
    this.timeoutSeconds = 300,
  });

  factory Task.fromJson(Map<String, dynamic> json) => _$TaskFromJson(json);
  Map<String, dynamic> toJson() => _$TaskToJson(this);
}
