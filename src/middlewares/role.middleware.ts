import { Request, Response, NextFunction } from 'express';
import { UserRole } from '@prisma/client';
import ApiError from '@/shared/utils/ApiError';
import { httpStatus } from '@/shared/utils/httpStatus';

/**
 * Middleware to restrict access based on user roles
 * @param allowedRoles Array of roles allowed to access the route
 */
export const roleMiddleware = (allowedRoles: UserRole[]) => {
  return (req: Request, res: Response, next: NextFunction) => {
    if (!req.user) {
      return next(new ApiError(httpStatus.UNAUTHORIZED, 'Login first'));
    }

    // Check if user role is in the allowed roles list
    // Note: req.user.role comes from JWT payload or database query
    const user = req.user as any;
    if (!allowedRoles.includes(user.role as UserRole)) {
      return next(new ApiError(httpStatus.FORBIDDEN, 'không đủ quyền truy cập'));
    }

    next();
  };
};
