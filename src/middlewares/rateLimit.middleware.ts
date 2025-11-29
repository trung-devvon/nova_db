import rateLimit from 'express-rate-limit';
import { httpStatus } from '@/shared/utils/httpStatus';

/**
 * General API Limiter
 * Use for public routes like getting tours, products, etc.
 * Allow high traffic for normal browsing experience.
 */
export const apiLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 1000, // Limit each IP to 1000 requests per windowMs
  standardHeaders: true, // Return rate limit info in the `RateLimit-*` headers
  legacyHeaders: false, // Disable the `X-RateLimit-*` headers
  message: {
    code: httpStatus.TOO_MANY_REQUESTS,
    message: 'Quá nhiều yêu cầu từ IP này, vui lòng thử lại sau 15 phút.',
  },
});

/**
 * Auth Limiter
 * Use for sensitive routes like login, register, forgot password.
 * Prevent brute-force attacks and spamming.
 */
export const authLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 20, // Limit each IP to 20 requests per windowMs (approx 1 try per minute on average, or bursts allowed)
  standardHeaders: true,
  legacyHeaders: false,
  message: {
    code: httpStatus.TOO_MANY_REQUESTS,
    message: 'Quá nhiều lần thử đăng nhập/đăng ký. Vui lòng thử lại sau 15 phút.',
  },
});
