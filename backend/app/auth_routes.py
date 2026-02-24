
from flask import Blueprint, jsonify, request

from .auth_utils import (
    create_token,
    decode_token,
    get_token_from_request,
    hash_password,
    verify_password,
)
from .database import get_connection

auth = Blueprint("auth", __name__, url_prefix="/auth")


@auth.route("", methods=["GET"])
@auth.route("/", methods=["GET"])
def auth_info():
    """Gợi ý URL khi gọi sai (tránh 404)."""
    return jsonify({
        "message": "Auth API – token chỉ cấp khi đăng nhập (login)",
        "register": "POST /auth/register (không trả token)",
        "login": "POST /auth/login (trả token)",
        "me": "GET /auth/me (header: Authorization: Bearer <token>)",
    }), 200


def _is_phone_blocked(conn, phone: str) -> bool:
    """
    Tạm thời luôn cho phép số điện thoại đăng ký / đăng nhập
    vì bảng blocked_numbers không còn trong schema hiện tại.
    """
    return False


def _user_by_phone(conn, phone: str) -> dict | None:
    with conn.cursor() as cur:
        cur.execute(
            "SELECT id, phone, full_name, device_token, password_hash, role, status, created_at "
            "FROM users WHERE phone = %s AND status = 'ACTIVE' LIMIT 1",
            (phone,),
        )
        return cur.fetchone()


@auth.route("/register", methods=["POST"])
def register():
    """
    Body JSON: phone, password, full_name (optional), device_token (optional),
    lat, lng (optional, mặc định 0,0 cho last_known_location).
    """
    data = request.get_json(silent=True) or {}
    phone = (data.get("phone") or "").strip()
    password = data.get("password") or ""

    if not phone:
        return jsonify({"error": "Thiếu số điện thoại"}), 400
    if not password or len(password) < 6:
        return jsonify({"error": "Mật khẩu tối thiểu 6 ký tự"}), 400

    lat = float(data.get("lat", 0))
    lng = float(data.get("lng", 0))
    full_name = (data.get("full_name") or "").strip() or None
    device_token = (data.get("device_token") or "").strip() or None

    conn = get_connection()
    try:
        if _is_phone_blocked(conn, phone):
            return jsonify({"error": "Số điện thoại đã bị chặn"}), 403

        existing = _user_by_phone(conn, phone)
        if existing:
            return jsonify({"error": "Số điện thoại đã được đăng ký"}), 409

        password_hash = hash_password(password)
        # MySQL POINT: SRID 4326 = WGS84, thứ tự (lng, lat)
        wkt_point = f"POINT({lng} {lat})"
        with conn.cursor() as cur:
            cur.execute(
                """
                INSERT INTO users (phone, full_name, device_token, password_hash, last_known_location, status)
                VALUES (%s, %s, %s, %s, ST_GeomFromText(%s, 4326), 'ACTIVE')
                """,
                (phone, full_name, device_token, password_hash, wkt_point),
            )
            conn.commit()
            user_id = cur.lastrowid

        # Đăng ký xong không cấp token; dùng /auth/login để lấy token
        return jsonify({
            "message": "Đăng ký thành công",
            "user": {
                "id": user_id,
                "phone": phone,
                "full_name": full_name,
            },
        }), 201
    finally:
        conn.close()


@auth.route("/login", methods=["POST"])
def login():
    """
    Body JSON: phone, password. Có thể thêm device_token để cập nhật.
    """
    data = request.get_json(silent=True) or {}
    phone = (data.get("phone") or "").strip()
    password = data.get("password") or ""

    if not phone:
        return jsonify({"error": "Thiếu số điện thoại"}), 400
    if not password:
        return jsonify({"error": "Thiếu mật khẩu"}), 400

    conn = get_connection()
    try:
        if _is_phone_blocked(conn, phone):
            return jsonify({"error": "Số điện thoại đã bị chặn"}), 403

        user = _user_by_phone(conn, phone)
        if not user:
            return jsonify({"error": "Số điện thoại hoặc mật khẩu không đúng"}), 401

        pwd_hash = user.get("password_hash")
        if not pwd_hash:
            return jsonify({"error": "Tài khoản chưa đặt mật khẩu, vui lòng dùng quên mật khẩu hoặc liên hệ hỗ trợ"}), 401
        if not verify_password(password, pwd_hash):
            return jsonify({"error": "Số điện thoại hoặc mật khẩu không đúng"}), 401

        device_token = (data.get("device_token") or "").strip()
        if device_token:
            with conn.cursor() as cur:
                cur.execute("UPDATE users SET device_token = %s WHERE id = %s", (device_token, user["id"]))
                conn.commit()

        token = create_token(user["id"], user["phone"], user.get("role"))
        return jsonify({
            "message": "Đăng nhập thành công",
            "token": token,
            "user": {
                "id": user["id"],
                "phone": user["phone"],
                "full_name": user["full_name"],
                "role": user.get("role", "USER"),
            },
        })
    finally:
        conn.close()


@auth.route("/me", methods=["GET"])
def me():
    """
    Trả về thông tin user hiện tại. Header: Authorization: Bearer <token>.
    """
    token = get_token_from_request()
    if not token:
        return jsonify({"error": "Thiếu token"}), 401

    payload = decode_token(token)
    if not payload or "sub" not in payload:
        return jsonify({"error": "Token không hợp lệ hoặc đã hết hạn"}), 401

    user_id = int(payload["sub"])
    conn = get_connection()
    try:
        with conn.cursor() as cur:
            cur.execute(
                "SELECT id, phone, full_name, device_token, role, status, created_at "
                "FROM users WHERE id = %s AND status = 'ACTIVE' LIMIT 1",
                (user_id,),
            )
            row = cur.fetchone()
        if not row:
            return jsonify({"error": "Người dùng không tồn tại hoặc đã bị khóa"}), 401
        # Bỏ password_hash nếu có, và format datetime
        out = dict(row)
        out.pop("password_hash", None)
        if out.get("created_at"):
            out["created_at"] = out["created_at"].isoformat() if hasattr(out["created_at"], "isoformat") else str(out["created_at"])
        return jsonify({"user": out})
    finally:
        conn.close()
