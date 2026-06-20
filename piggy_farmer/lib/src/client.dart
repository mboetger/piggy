import 'package:postgres/postgres.dart';
import '../models.dart';

class PiggyClient {
  final Pool pool;

  PiggyClient(this.pool);

  Future<int> enqueue(String topic, Map<String, dynamic>? payload, {int maxRetries = 3, int timeoutSeconds = 300}) async {
    final result = await pool.execute(
      Sql.named('''
        INSERT INTO tasks (topic, payload, max_retries, timeout_seconds)
        VALUES (@topic, @payload, @max_retries, @timeout_seconds)
        RETURNING id
      '''),
      parameters: {
        'topic': topic,
        'payload': payload,
        'max_retries': maxRetries,
        'timeout_seconds': timeoutSeconds,
      },
    );
    return result.first[0] as int;
  }

  Future<Map<String, int>> getStatusCounts() async {
    final result = await pool.execute('''
      SELECT status::text, count(*) 
      FROM tasks 
      GROUP BY status
    ''');
    final counts = <String, int>{
      'pending': 0,
      'processing': 0,
      'completed': 0,
      'failed': 0,
    };
    for (final row in result) {
      counts[row[0] as String] = row[1] as int;
    }
    return counts;
  }

  Future<List<Task>> getRecentTasks({int limit = 100}) async {
    final result = await pool.execute(
      Sql.named('''
        SELECT id, topic, status::text, payload, created_at, updated_at, started_at, completed_at, error_message, max_retries, retry_count, timeout_seconds
        FROM tasks
        ORDER BY created_at DESC
        LIMIT @limit
      '''),
      parameters: {'limit': limit},
    );

    return result.map((row) {
      return Task(
        id: row[0] as int,
        topic: row[1] as String,
        status: TaskStatus.values.firstWhere((e) => e.name == (row[2] as String)),
        payload: row[3] is String ? null : row[3] as Map<String, dynamic>?,
        createdAt: row[4] as DateTime,
        updatedAt: row[5] as DateTime,
        startedAt: row[6] as DateTime?,
        completedAt: row[7] as DateTime?,
        errorMessage: row[8] as String?,
        maxRetries: row[9] as int,
        retryCount: row[10] as int,
        timeoutSeconds: row[11] as int,
      );
    }).toList();
  }
}
