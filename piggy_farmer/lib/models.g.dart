// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Task _$TaskFromJson(Map<String, dynamic> json) => Task(
  id: (json['id'] as num).toInt(),
  topic: json['topic'] as String,
  status: $enumDecode(_$TaskStatusEnumMap, json['status']),
  payload: json['payload'] as Map<String, dynamic>?,
  createdAt: DateTime.parse(json['createdAt'] as String),
  updatedAt: DateTime.parse(json['updatedAt'] as String),
  startedAt: json['startedAt'] == null
      ? null
      : DateTime.parse(json['startedAt'] as String),
  completedAt: json['completedAt'] == null
      ? null
      : DateTime.parse(json['completedAt'] as String),
  errorMessage: json['errorMessage'] as String?,
  maxRetries: (json['maxRetries'] as num?)?.toInt() ?? 3,
  retryCount: (json['retryCount'] as num?)?.toInt() ?? 0,
  timeoutSeconds: (json['timeoutSeconds'] as num?)?.toInt() ?? 300,
);

Map<String, dynamic> _$TaskToJson(Task instance) => <String, dynamic>{
  'id': instance.id,
  'topic': instance.topic,
  'status': _$TaskStatusEnumMap[instance.status]!,
  'payload': instance.payload,
  'createdAt': instance.createdAt.toIso8601String(),
  'updatedAt': instance.updatedAt.toIso8601String(),
  'startedAt': instance.startedAt?.toIso8601String(),
  'completedAt': instance.completedAt?.toIso8601String(),
  'errorMessage': instance.errorMessage,
  'maxRetries': instance.maxRetries,
  'retryCount': instance.retryCount,
  'timeoutSeconds': instance.timeoutSeconds,
};

const _$TaskStatusEnumMap = {
  TaskStatus.pending: 'pending',
  TaskStatus.processing: 'processing',
  TaskStatus.completed: 'completed',
  TaskStatus.failed: 'failed',
};
