# Migrations

Chạy các file `.sql` theo thứ tự trên database **disaster_response** (Aiven MySQL).

## Bước 1: Thêm cột `password_hash` (bắt buộc cho Login/Register)

**File:** `001_add_password_to_users.sql`

**Cách chạy:** Mở MySQL client (Workbench, DBeaver, HeidiSQL, hoặc `mysql` CLI), kết nối tới DB với thông tin trong `backend/.env`, rồi chạy:

```sql
USE disaster_response;

ALTER TABLE users
ADD COLUMN password_hash VARCHAR(255) NULL
AFTER device_token;
```

Sau khi chạy xong, thử lại **POST /auth/register** trên Postman.
