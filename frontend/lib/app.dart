import 'dart:convert';
import 'package:jaspr/jaspr.dart';
import 'package:http/http.dart' as http;
import 'package:piggy_farmer/models.dart';
import 'dart:async';
import 'package:jaspr/dom.dart';

class App extends StatefulComponent {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  Map<String, int> _statusCounts = {
    'pending': 0,
    'processing': 0,
    'completed': 0,
    'failed': 0,
  };
  List<Task> _tasks = [];
  Timer? _timer;
  bool _isLoading = false;

  final _apiUrl = 'http://localhost:8080';

  @override
  void initState() {
    super.initState();
    _fetchData();
    _timer = Timer.periodic(const Duration(seconds: 2), (_) => _fetchData());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _fetchData() async {
    try {
      final statusRes = await http.get(Uri.parse('$_apiUrl/status'));
      if (statusRes.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(statusRes.body);
        _statusCounts = data.map((key, value) => MapEntry(key, value as int));
      }

      final tasksRes = await http.get(Uri.parse('$_apiUrl/tasks'));
      if (tasksRes.statusCode == 200) {
        final List<dynamic> data = jsonDecode(tasksRes.body);
        _tasks = data.map((json) => Task.fromJson(json)).toList();
      }
      setState(() {});
    } catch (e) {
      print('Error fetching data: $e');
    }
  }

  Future<void> _enqueueTask(int count) async {
    if (_isLoading) return;
    setState(() => _isLoading = true);
    
    try {
      final futures = <Future>[];
      for (int i = 0; i < count; i++) {
        futures.add(http.post(
          Uri.parse('$_apiUrl/tasks'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'topic': 'default',
            'payload': {'action': 'do_something_awesome', 'index': i}
          }),
        ));
      }
      await Future.wait(futures);
      await _fetchData();
    } catch (e) {
      print('Error enqueuing tasks: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Component build(BuildContext context) {
    return div(classes: 'app-container', [
      div(classes: 'header', [
        img(src: 'piggy_logo.jpg', alt: 'Piggy Logo', classes: 'logo'),
        h1([text('Piggy Platform')]),
        p([text('High-Performance PostgreSQL Task Queue')]),
      ]),

      div(classes: 'card', [
        h2([text('Pool Status')]),
        div(classes: 'status-grid', [
          _buildStatusItem('Pending', _statusCounts['pending'] ?? 0, 'status-pending'),
          _buildStatusItem('Processing', _statusCounts['processing'] ?? 0, 'status-processing'),
          _buildStatusItem('Completed', _statusCounts['completed'] ?? 0, 'status-completed'),
          _buildStatusItem('Failed', _statusCounts['failed'] ?? 0, 'status-failed'),
        ]),
      ]),

      div(classes: 'card', [
        div(classes: 'button-group', [
          button(
            classes: 'button',
            onClick: () => _enqueueTask(1),
            disabled: _isLoading,
            [text(_isLoading ? 'Enqueuing...' : '+ 1 Task')],
          ),
          button(
            classes: 'button',
            onClick: () => _enqueueTask(10),
            disabled: _isLoading,
            [text(_isLoading ? 'Enqueuing...' : '+ 10 Tasks')],
          ),
          button(
            classes: 'button',
            onClick: () => _enqueueTask(100),
            disabled: _isLoading,
            [text(_isLoading ? 'Enqueuing...' : '+ 100 Tasks')],
          ),
        ])
      ]),

      div(classes: 'card', [
        h2([text('Recent Tasks')]),
        div(classes: 'task-list', _tasks.map(_buildTaskItem).toList()),
      ]),
    ]);
  }

  Component _buildStatusItem(String label, int count, String valueClass) {
    return div(classes: 'status-item', [
      div(classes: 'status-value $valueClass', [text(count.toString())]),
      div(classes: 'status-label', [text(label)]),
    ]);
  }

  Component _buildTaskItem(Task task) {
    final statusName = task.status.name;
    return div(classes: 'task-item $statusName', [
      div([
        div(classes: 'task-topic', [text(task.topic)]),
        div(classes: 'task-id', [text('Task #${task.id}')]),
      ]),
      div(classes: 'status-label status-$statusName', [text(statusName.toUpperCase())]),
    ]);
  }
}
