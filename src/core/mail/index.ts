import nodemailer, { Transporter } from 'nodemailer';
import ejs from 'ejs';
import path from 'path';
import { config } from '@/core/config';

class MailService {
  private transporter: Transporter;
  private templatesPath: string;

  constructor() {
    this.transporter = nodemailer.createTransport({
      host: config.EMAIL_HOST,
      port: config.EMAIL_PORT,
      secure: false,
      auth: {
        user: config.EMAIL_USER,
        pass: config.EMAIL_PASSWORD,
      },
    });

    this.templatesPath = path.join(__dirname, 'templates');
  }

  /**
   * Send OTP email for registration
   */
  async sendOtpEmail(to: string, otpCode: string, name?: string): Promise<void> {
    const html = await ejs.renderFile(path.join(this.templatesPath, 'otp.ejs'), {
      otpCode,
      name,
      appName: config.EMAIL_FROM_NAME,
    });

    await this.transporter.sendMail({
      from: `"${config.EMAIL_FROM_NAME}" <${config.EMAIL_FROM}>`,
      to,
      subject: `Mã OTP xác thực tài khoản - ${config.EMAIL_FROM_NAME}`,
      html,
    });
  }

  /**
   * Send OTP email for password reset
   */
  async sendResetPasswordEmail(to: string, otpCode: string, name?: string): Promise<void> {
    const html = await ejs.renderFile(path.join(this.templatesPath, 'reset-password.ejs'), {
      otpCode,
      name,
      appName: config.EMAIL_FROM_NAME,
    });

    await this.transporter.sendMail({
      from: `"${config.EMAIL_FROM_NAME}" <${config.EMAIL_FROM}>`,
      to,
      subject: `Đặt lại mật khẩu - ${config.EMAIL_FROM_NAME}`,
      html,
    });
  }
}

export const mailService = new MailService();
