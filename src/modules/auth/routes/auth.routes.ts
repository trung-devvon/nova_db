import { Router } from 'express';
import { AuthController } from '../controllers/auth.controller';
import { validate } from '@/middlewares/validation.middleware';
import {
  registerSchema,
  loginSchema,
  verifyOtpSchema,
  resendOtpSchema,
  refreshTokenSchema,
  forgotPasswordSchema,
  resetPasswordSchema,
} from '../validators/auth.validator';
import { authenticate } from '@/middlewares/auth.middleware';

const router = Router();
const authController = new AuthController();

/**
 * @route   POST /api/v1/auth/register
 * @desc    Register a new user
 * @access  Public
 */
router.post('/register', validate(registerSchema), authController.register);

/**
 * @route   POST /api/v1/auth/verify-otp
 * @desc    Verify OTP code
 * @access  Public
 */
router.post('/verify-otp', validate(verifyOtpSchema), authController.verifyOtp);

/**
 * @route   POST /api/v1/auth/resend-otp
 * @desc    Resend OTP code
 * @access  Public
 */
router.post('/resend-otp', validate(resendOtpSchema), authController.resendOtp);

/**
 * @route   POST /api/v1/auth/login
 * @desc    Login user
 * @access  Public
 */
router.post('/login', validate(loginSchema), authController.login);

/**
 * @route   POST /api/v1/auth/refresh-token
 * @desc    Refresh access token
 * @access  Public
 */
router.post('/refresh-token', validate(refreshTokenSchema), authController.refreshToken);

/**
 * @route   GET /api/v1/auth/profile
 * @desc    Get user profile
 * @access  Private
 */
router.get('/profile', authenticate, authController.getProfile);

/**
 * @route   POST /api/v1/auth/forgot-password
 * @desc    Request password reset OTP
 * @access  Public
 */
router.post('/forgot-password', validate(forgotPasswordSchema), authController.forgotPassword);

/**
 * @route   POST /api/v1/auth/reset-password
 * @desc    Reset password with OTP
 * @access  Public
 */
router.post('/reset-password', validate(resetPasswordSchema), authController.resetPassword);

/**
 * @route   GET /api/v1/auth/google
 * @desc    Redirect to Google OAuth
 * @access  Public
 */
router.get('/google', authController.googleAuth);

/**
 * @route   GET /api/v1/auth/google/callback
 * @desc    Google OAuth callback
 * @access  Public
 */
router.get('/google/callback', ...authController.googleCallback);

export { router as authRoutes };
