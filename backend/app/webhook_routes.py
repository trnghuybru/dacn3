from flask import Blueprint, request, jsonify

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
        
        # Kiểm tra secret key
        secret_key = data.get("secret_key") if data else None
        if secret_key != "my_secret_key_2026":
            return jsonify({"status": "error", "message": "Invalid secret key"}), 401
        
        # In ra console để kiểm tra
        print("=== Nhận được Webhook SMS ===")
        print(data)
        print("==============================")
        
        # Trả về mã thành công cho dịch vụ bên thứ 3 (để họ biết đã gửi thành công)
        return jsonify({"status": "success", "message": "Webhook received successfully"}), 200
        
    except Exception as e:
        print(f"Lỗi khi nhận webhook SMS: {e}")
        return jsonify({"status": "error", "message": str(e)}), 400
