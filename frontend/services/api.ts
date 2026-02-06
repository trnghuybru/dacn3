/**
 * API service để gọi backend
 */
import { API_CONFIG } from "@/constants/config";

const API_BASE_URL = API_CONFIG.BASE_URL;

export interface RegisterData {
  phone: string;
  password: string;
  full_name?: string;
  device_token?: string;
  lat?: number;
  lng?: number;
  district_id?: number;
}

export interface LoginData {
  phone: string;
  password: string;
  device_token?: string;
}

export interface AuthResponse {
  message: string;
  token?: string;
  user?: {
    id: number;
    phone: string;
    full_name?: string;
  };
}

export interface ErrorResponse {
  error: string;
}

/**
 * Lưu token vào AsyncStorage
 */
import AsyncStorage from "@react-native-async-storage/async-storage";

const TOKEN_KEY = "@auth_token";

export const saveToken = async (token: string) => {
  try {
    await AsyncStorage.setItem(TOKEN_KEY, token);
  } catch (error) {
    console.error("Error saving token:", error);
  }
};

export const getToken = async (): Promise<string | null> => {
  try {
    return await AsyncStorage.getItem(TOKEN_KEY);
  } catch (error) {
    console.error("Error getting token:", error);
    return null;
  }
};

export const removeToken = async () => {
  try {
    await AsyncStorage.removeItem(TOKEN_KEY);
  } catch (error) {
    console.error("Error removing token:", error);
  }
};

/**
 * Đăng ký
 */
export const register = async (data: RegisterData): Promise<AuthResponse> => {
  const response = await fetch(`${API_BASE_URL}/auth/register`, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
    },
    body: JSON.stringify(data),
  });

  const result = await response.json();

  if (!response.ok) {
    throw new Error(result.error || "Đăng ký thất bại");
  }

  return result;
};

/**
 * Đăng nhập
 */
export const login = async (data: LoginData): Promise<AuthResponse> => {
  const response = await fetch(`${API_BASE_URL}/auth/login`, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
    },
    body: JSON.stringify(data),
  });

  const result = await response.json();

  if (!response.ok) {
    throw new Error(result.error || "Đăng nhập thất bại");
  }

  // Lưu token sau khi đăng nhập thành công
  if (result.token) {
    await saveToken(result.token);
  }

  return result;
};

/**
 * Lấy thông tin user hiện tại
 */
export const getMe = async (): Promise<any> => {
  const token = await getToken();
  if (!token) {
    throw new Error("Chưa đăng nhập");
  }

  const response = await fetch(`${API_BASE_URL}/auth/me`, {
    method: "GET",
    headers: {
      Authorization: `Bearer ${token}`,
    },
  });

  const result = await response.json();

  if (!response.ok) {
    if (response.status === 401) {
      await removeToken(); // Token hết hạn hoặc không hợp lệ
    }
    throw new Error(result.error || "Lấy thông tin thất bại");
  }

  return result;
};
