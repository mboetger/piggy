import 'package:postgres/postgres.dart';

class Migration {
  final int version;
  final String name;
  final List<String> sqlCommands;
  const Migration(this.version, this.name, this.sqlCommands);
}

const List<Migration> _migrations = [
  Migration(1, 'initial_schema', [
    '''
    DO \$\$
    BEGIN
        IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'task_status') THEN
            CREATE TYPE task_status AS ENUM ('pending', 'processing', 'completed', 'failed');
        END IF;
    END
    \$\$;
    ''',
    '''
    CREATE TABLE IF NOT EXISTS tasks (
      id SERIAL PRIMARY KEY,
      topic VARCHAR(255) NOT NULL DEFAULT 'default',
      status task_status NOT NULL DEFAULT 'pending',
      payload JSONB,
      created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
      updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
      started_at TIMESTAMP WITH TIME ZONE,
      completed_at TIMESTAMP WITH TIME ZONE,
      error_message TEXT
    );
    ''',
    '''
    CREATE OR REPLACE FUNCTION notify_new_task()
    RETURNS trigger AS \$\$
    BEGIN
      PERFORM pg_notify('new_task_' || NEW.topic, NEW.id::text);
      RETURN NEW;
    END;
    \$\$ LANGUAGE plpgsql;
    ''',
    '''
    DO \$\$
    BEGIN
        IF NOT EXISTS (
            SELECT 1 FROM pg_trigger 
            WHERE tgname = 'task_notify_trigger' 
            AND tgrelid = 'tasks'::regclass
        ) THEN
            CREATE TRIGGER task_notify_trigger
            AFTER INSERT ON tasks
            FOR EACH ROW
            EXECUTE FUNCTION notify_new_task();
        END IF;
    END
    \$\$;
    '''
  ]),
  Migration(2, 'add_retries', [
    'ALTER TABLE tasks ADD COLUMN IF NOT EXISTS max_retries INT NOT NULL DEFAULT 3;',
    'ALTER TABLE tasks ADD COLUMN IF NOT EXISTS retry_count INT NOT NULL DEFAULT 0;',
    'ALTER TABLE tasks ADD COLUMN IF NOT EXISTS timeout_seconds INT NOT NULL DEFAULT 300;'
  ]),
];

class PiggyMigrations {
  static Future<void> applyMigrations(Session session) async {
    await session.execute('''
      CREATE TABLE IF NOT EXISTS piggy_farmer_migrations (
        version INT PRIMARY KEY,
        name TEXT NOT NULL,
        applied_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
      );
    ''');

    final result = await session.execute('SELECT version FROM piggy_farmer_migrations ORDER BY version ASC');
    final appliedVersions = result.map((r) => r[0] as int).toSet();
    
    for (final m in _migrations) {
      if (!appliedVersions.contains(m.version)) {
        print('PiggyFarmer: Applying migration \${m.version}: \${m.name}');
        for (final cmd in m.sqlCommands) {
          await session.execute(cmd);
        }
        await session.execute(
          Sql.named('INSERT INTO piggy_farmer_migrations (version, name) VALUES (@v, @n)'),
          parameters: {'v': m.version, 'n': m.name},
        );
      }
    }
  }
}
