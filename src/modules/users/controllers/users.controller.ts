import { Request, Response } from 'express';
import { UsersService } from '../services/users.service';
import { catchAsync } from '@/shared/utils/catchAsync';
import ApiResponse from '@/shared/utils/ApiResponse';
import { httpStatus } from '@/shared/utils/httpStatus';
import { GetUsersInput } from '../validators/users.validator';

export class UsersController {
  private usersService: UsersService;

  constructor() {
    this.usersService = new UsersService();
  }

  /**
   * GET /api/v1/users
   * Get all users (Admin/Sales only)
   */
  getUsers = catchAsync(async (req: Request, res: Response) => {
    const query = req.query as unknown as GetUsersInput;
    const result = await this.usersService.getAllUsers(query);
    new ApiResponse(httpStatus.OK, 'Get users successfully', result).send(res);
  });

  /**
   * GET /api/v1/users/profile
   * Get current user profile
   */
  getProfile = catchAsync(async (req: Request, res: Response) => {
    const userId = (req.user as any)?.userId || (req.user as any)?.id;
    const result = await this.usersService.getUserById(userId);
    new ApiResponse(httpStatus.OK, 'Get profile successfully', result).send(res);
  });
}
