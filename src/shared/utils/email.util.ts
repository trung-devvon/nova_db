import nodemailer from 'nodemailer';
import { config } from '@/core/config';

const transporter = nodemailer.createTransport({
  host: config.EMAIL_HOST,
  port: config.EMAIL_PORT,
  secure: false,
  auth: {
    user: config.EMAIL_USER,
    pass: config.EMAIL_PASSWORD,
  },
});

export const sendOtpEmail = async (to: string, otpCode: string, name?: string): Promise<void> => {
  const mailOptions = {
    from: `"${config.EMAIL_FROM_NAME}" <${config.EMAIL_FROM}>`,
    to,
    subject: 'Xác thực tài khoản - NOVA CRM',
    html: `
      <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
        <h2 style="color: #333;">Xin chào ${name || 'bạn'},</h2>
        <p>Cảm ơn bạn đã đăng ký tài khoản tại NOVA CRM.</p>
        <p>Mã OTP của bạn là:</p>
        <div style="background-color: #f4f4f4; padding: 15px; text-align: center; font-size: 24px; font-weight: bold; letter-spacing: 5px; margin: 20px 0;">
          ${otpCode}
        </div>
        <p>Mã OTP này có hiệu lực trong <strong>10 phút</strong>.</p>
        <p>Nếu bạn không thực hiện yêu cầu này, vui lòng bỏ qua email này.</p>
        <hr style="margin: 30px 0; border: none; border-top: 1px solid #eee;">
        <p style="color: #999; font-size: 12px;">Email này được gửi tự động, vui lòng không trả lời.</p>
      </div>
    `,
  };

  await transporter.sendMail(mailOptions);
};

export const sendWelcomeEmail = async (to: string, name: string): Promise<void> => {
  const mailOptions = {
    from: `"${config.EMAIL_FROM_NAME}" <${config.EMAIL_FROM}>`,
    to,
    subject: 'Chào mừng đến với NOVA CRM',
    html: `
      <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
        <h2 style="color: #333;">Chào mừng ${name}!</h2>
        <p>Tài khoản của bạn đã được xác thực thành công.</p>
        <p>Bạn có thể bắt đầu sử dụng các dịch vụ của chúng tôi ngay bây giờ.</p>
        <a href="${config.FRONTEND_URL}/login" style="display: inline-block; padding: 12px 24px; background-color: #007bff; color: white; text-decoration: none; border-radius: 5px; margin: 20px 0;">
          Đăng nhập ngay
        </a>
        <p>Trân trọng,<br>Đội ngũ NOVA CRM</p>
      </div>
    `,
  };

  await transporter.sendMail(mailOptions);
};
