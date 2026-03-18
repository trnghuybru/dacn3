import json
from flask import Blueprint, request, jsonify
from .database import get_connection

webhook = Blueprint("webhook", __name__, url_prefix="/api/webhook")

@webhook.route("/sms", methods=["POST"])
def receive_sms():
    """
    Endpoint (Webhook) để nhận dữ liệu từ dịch vụ SMS bên thứ 3.
    Hiện tại chỉ nhận JSON và in ra console.
    """
    try:
        # Lấy dữ liệu JSON từ request
        data = request.get_json()
        if not data:
            return jsonify({"status": "error", "message": "No data received"}), 400
        
        # SpeedSMS thường không gửi secret trong body, nên kiểm tra từ query params của URL
        # URL đăng ký trên dashboard SpeedSMS: https://domain/api/webhook/sms?secret_key=my_secret_key_2026
        secret_key = request.args.get("secret_key")
        if secret_key and secret_key != "my_secret_key_2026":
            return jsonify({"status": "error", "message": "Invalid secret key"}), 401
        
        # In ra console để kiểm tra
        print("=== Nhận được Webhook SpeedSMS ===")
        print(data)
        print("=================================")
        
        msg_type = data.get("type")
        
        # Nếu không phải là tin nhắn gửi đến (ví dụ: delivery report), ta bỏ qua nhưng vẫn trả về 200
        if msg_type != "sms":
            print(f"Nhận bản tin loại {msg_type}, bỏ qua lưu database.")
            return jsonify({"status": "success", "message": "Ignored non-sms webhook"}), 200
        
        # Bóc tách thông tin dựa theo định dạng của SpeedSMS
        sender = data.get("phone") or "Unknown"
        content = data.get("content") or ""
        
        # Nội dung SMS từ frontend Dart gửi lên là một chuỗi JSON encode
        sms_type = None
        location = None
        people_count = None
        contact_phone = None
        situation = content
        
        try:
            parsed_content = json.loads(content)
            if isinstance(parsed_content, dict):
                sms_type = parsed_content.get("type")
                location = parsed_content.get("location")
                people_count = parsed_content.get("people_count")
                contact_phone = parsed_content.get("contact_phone")
                # Ghi đè situation nếu parse thành công
                situation = parsed_content.get("situation", content)
        except json.JSONDecodeError:
            print("Content không phải JSON, lưu dưới dạng nguyên bản vào situation.")
        
        # Lưu vào database (không lưu raw_payload và content gốc nữa)
        conn = get_connection()
        try:
            with conn.cursor() as cur:
                cur.execute(
                    """
                    INSERT INTO webhook_messages 
                    (sender, sms_type, location, people_count, contact_phone, situation)
                    VALUES (%s, %s, %s, %s, %s, %s)
                    """,
                    (sender, sms_type, location, people_count, contact_phone, situation)
                )
                conn.commit()
                print("Đã lưu tin nhắn SpeedSMS (chỉ lưu các trường bóc tách) vào database.")
        finally:
            conn.close()
        
        # Trả về mã thành công cho SpeedSMS (để họ biết đã gửi thành công và không gửi lại)
        return jsonify({"status": "success", "message": "Webhook received and saved successfully"}), 200
        
    except Exception as e:
        print(f"Lỗi khi nhận webhook SMS: {e}")
        return jsonify({"status": "error", "message": str(e)}), 400
