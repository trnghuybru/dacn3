/**
 * Cấu hình API và app
 */
export const API_CONFIG = {
  // Development: Đã đổi thành IP LAN để chạy được trên Emulator/Device
  // Nếu bạn dùng máy ảo Android (Emulator), Android coi 10.0.2.2 là localhost của máy chủ
  // Nếu bạn dùng điện thoại thật, hãy thay bằng IP LAN (VD: 192.168.1.15)
  BASE_URL: __DEV__
    ? "http://192.168.1.15:5000" // IP LAN hiện tại của máy bạn
    : "https://your-production-url.com",
};
