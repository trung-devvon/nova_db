import { Request, Response, NextFunction } from 'express';
import { AuthService } from '../services/auth.service';
import { catchAsync } from '@/shared/utils/catchAsync';
import ApiResponse from '@/shared/utils/ApiResponse';
import ApiError from '@/shared/utils/ApiError';
import { httpStatus } from '@/shared/utils/httpStatus';
import { RegisterInput, LoginInput, VerifyOtpInput, ResendOtpInput, RefreshTokenInput } from '../validators/auth.validator';
import { User } from '@prisma/client';
import passport from '../strategies/google.strategy';
import { JwtService } from '../services/jwt.service';

export class AuthController {
  private authService: AuthService;
  private jwtService: JwtService;

  constructor() {
    this.authService = new AuthService();
    this.jwtService = new JwtService();
  }

  /**
   * POST /api/v1/auth/register
   */
  register = catchAsync(async (req: Request, res: Response) => {
    const data: RegisterInput = req.body;
    const result = await this.authService.register(data);
    new ApiResponse(httpStatus.CREATED, result.message, result.user).send(res);
  });

  /**
   * POST /api/v1/auth/verify-otp
   */
  verifyOtp = catchAsync(async (req: Request, res: Response) => {
    const data: VerifyOtpInput = req.body;
    const result = await this.authService.verifyOtp(data);
    new ApiResponse(httpStatus.OK, 'Xác thực thành công', result).send(res);
  });

  /**
   * POST /api/v1/auth/resend-otp
   */
  resendOtp = catchAsync(async (req: Request, res: Response) => {
    const data: ResendOtpInput = req.body;
    const result = await this.authService.resendOtp(data.email);
    new ApiResponse(httpStatus.OK, result.message).send(res);
  });

  /**
   * POST /api/v1/auth/login
   */
  login = catchAsync(async (req: Request, res: Response) => {
    const data: LoginInput = req.body;
    const result = await this.authService.login(data);
    new ApiResponse(httpStatus.OK, 'Đăng nhập thành công', result).send(res);
  });

  /**
   * POST /api/v1/auth/refresh-token
   */
  refreshToken = catchAsync(async (req: Request, res: Response) => {
    const data: RefreshTokenInput = req.body;
    const tokens = await this.authService.refreshToken(data.refreshToken);
    new ApiResponse(httpStatus.OK, 'Làm mới token thành công', tokens).send(res);
  });

  /**
   * GET /api/v1/auth/profile
   */
  getProfile = catchAsync(async (req: Request, res: Response) => {
    const userId = (req.user as any)?.userId;
    if (!userId) {
      throw new ApiError(httpStatus.UNAUTHORIZED, 'Không tìm thấy thông tin xác thực');
    }
    const profile = await this.authService.getProfile(userId);
    new ApiResponse(httpStatus.OK, 'Lấy thông tin thành công', profile).send(res);
  });

  /**
   * POST /api/v1/auth/forgot-password
   */
  forgotPassword = catchAsync(async (req: Request, res: Response) => {
    const { email } = req.body;
    const result = await this.authService.forgotPassword(email);
    new ApiResponse(httpStatus.OK, result.message).send(res);
  });

  /**
   * POST /api/v1/auth/reset-password
   */
  resetPassword = catchAsync(async (req: Request, res: Response) => {
    const { email, otpCode, newPassword } = req.body;
    const result = await this.authService.resetPassword(email, otpCode, newPassword);
    new ApiResponse(httpStatus.OK, result.message).send(res);
  });

  /**
   * GET /api/v1/auth/google
   * Redirect to Google OAuth
   */
  googleAuth = passport.authenticate('google', {
    scope: ['profile', 'email'],
    session: false,
  });

  /**
   * GET /api/v1/auth/google/callback
   * Google OAuth callback
   */
  googleCallback = [
    passport.authenticate('google', { session: false, failureRedirect: '/login' }),
    catchAsync(async (req: Request, res: Response) => {
      const user = req.user as any as User;
      
      if (!user) {
        throw new ApiError(httpStatus.UNAUTHORIZED, 'Xác thực Google thất bại');
      }

      // Generate JWT tokens
      const tokens = this.jwtService.generateTokens(user);

      // Redirect to frontend with tokens
      const frontendUrl = process.env.FRONTEND_URL || 'http://localhost:5173';
      res.redirect(`${frontendUrl}/auth/callback?accessToken=${tokens.accessToken}&refreshToken=${tokens.refreshToken}`);
    }),
  ];
}
