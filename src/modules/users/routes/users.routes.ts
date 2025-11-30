import { Router } from 'express';
import { UsersController } from '../controllers/users.controller';
import { validate } from '@/middlewares/validation.middleware';
import { getUsersSchema } from '../validators/users.validator';
import { authenticate } from '@/middlewares/auth.middleware';
import { roleMiddleware } from '@/middlewares/role.middleware';
import { UserRole } from '@prisma/client';
import { apiLimiter } from '@/middlewares/rateLimit.middleware';

const router = Router();
const usersController = new UsersController();

// Apply authentication to all routes
router.use(authenticate);

/**
 * @route   GET /api/v1/users
 * @desc    Get all users
 * @access  Private (Admin, Sales)
 */
router.get(
  '/',
  apiLimiter,
  roleMiddleware([UserRole.ADMIN, UserRole.SALES]),
  validate(getUsersSchema),
  usersController.getUsers
);

/**
 * @route   GET /api/v1/users/profile
 * @desc    Get current user profile
 * @access  Private
 */
router.get('/profile', apiLimiter, usersController.getProfile);

export { router as usersRoutes };
