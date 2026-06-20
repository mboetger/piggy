import 'dart:async';
import 'dart:io';
import 'package:postgres/postgres.dart';
import '../models.dart';

typedef TaskHandler = Future<void> Function(Task task);

class PiggyWorker {
  final Pool pool;
  final Connection listenConnection;
  final Map<String, TaskHandler> _handlers = {};
  final StreamController<void> _triggerCheck = StreamController<void>.broadcast();
  bool _isProcessing = false;
  bool _running = false;
  Timer? _fallbackTimer;
  final int concurrencyLimit;
  int _activeTasks = 0;

  PiggyWorker(this.pool, this.listenConnection, {this.concurrencyLimit = 10});

  void on(String topic, TaskHandler handler) {
    if (_running) throw StateError('Cannot add topic after worker has started');
    _handlers[topic] = handler;
  }

  Future<void> start() async {
    if (_running) return;
    _running = true;

    for (final topic in _handlers.keys) {
      final channelName = 'new_task_$topic';
      listenConnection.channels[channelName].listen((_) {
        _triggerCheck.add(null);
      }, onError: (e) {
        print('PiggyFarmer: Listen connection error: $e');
        exit(1);
      }, onDone: () {
        print('PiggyFarmer: Listen connection closed.');
        exit(1);
      });
    }

    _fallbackTimer = Timer.periodic(Duration(seconds: 10), (_) async {
      try {
        await listenConnection.execute('SELECT 1');
      } catch (e) {
        print('PiggyFarmer: Liveness check failed: $e');
        exit(1);
      }
      _triggerCheck.add(null);
    });
    _triggerCheck.add(null);

    await for (final _ in _triggerCheck.stream) {
      if (!_running) break;
      if (_isProcessing) continue;
      _isProcessing = true;
      
      try {
        while (_activeTasks < concurrencyLimit) {
          bool anyProcessed = false;
          for (final topic in _handlers.keys) {
            if (_activeTasks >= concurrencyLimit) break;
            
            bool taskDispatched = await _tryDispatchNextTask(topic);
            if (taskDispatched) anyProcessed = true;
          }
          if (!anyProcessed) break;
        }
      } catch (e) {
        print('PiggyFarmer: Worker loop error: $e');
      } finally {
        _isProcessing = false;
      }
    }
  }

  Future<void> stop() async {
    _running = false;
    _fallbackTimer?.cancel();
    _triggerCheck.add(null); // to wake up and exit
  }

  Future<bool> _tryDispatchNextTask(String topic) async {
    // 1. Transaction to pick up the task securely
    final task = await pool.runTx((ctx) async {
      final result = await ctx.execute(
        Sql.named('''
          SELECT id, payload, max_retries, retry_count, timeout_seconds, created_at, updated_at, started_at, completed_at, error_message, status::text
          FROM tasks
          WHERE topic = @topic 
            AND (
              status = 'pending' 
              OR (status = 'processing' AND updated_at < NOW() - (timeout_seconds || ' seconds')::interval)
            )
          ORDER BY created_at ASC
          FOR UPDATE SKIP LOCKED
          LIMIT 1
        '''),
        parameters: {'topic': topic},
      );

      if (result.isEmpty) {
        return null; 
      }

      final row = result.first;
      final id = row[0] as int;
      final previousStatus = row[10] as String;
      int retryCount = row[3] as int;
      
      // If we are picking up a timed-out task, count it as a retry immediately
      if (previousStatus == 'processing') {
        retryCount += 1;
      }

      await ctx.execute(
        Sql.named('''
          UPDATE tasks
          SET status = 'processing', 
              started_at = COALESCE(started_at, NOW()), 
              updated_at = NOW(),
              retry_count = @retryCount
          WHERE id = @id
        '''),
        parameters: {
          'id': id,
          'retryCount': retryCount,
        },
      );

      return Task(
        id: id,
        topic: topic,
        status: TaskStatus.processing,
        payload: row[1] is String ? null : row[1] as Map<String, dynamic>?,
        maxRetries: row[2] as int,
        retryCount: retryCount,
        timeoutSeconds: row[4] as int,
        createdAt: row[5] as DateTime,
        updatedAt: row[6] as DateTime,
        startedAt: row[7] as DateTime?,
        completedAt: row[8] as DateTime?,
        errorMessage: row[9] as String?,
      );
    });

    if (task == null) return false;

    // 2. Execute handler outside the lock concurrently
    _activeTasks++;
    _executeHandler(topic, task); // deliberately not awaited
    return true; 
  }

  Future<void> _executeHandler(String topic, Task task) async {
    final handler = _handlers[topic];
    if (handler != null) {
      try {
        await handler(task);
        
        await pool.execute(
          Sql.named('''
            UPDATE tasks
            SET status = 'completed', completed_at = NOW(), updated_at = NOW()
            WHERE id = @id AND retry_count = @originalRetryCount
          '''),
          parameters: {'id': task.id, 'originalRetryCount': task.retryCount},
        );
      } catch (e) {
        final newRetryCount = task.retryCount + 1;
        final status = newRetryCount >= task.maxRetries ? 'failed' : 'pending';
        
        await pool.execute(
          Sql.named('''
            UPDATE tasks
            SET status = @status, 
                retry_count = @retryCount, 
                updated_at = NOW(), 
                error_message = @error
            WHERE id = @id AND retry_count = @originalRetryCount
          '''),
          parameters: {
            'id': task.id,
            'status': status,
            'retryCount': newRetryCount,
            'error': e.toString(),
            'originalRetryCount': task.retryCount,
          },
        );
      }
    }
    
    _activeTasks--;
    if (_activeTasks < concurrencyLimit) {
      _triggerCheck.add(null);
    }
  }
}
