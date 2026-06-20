import 'package:test/test.dart';
import 'package:piggy_farmer/piggy_farmer.dart';

void main() {
  group('Task Serialization', () {
    test('Task model correctly serializes and deserializes', () {
      final task = Task(
        id: 1,
        topic: 'default',
        status: TaskStatus.pending,
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
        maxRetries: 5,
        retryCount: 0,
        timeoutSeconds: 300,
        payload: {'foo': 'bar'},
      );

      final json = task.toJson();
      expect(json['topic'], 'default');
      expect(json['maxRetries'], 5);
      expect(json['payload']['foo'], 'bar');

      final deserialized = Task.fromJson(json);
      expect(deserialized.id, 1);
      expect(deserialized.maxRetries, 5);
      expect(deserialized.payload?['foo'], 'bar');
    });
  });
}
