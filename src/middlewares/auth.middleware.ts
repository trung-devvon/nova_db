import { Request, Response, NextFunction } from 'express';
import { verifyAccessToken } from '@/shared/utils/jwt.util';
import ApiError from '@/shared/utils/ApiError';
import { httpStatus } from '@/shared/utils/httpStatus';

/**
 * Middleware to authenticate user using JWT token
 */
export const authenticate = (req: Request, res: Response, next: NextFunction) => {
  try {
    const authHeader = req.headers.authorization;

    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      throw new ApiError(httpStatus.UNAUTHORIZED, 'Token không được cung cấp');
    }

    const token = authHeader.substring(7); // Remove 'Bearer ' prefix

    const payload = verifyAccessToken(token);
    req.user = payload;

    next();
  } catch (error) {
    if (error instanceof ApiError) {
      next(error);
    } else {
      next(new ApiError(httpStatus.UNAUTHORIZED, 'Token không hợp lệ hoặc đã hết hạn'));
    }
  }
};
