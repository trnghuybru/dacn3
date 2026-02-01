-- Thêm cột password_hash cho đăng nhập/đăng ký (app users)
USE disaster_response;

ALTER TABLE users
ADD COLUMN password_hash VARCHAR(255) NULL
AFTER device_token;
