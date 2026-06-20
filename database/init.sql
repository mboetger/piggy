CREATE TYPE task_status AS ENUM ('pending', 'processing', 'completed', 'failed');

CREATE TABLE tasks (
    id SERIAL PRIMARY KEY,
    topic VARCHAR(255) NOT NULL,
    status task_status NOT NULL DEFAULT 'pending',
    payload JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    started_at TIMESTAMP WITH TIME ZONE,
    completed_at TIMESTAMP WITH TIME ZONE,
    error_message TEXT
);

-- Index for quick polling by topic and status
CREATE INDEX idx_tasks_poll ON tasks (topic, status, created_at);

-- Function and trigger to notify workers on insert
CREATE OR REPLACE FUNCTION notify_new_task()
RETURNS TRIGGER AS $$
BEGIN
    PERFORM pg_notify('new_task_' || NEW.topic, NEW.id::text);
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER task_insert_notify
AFTER INSERT ON tasks
FOR EACH ROW
EXECUTE FUNCTION notify_new_task();
