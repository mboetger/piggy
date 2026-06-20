import 'package:dart_frog/dart_frog.dart';
import 'package:postgres/postgres.dart';
import 'package:piggy_farmer/piggy_farmer.dart';

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method == HttpMethod.options) {
    return Response(statusCode: 204);
  }

  final pool = context.read<Pool>();
  final client = PiggyClient(pool);

  if (context.request.method == HttpMethod.get) {
    final tasks = await client.getRecentTasks(limit: 100);
    return Response.json(body: tasks.map((t) => t.toJson()).toList());
  }

  if (context.request.method == HttpMethod.post) {
    final body = await context.request.json() as Map<String, dynamic>;
    final topic = body['topic'] as String? ?? 'default';
    final payload = body['payload'];
    final maxRetries = body['max_retries'] as int? ?? 3;
    final timeoutSeconds = body['timeout_seconds'] as int? ?? 300;

    final id = await client.enqueue(
      topic, 
      payload as Map<String, dynamic>?, 
      maxRetries: maxRetries, 
      timeoutSeconds: timeoutSeconds,
    );

    return Response.json(
      body: {'id': id},
      statusCode: 201,
    );
  }

  return Response(statusCode: 405);
}
