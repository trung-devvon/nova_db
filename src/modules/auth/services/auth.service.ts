import prisma from '@/core/db';
import { hashPassword, comparePassword } from '@/shared/utils/hash.util';
import { mailService } from '@/core/mail';
import ApiError from '@/shared/utils/ApiError';
import { httpStatus } from '@/shared/utils/httpStatus';
import { OtpService } from './otp.service';
import { JwtService } from './jwt.service';
import { RegisterInput, LoginInput, VerifyOtpInput } from '../validators/auth.validator';
import { User, AuthProvider } from '@prisma/client';
import { verifyRefreshToken } from '@/shared/utils/jwt.util';
import { getInfoData } from '@/shared/utils/fn';

export class AuthService {
  private otpService: OtpService;
  private jwtService: JwtService;

  constructor() {
    this.otpService = new OtpService();
    this.jwtService = new JwtService();
  }

  /**
   * Register a new user with LOCAL provider
   */
  async register(data: RegisterInput): Promise<{ user: Partial<User>; message: string }> {
    // Check if user already exists
    const existingUser = await prisma.user.findUnique({
      where: { email: data.email },
    });

    if (existingUser) {
      if (existingUser.isVerified) {
        throw new ApiError(httpStatus.BAD_REQUEST, 'Email đã được đăng ký');
      }
      // If user exists but not verified, resend OTP
      const otpCode = this.otpService.generateOtpCode();
      const otpExpiry = this.otpService.getOtpExpiry();

      await prisma.user.update({
        where: { id: existingUser.id },
        data: {
          otpCode,
          otpExpiry,
          passwordHash: await hashPassword(data.password),
          name: data.name || existingUser.name,
          phone: data.phone || existingUser.phone,
        },
      });

      mailService.sendOtpEmail(data.email, otpCode, data.name).catch((err) => {
        console.error('[mail]: Failed to send OTP email', err);
      });

      return {
        user: {
          email: existingUser.email,
          name: data.name || existingUser.name,
        },
        message: 'Mã OTP đã được gửi lại. Vui lòng kiểm tra email.',
      };
    }

    // Create new user
    const passwordHash = await hashPassword(data.password);
    const otpCode = this.otpService.generateOtpCode();
    const otpExpiry = this.otpService.getOtpExpiry();

    const user = await prisma.user.create({
      data: {
        email: data.email,
        name: data.name,
        phone: data.phone,
        passwordHash,
        authProvider: AuthProvider.LOCAL,
        otpCode,
        otpExpiry,
        isVerified: false,
      },
    });

    // Send OTP email
    mailService.sendOtpEmail(data.email, otpCode, data.name).catch((err) => {
      console.error('[mail]: Failed to send OTP email', err);
    });

    return {
      user: {
        email: user.email,
        name: user.name,
      },
      message: 'Đăng ký thành công! Vui lòng kiểm tra email để xác thực tài khoản.',
    };
  }

  /**
   * Verify OTP code
   */
  async verifyOtp(data: VerifyOtpInput): Promise<{ user: Partial<User>; tokens: { accessToken: string; refreshToken: string } }> {
    const user = await prisma.user.findUnique({
      where: { email: data.email },
    });

    if (!user) {
      throw new ApiError(httpStatus.NOT_FOUND, 'Không tìm thấy tài khoản');
    }

    if (user.isVerified) {
      throw new ApiError(httpStatus.BAD_REQUEST, 'Tài khoản đã được xác thực');
    }

    if (!user.otpCode || user.otpCode !== data.otpCode) {
      throw new ApiError(httpStatus.BAD_REQUEST, 'Mã OTP không chính xác');
    }

    if (this.otpService.isOtpExpired(user.otpExpiry)) {
      throw new ApiError(httpStatus.BAD_REQUEST, 'Mã OTP đã hết hạn');
    }

    // Update user as verified and generate tokens
    const updatedUser = await prisma.user.update({
      where: { id: user.id },
      data: {
        isVerified: true,
        otpCode: null,
        otpExpiry: null,
      },
    });

    // Generate tokens (no welcome email, login directly)
    const tokens = this.jwtService.generateTokens(updatedUser);

    return {
      user: getInfoData({
        fields: ['id', 'email', 'name', 'phone', 'role', 'avatar'],
        object: updatedUser,
      }),
      tokens,
    };
  }

  /**
   * Resend OTP code
   */
  async resendOtp(email: string): Promise<{ message: string }> {
    const user = await prisma.user.findUnique({
      where: { email },
    });

    if (!user) {
      throw new ApiError(httpStatus.NOT_FOUND, 'Không tìm thấy tài khoản');
    }

    if (user.isVerified) {
      throw new ApiError(httpStatus.BAD_REQUEST, 'Tài khoản đã được xác thực');
    }

    const otpCode = this.otpService.generateOtpCode();
    const otpExpiry = this.otpService.getOtpExpiry();

    await prisma.user.update({
      where: { id: user.id },
      data: {
        otpCode,
        otpExpiry,
      },
    });

    mailService.sendOtpEmail(email, otpCode, user.name || undefined).catch((err) => {
      console.error('[mail]: Failed to send OTP email', err);
    });

    return {
      message: 'Mã OTP đã được gửi lại. Vui lòng kiểm tra email.',
    };
  }

  /**
   * Login with email and password
   */
  async login(data: LoginInput): Promise<{ user: Partial<User>; tokens: { accessToken: string; refreshToken: string } }> {
    const user = await prisma.user.findUnique({
      where: { email: data.email },
    });

    if (!user || user.authProvider !== AuthProvider.LOCAL) {
      throw new ApiError(httpStatus.UNAUTHORIZED, 'Email hoặc mật khẩu không chính xác');
    }

    if (!user.isVerified) {
      throw new ApiError(httpStatus.UNAUTHORIZED, 'Tài khoản chưa được xác thực. Vui lòng kiểm tra email.');
    }

    if (!user.passwordHash) {
      throw new ApiError(httpStatus.UNAUTHORIZED, 'Email hoặc mật khẩu không chính xác');
    }

    const isPasswordValid = await comparePassword(data.password, user.passwordHash);

    if (!isPasswordValid) {
      throw new ApiError(httpStatus.UNAUTHORIZED, 'Email hoặc mật khẩu không chính xác');
    }

    const tokens = this.jwtService.generateTokens(user);

    return {
      user: getInfoData({
        fields: ['id', 'email', 'name', 'phone', 'role', 'avatar'],
        object: user,
      }),
      tokens,
    };
  }

  /**
   * Refresh access token
   */
  async refreshToken(refreshToken: string): Promise<{ accessToken: string; refreshToken: string }> {
    try {
      const payload = verifyRefreshToken(refreshToken);

      const user = await prisma.user.findUnique({
        where: { id: payload.userId },
      });

      if (!user || !user.isVerified) {
        throw new ApiError(httpStatus.UNAUTHORIZED, 'Token không hợp lệ');
      }

      const tokens = this.jwtService.generateTokens(user);
      return tokens;
    } catch (error) {
      throw new ApiError(httpStatus.UNAUTHORIZED, 'Token không hợp lệ hoặc đã hết hạn');
    }
  }

  /**
   * Get user profile
   */
  async getProfile(userId: string): Promise<Partial<User>> {
    const user = await prisma.user.findUnique({
      where: { id: userId },
    });

    if (!user) {
      throw new ApiError(httpStatus.NOT_FOUND, 'Không tìm thấy người dùng');
    }

    return getInfoData({
      fields: ['id', 'email', 'name', 'phone', 'role', 'avatar', 'authProvider', 'createdAt'],
      object: user,
    }) as Partial<User>;
  }

  /**
   * Forgot password - Send OTP to email
   */
  async forgotPassword(email: string): Promise<{ message: string }> {
    const user = await prisma.user.findUnique({
      where: { email },
    });

    if (!user) {
      throw new ApiError(httpStatus.NOT_FOUND, 'Không tìm thấy tài khoản với email này');
    }

    if (user.authProvider !== AuthProvider.LOCAL) {
      throw new ApiError(httpStatus.BAD_REQUEST, 'Tài khoản này đăng nhập bằng Google, không thể đặt lại mật khẩu');
    }

    const otpCode = this.otpService.generateOtpCode();
    const otpExpiry = this.otpService.getOtpExpiry();

    await prisma.user.update({
      where: { id: user.id },
      data: {
        otpCode,
        otpExpiry,
      },
    });

    mailService.sendResetPasswordEmail(email, otpCode, user.name || undefined).catch((err) => {
      console.error('[mail]: Failed to send reset password email', err);
    });

    return {
      message: 'Mã OTP đã được gửi đến email của bạn. Vui lòng kiểm tra email.',
    };
  }

  /**
   * Reset password with OTP
   */
  async resetPassword(email: string, otpCode: string, newPassword: string): Promise<{ message: string }> {
    const user = await prisma.user.findUnique({
      where: { email },
    });

    if (!user) {
      throw new ApiError(httpStatus.NOT_FOUND, 'Không tìm thấy tài khoản');
    }

    if (!user.otpCode || user.otpCode !== otpCode) {
      throw new ApiError(httpStatus.BAD_REQUEST, 'Mã OTP không chính xác');
    }

    if (this.otpService.isOtpExpired(user.otpExpiry)) {
      throw new ApiError(httpStatus.BAD_REQUEST, 'Mã OTP đã hết hạn');
    }

    const passwordHash = await hashPassword(newPassword);

    await prisma.user.update({
      where: { id: user.id },
      data: {
        passwordHash,
        otpCode: null,
        otpExpiry: null,
      },
    });

    return {
      message: 'Mật khẩu đã được đặt lại thành công. Bạn có thể đăng nhập với mật khẩu mới.',
    };
  }
}