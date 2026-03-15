import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';
import '../widgets/custom_card.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_alert.dart';
import '../widgets/custom_textarea.dart';

class SOSScreen extends StatefulWidget {
  const SOSScreen({Key? key}) : super(key: key);

  @override
  State<SOSScreen> createState() => _SOSScreenState();
}

class _SOSScreenState extends State<SOSScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _peopleCountController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  String _message = "";
  bool _isSent = false;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _peopleCountController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _handleSendSOS() async {
    // Thu thập thông tin từ các trường nhập liệu
    final String peopleCount = _peopleCountController.text.trim();
    final String phoneContact = _phoneController.text.trim();
    final String situation = _message.trim();
    
    // Vị trí (Tạm thời hardcode, có thể lấy từ GPS thật sau này)
    final String locationInfo = "16.0544° N, 108.2022° E (Đà Nẵng, Việt Nam)";

    // Số điện thoại nhận SMS khẩn cấp (Sẽ được cập nhật sau)
    final String emergencyNumber = "0123456789"; 

    // Tạo nội dung tin nhắn dưới định dạng JSON
    final Map<String, dynamic> smsData = {
      "type": "SOS",
      "location": locationInfo,
      "people_count": peopleCount.isNotEmpty ? peopleCount : "Unknown",
      "contact_phone": phoneContact.isNotEmpty ? phoneContact : "Unknown",
      "situation": situation.isNotEmpty ? situation : "Đang gặp nguy hiểm!",
    };
    final String smsBody = jsonEncode(smsData);

    // Format URI cho SMS
    final Uri smsUri = Uri(
      scheme: 'sms',
      path: emergencyNumber,
      queryParameters: <String, String>{
        'body': smsBody,
      },
    );

    try {
      if (await canLaunchUrl(smsUri)) {
        await launchUrl(smsUri);
      } else {
        // Fallback or show error
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Không thể mở ứng dụng tin nhắn!')),
          );
        }
      }
    } catch (e) {
      debugPrint("Lỗi khi mở SMS: $e");
    }

    // Hiển thị trạng thái "đã gửi" trên UI (tuỳ chọn)
    setState(() {
      _isSent = true;
    });
    Timer(const Duration(seconds: 5), () {
      if (mounted) {
        setState(() {
          _isSent = false;
          // _message = ""; // Chọn giữ lại hoặc xoá tuỳ nhu cầu
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SOS', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildEmergencyHeader(),
            const SizedBox(height: 16),
            if (_isSent) _buildSuccessMessage(),
            if (_isSent) const SizedBox(height: 16),
            _buildQuickActions(),
            const SizedBox(height: 16),
            _buildSOSForm(),
            const SizedBox(height: 16),
            _buildWarning(),
          ],
        ),
      ),
    );
  }

  Widget _buildEmergencyHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFE53935), Color(0xFFC62828)], // red-600 to red-800
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.red.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            top: -50,
            right: -50,
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Column(
            children: [
              FadeTransition(
                opacity: _pulseController,
                child: const Icon(
                  Icons.error_outline,
                  size: 80,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'GỬI LỜI CẦU CỨU',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Chức năng khẩn cấp - Sử dụng khi gặp nguy hiểm',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessMessage() {
    return CustomAlert(
      icon: const Icon(Icons.check_circle, color: Colors.green),
      title: 'Đã gửi thành công!',
      description:
          'Lực lượng cứu hộ đã nhận được thông tin và sẽ liên hệ với bạn sớm nhất.',
      borderColor: Colors.green.shade500,
      backgroundColor: Colors.green.shade50,
      titleColor: Colors.green.shade700,
      descriptionColor: Colors.green.shade600,
    );
  }

  Widget _buildQuickActions() {
    return CustomCard(
      borderColor: Colors.red.shade200,
      children: [
        CustomCardHeader(
          title: CustomCardTitle('Gọi khẩn cấp', color: Colors.red.shade600),
        ),
        CustomCardContent(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final buttonWidth = (constraints.maxWidth - 12) / 2;
              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _buildQuickCallBtn(
                    '113 - Cảnh sát',
                    Icons.local_police,
                    Colors.blue,
                    buttonWidth,
                  ),
                  _buildQuickCallBtn(
                    '114 - Cứu hỏa',
                    Icons.fire_extinguisher,
                    Colors.red,
                    buttonWidth,
                  ),
                  _buildQuickCallBtn(
                    '115 - Cấp cứu',
                    Icons.local_hospital,
                    Colors.green,
                    buttonWidth,
                  ),
                  _buildQuickCallBtn(
                    '112 - SOS',
                    Icons.support_agent,
                    Colors.orange,
                    buttonWidth,
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildQuickCallBtn(
    String label,
    IconData icon,
    MaterialColor color,
    double width,
  ) {
    return SizedBox(
      width: width,
      child: CustomButton(
        onPressed: () {},
        variant: CustomButtonVariant.outline,
        borderColor: color.shade500,
        height: 80,
        customChild: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color.shade600, size: 24),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.black87,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSOSForm() {
    return CustomCard(
      children: [
        const CustomCardHeader(title: CustomCardTitle('Gửi thông tin cầu cứu')),
        CustomCardContent(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Location Info
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          color: Colors.blue.shade600,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Vị trí của bạn',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '16.0544° N, 108.2022° E',
                      style: TextStyle(color: Colors.black54, fontSize: 13),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Đà Nẵng, Việt Nam',
                      style: TextStyle(color: Colors.black54, fontSize: 13),
                    ),
                    const SizedBox(height: 8),
                    CustomButton(
                      text: 'Cập nhật vị trí',
                      onPressed: () {},
                      variant: CustomButtonVariant.link,
                      foregroundColor: Colors.blue.shade600,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Custom fields
              const Text(
                'Số lượng người cần cứu',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _peopleCountController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: 'Nhập số lượng người (VD: 3)',
                  hintStyle: TextStyle(color: Theme.of(context).hintColor),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              const Text(
                'Số điện thoại liên hệ',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  hintText: 'Nhập số điện thoại của bạn',
                  hintStyle: TextStyle(color: Theme.of(context).hintColor),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Message
              const Text(
                'Tình trạng hiện tại (Mô tả chi tiết)',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              CustomTextarea(
                hintText:
                    'Ví dụ: Tôi đang bị mắc kẹt trên mái nhà do nước lũ, có người già và trẻ nhỏ...',
                value: _message,
                onChanged: (val) => setState(() => _message = val),
              ),
              const SizedBox(height: 16),

              // Attachments
              CustomButton(
                text: 'Đính kèm ảnh/video',
                icon: const Icon(Icons.camera_alt, size: 18),
                onPressed: () {},
                variant: CustomButtonVariant.outline,
                fullWidth: true,
              ),
              const SizedBox(height: 16),

              // Send Button
              CustomButton(
                text: _isSent ? 'Đã gửi' : 'Gửi cầu cứu ngay',
                icon: const Icon(Icons.send, size: 20),
                onPressed: _isSent ? null : _handleSendSOS,
                backgroundColor: Colors.red.shade600,
                fullWidth: true,
                height: 56,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildWarning() {
    return const CustomAlert(
      icon: Icon(Icons.warning_amber_rounded, size: 20),
      title: 'Lưu ý',
      description:
          'Chỉ sử dụng chức năng này khi thực sự gặp nguy hiểm. Thông tin sai lệch có thể bị xử phạt theo quy định pháp luật.',
      borderColor: Colors.grey,
      backgroundColor: Colors.transparent,
    );
  }
}
