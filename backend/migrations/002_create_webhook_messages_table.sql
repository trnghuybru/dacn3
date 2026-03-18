CREATE TABLE IF NOT EXISTS webhook_messages (
    id INT AUTO_INCREMENT PRIMARY KEY,
    sender VARCHAR(50),
    content TEXT,
    raw_payload JSON,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
