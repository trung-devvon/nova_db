import { registry } from '@/docs/openapi.registry';
import { z } from 'zod';
import {
  registerSchema,
  loginSchema,
  verifyOtpSchema,
  resendOtpSchema,
  refreshTokenSchema,
  forgotPasswordSchema,
  resetPasswordSchema,
} from './validators/auth.validator';

// --- Schemas ---
registry.register('RegisterInput', registerSchema);
registry.register('LoginInput', loginSchema);
registry.register('VerifyOtpInput', verifyOtpSchema);
registry.register('ResendOtpInput', resendOtpSchema);
registry.register('RefreshTokenInput', refreshTokenSchema);
registry.register('ForgotPasswordInput', forgotPasswordSchema);
registry.register('ResetPasswordInput', resetPasswordSchema);

// --- Paths ---

// Register
registry.registerPath({
  method: 'post',
  path: '/auth/register',
  tags: ['Auth'],
  summary: 'Register a new user',
  request: {
    body: {
      content: {
        'application/json': {
          schema: registerSchema.shape.body,
        },
      },
    },
  },
  responses: {
    201: {
      description: 'User registered successfully',
      content: {
        'application/json': {
          schema: z.object({
            code: z.number(),
            message: z.string(),
            data: z.object({
              user: z.object({ id: z.string(), email: z.string() }),
            }),
          }),
        },
      },
    },
    400: { description: 'Validation error' },
  },
});

// Login
registry.registerPath({
  method: 'post',
  path: '/auth/login',
  tags: ['Auth'],
  summary: 'Login user',
  request: {
    body: {
      content: {
        'application/json': {
          schema: loginSchema.shape.body,
        },
      },
    },
  },
  responses: {
    200: {
      description: 'Login successfully',
      content: {
        'application/json': {
          schema: z.object({
            code: z.number(),
            message: z.string(),
            data: z.object({
              user: z.object({ id: z.string(), email: z.string() }),
              tokens: z.object({ accessToken: z.string(), refreshToken: z.string() }),
            }),
          }),
        },
      },
    },
    401: { description: 'Invalid credentials' },
  },
});

// Logout
registry.registerPath({
  method: 'post',
  path: '/auth/logout',
  tags: ['Auth'],
  summary: 'Logout user',
  responses: {
    200: { description: 'Logout successfully' },
  },
});

// Verify OTP
registry.registerPath({
  method: 'post',
  path: '/auth/verify-otp',
  tags: ['Auth'],
  summary: 'Verify OTP',
  request: {
    body: {
      content: {
        'application/json': {
          schema: verifyOtpSchema.shape.body,
        },
      },
    },
  },
  responses: {
    200: { description: 'OTP verified successfully' },
    400: { description: 'Invalid or expired OTP' },
  },
});

// Resend OTP
registry.registerPath({
  method: 'post',
  path: '/auth/resend-otp',
  tags: ['Auth'],
  summary: 'Resend OTP',
  request: {
    body: {
      content: {
        'application/json': {
          schema: resendOtpSchema.shape.body,
        },
      },
    },
  },
  responses: {
    200: { description: 'OTP resent successfully' },
  },
});

// Refresh Token
registry.registerPath({
  method: 'post',
  path: '/auth/refresh-token',
  tags: ['Auth'],
  summary: 'Refresh access token',
  request: {
    body: {
      content: {
        'application/json': {
          schema: refreshTokenSchema.shape.body,
        },
      },
    },
  },
  responses: {
    200: { description: 'Token refreshed successfully' },
  },
});

// Forgot Password
registry.registerPath({
  method: 'post',
  path: '/auth/forgot-password',
  tags: ['Auth'],
  summary: 'Request password reset',
  request: {
    body: {
      content: {
        'application/json': {
          schema: forgotPasswordSchema.shape.body,
        },
      },
    },
  },
  responses: {
    200: { description: 'OTP sent to email' },
  },
});

// Reset Password
registry.registerPath({
  method: 'post',
  path: '/auth/reset-password',
  tags: ['Auth'],
  summary: 'Reset password with OTP',
  request: {
    body: {
      content: {
        'application/json': {
          schema: resetPasswordSchema.shape.body,
        },
      },
    },
  },
  responses: {
    200: { description: 'Password reset successfully' },
  },
});

// Get Profile
registry.registerPath({
  method: 'get',
  path: '/auth/profile',
  tags: ['Auth'],
  summary: 'Get current user profile',
  security: [{ bearerAuth: [] }],
  responses: {
    200: { description: 'Profile retrieved successfully' },
    401: { description: 'Unauthorized' },
  },
});
