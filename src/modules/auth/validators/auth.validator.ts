import { z } from 'zod';
import { isEmail } from '@/shared/helper/common.validators';

export const registerSchema = z.object({
  body: z.object({
    email: isEmail,
    password: z
      .string()
      .min(6, 'Password must be at least 6 characters')
      .max(20, 'Password must be at most 20 characters'), 
    name: z.string().min(2, 'Name must be at least 2 characters').optional(),
    phone: z.string().regex(/^[0-9]{10,11}$/, 'Invalid phone number').optional(),
  }).strict(),
});

export const loginSchema = z.object({
  body: z.object({
    email: isEmail,
    password: z.string().min(1, 'Password is required'),
  }).strict(),
});

export const verifyOtpSchema = z.object({
  body: z.object({
    email: isEmail,
    otpCode: z.string().length(6, 'OTP code must be 6 characters'),
  }).strict(),
});

export const resendOtpSchema = z.object({
  body: z.object({
    email: isEmail,
  }).strict(),
});

export const refreshTokenSchema = z.object({
  body: z.object({
    refreshToken: z.string().min(1, 'Refresh token is required'),
  }).strict(),
});

export const forgotPasswordSchema = z.object({
  body: z.object({
    email: isEmail,
  }).strict(),
});

export const resetPasswordSchema = z.object({
  body: z.object({
    email: isEmail,
    otpCode: z.string().length(6, 'OTP code must be 6 characters'),
    newPassword: z
      .string()
      .min(6, 'Password must be at least 6 characters')
      .max(20, 'Password must be at most 20 characters'),
  }).strict(),
});

export type RegisterInput = z.infer<typeof registerSchema>['body'];
export type LoginInput = z.infer<typeof loginSchema>['body'];
export type VerifyOtpInput = z.infer<typeof verifyOtpSchema>['body'];
export type ResendOtpInput = z.infer<typeof resendOtpSchema>['body'];
export type RefreshTokenInput = z.infer<typeof refreshTokenSchema>['body'];
export type ForgotPasswordInput = z.infer<typeof forgotPasswordSchema>['body'];
export type ResetPasswordInput = z.infer<typeof resetPasswordSchema>['body'];
