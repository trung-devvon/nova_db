import { User } from '@prisma/client';
import { generateAccessToken, generateRefreshToken, JwtPayload } from '@/shared/utils/jwt.util';

export class JwtService {
  /**
   * Generate tokens for a user
   */
  generateTokens(user: User): { accessToken: string; refreshToken: string } {
    const payload: JwtPayload = {
      userId: user.id,
      email: user.email,
      role: user.role,
    };

    return {
      accessToken: generateAccessToken(payload),
      refreshToken: generateRefreshToken(payload),
    };
  }
}
