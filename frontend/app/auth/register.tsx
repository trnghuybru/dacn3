/**
 * Màn hình Đăng ký
 */
import React, { useState } from "react";
import {
  View,
  Text,
  StyleSheet,
  ScrollView,
  KeyboardAvoidingView,
  Platform,
  Alert,
  TouchableOpacity,
} from "react-native";
import { SafeAreaView } from "react-native-safe-area-context";
import { Ionicons } from "@expo/vector-icons";
import { router } from "expo-router";
import { Input } from "@/components/ui/input";
import { Button } from "@/components/ui/button";
import { register, RegisterData } from "@/services/api";

export default function RegisterScreen() {
  const [phone, setPhone] = useState("");
  const [fullName, setFullName] = useState("");
  const [password, setPassword] = useState("");
  const [confirmPassword, setConfirmPassword] = useState("");
  const [loading, setLoading] = useState(false);
  const [errors, setErrors] = useState<{
    phone?: string;
    fullName?: string;
    password?: string;
    confirmPassword?: string;
  }>({});

  const validatePassword = (pwd: string): boolean => {
    // Backend yêu cầu tối thiểu 6 ký tự, nhưng UI có thể yêu cầu mạnh hơn
    if (pwd.length < 6) return false;
    // Optional: có thể thêm validation cho chữ hoa, chữ thường, số
    return true;
  };

  const validate = () => {
    const newErrors: {
      phone?: string;
      fullName?: string;
      password?: string;
      confirmPassword?: string;
    } = {};

    if (!phone.trim()) {
      newErrors.phone = "Vui lòng nhập số điện thoại";
    } else if (!/^[0-9]{10,11}$/.test(phone.trim())) {
      newErrors.phone = "Số điện thoại không hợp lệ";
    }

    if (!fullName.trim()) {
      newErrors.fullName = "Vui lòng nhập họ và tên";
    }

    if (!password) {
      newErrors.password = "Vui lòng nhập mật khẩu";
    } else if (password.length < 6) {
      newErrors.password = "Mật khẩu tối thiểu 6 ký tự";
    } else if (!validatePassword(password)) {
      newErrors.password = "Mật khẩu không đủ mạnh";
    }

    if (!confirmPassword) {
      newErrors.confirmPassword = "Vui lòng nhập lại mật khẩu";
    } else if (password !== confirmPassword) {
      newErrors.confirmPassword = "Mật khẩu không khớp";
    }

    setErrors(newErrors);
    return Object.keys(newErrors).length === 0;
  };

  const handleRegister = async () => {
    if (!validate()) return;

    setLoading(true);
    try {
      const data: RegisterData = {
        phone: phone.trim(),
        password,
        full_name: fullName.trim(),
      };
      const result = await register(data);
      Alert.alert("Thành công", result.message || "Đăng ký thành công", [
        {
          text: "Đăng nhập ngay",
          onPress: () => {
            router.replace("/auth/login");
          },
        },
      ]);
    } catch (error: any) {
      Alert.alert("Lỗi", error.message || "Đăng ký thất bại");
    } finally {
      setLoading(false);
    }
  };

  return (
    <SafeAreaView style={styles.container} edges={["top"]}>
      <KeyboardAvoidingView
        behavior={Platform.OS === "ios" ? "padding" : "height"}
        style={styles.keyboardView}
      >
        <ScrollView
          contentContainerStyle={styles.scrollContent}
          keyboardShouldPersistTaps="handled"
        >
          {/* Header with Back Button */}
          <View style={styles.header}>
            <TouchableOpacity
              onPress={() => router.back()}
              style={styles.backButton}
            >
              <Ionicons name="arrow-back" size={24} color="#111827" />
            </TouchableOpacity>
            <Text style={styles.title}>Đăng ký</Text>
            <View style={styles.backButton} />
          </View>

          {/* Input Fields */}
          <View style={styles.formContainer}>
            {/* Phone with OTP Button */}
            <View style={styles.phoneRow}>
              {/* <View style={styles.phoneInput}>
                <Input
                  placeholder="Nhập số điện thoại của bạn"
                  value={phone}
                  onChangeText={setPhone}
                  icon="call-outline"
                  keyboardType="phone-pad"
                  error={errors.phone}
                />
              </View> */}
              {/* <TouchableOpacity
                style={styles.otpButton}
                onPress={() => {
                  Alert.alert("Thông báo", "Tính năng OTP đang phát triển");
                }}
              >
                <Text style={styles.otpButtonText}>Gửi mã OTP</Text>
              </TouchableOpacity> */}
            </View>

            <Input
              placeholder="Nhập họ và tên đầy đủ"
              value={fullName}
              onChangeText={setFullName}
              icon="person-outline"
              error={errors.fullName}
            />

            <Input
              placeholder="Tạo mật khẩu mạnh"
              value={password}
              onChangeText={setPassword}
              icon="lock-closed-outline"
              secureTextEntry
              error={errors.password}
              info="Cần ít nhất 6 ký tự"
            />

            <Input
              placeholder="Nhập lại mật khẩu của bạn"
              value={confirmPassword}
              onChangeText={setConfirmPassword}
              icon="lock-closed-outline"
              secureTextEntry
              error={errors.confirmPassword}
              info="Nhập lại mật khẩu để xác nhận"
            />

            {/* Terms and Privacy */}
            <View style={styles.termsContainer}>
              <Text style={styles.termsText}>
                Bằng cách đăng ký, bạn đồng ý với{" "}
                <Text style={styles.termsLink}>Điều khoản dịch vụ</Text> và{" "}
                <Text style={styles.termsLink}>Chính sách bảo mật</Text> của
                chúng tôi.
              </Text>
            </View>

            {/* Register Button */}
            <Button
              title="Đăng ký"
              onPress={handleRegister}
              variant="primary"
              loading={loading}
            />
          </View>

          {/* Footer Link */}
          <View style={styles.footer}>
            <Text style={styles.footerText}>Bạn đã có tài khoản? </Text>
            <TouchableOpacity onPress={() => router.replace("/auth/login")}>
              <Text style={styles.footerLink}>Đăng nhập</Text>
            </TouchableOpacity>
          </View>
        </ScrollView>
      </KeyboardAvoidingView>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: "#FFFFFF",
  },
  keyboardView: {
    flex: 1,
  },
  scrollContent: {
    flexGrow: 1,
    paddingHorizontal: 24,
    paddingTop: 16,
    paddingBottom: 32,
  },
  header: {
    flexDirection: "row",
    alignItems: "center",
    justifyContent: "space-between",
    marginBottom: 32,
  },
  backButton: {
    width: 40,
    height: 40,
    alignItems: "center",
    justifyContent: "center",
  },
  title: {
    fontSize: 24,
    fontWeight: "700",
    color: "#111827",
  },
  formContainer: {
    marginTop: 8,
  },
  phoneRow: {
    flexDirection: "row",
    gap: 12,
    marginBottom: 16,
  },
  phoneInput: {
    flex: 1,
  },
  // otpButton: {
  //   paddingHorizontal: 16,
  //   paddingVertical: 16,
  //   borderRadius: 12,
  //   borderWidth: 1,
  //   borderColor: "#D1D5DB",
  //   backgroundColor: "#F9FAFB",
  //   justifyContent: "center",
  //   minHeight: 52,
  // },
  // otpButtonText: {
  //   fontSize: 14,
  //   fontWeight: "500",
  //   color: "#374151",
  // },
  termsContainer: {
    marginBottom: 24,
    marginTop: 8,
  },
  termsText: {
    fontSize: 12,
    color: "#6B7280",
    lineHeight: 18,
  },
  termsLink: {
    color: "#3B82F6",
    fontWeight: "500",
  },
  footer: {
    flexDirection: "row",
    justifyContent: "center",
    alignItems: "center",
    marginTop: 32,
  },
  footerText: {
    fontSize: 14,
    color: "#6B7280",
  },
  footerLink: {
    fontSize: 14,
    color: "#3B82F6",
    fontWeight: "600",
  },
});
