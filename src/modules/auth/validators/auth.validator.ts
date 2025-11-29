import { z } from 'zod';

export const registerSchema = z.object({
  body: z.object({
    email: z.string().email('Email không hợp lệ'),
    password: z
      .string()
      .min(6, 'Mật khẩu phải có ít nhất 6 ký tự')
      .max(50, 'Mật khẩu không được quá 50 ký tự'),
    name: z.string().min(2, 'Tên phải có ít nhất 2 ký tự').optional(),
    phone: z.string().regex(/^[0-9]{10,11}$/, 'Số điện thoại không hợp lệ').optional(),
  }),
});

export const loginSchema = z.object({
  body: z.object({
    email: z.string().email('Email không hợp lệ'),
    password: z.string().min(1, 'Mật khẩu không được để trống'),
  }),
});

export const verifyOtpSchema = z.object({
  body: z.object({
    email: z.string().email('Email không hợp lệ'),
    otpCode: z.string().length(6, 'Mã OTP phải có 6 ký tự'),
  }),
});

export const resendOtpSchema = z.object({
  body: z.object({
    email: z.string().email('Email không hợp lệ'),
  }),
});

export const refreshTokenSchema = z.object({
  body: z.object({
    refreshToken: z.string().min(1, 'Refresh token không được để trống'),
  }),
});

export const forgotPasswordSchema = z.object({
  body: z.object({
    email: z.string().email('Email không hợp lệ'),
  }),
});

export const resetPasswordSchema = z.object({
  body: z.object({
    email: z.string().email('Email không hợp lệ'),
    otpCode: z.string().length(6, 'Mã OTP phải có 6 ký tự'),
    newPassword: z
      .string()
      .min(6, 'Mật khẩu phải có ít nhất 6 ký tự')
      .max(50, 'Mật khẩu không được quá 50 ký tự'),
  }),
});

export type RegisterInput = z.infer<typeof registerSchema>['body'];
export type LoginInput = z.infer<typeof loginSchema>['body'];
export type VerifyOtpInput = z.infer<typeof verifyOtpSchema>['body'];
export type ResendOtpInput = z.infer<typeof resendOtpSchema>['body'];
export type RefreshTokenInput = z.infer<typeof refreshTokenSchema>['body'];
export type ForgotPasswordInput = z.infer<typeof forgotPasswordSchema>['body'];
export type ResetPasswordInput = z.infer<typeof resetPasswordSchema>['body'];
