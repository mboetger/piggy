import 'package:dart_frog/dart_frog.dart';
import 'package:postgres/postgres.dart';
import 'package:piggy_farmer/piggy_farmer.dart';

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method == HttpMethod.options) {
    return Response(statusCode: 204);
  }

  if (context.request.method != HttpMethod.get) {
    return Response(statusCode: 405);
  }

  final pool = context.read<Pool>();
  final client = PiggyClient(pool);
  
  final counts = await client.getStatusCounts();

  return Response.json(body: counts);
}
