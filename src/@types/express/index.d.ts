import { JwtPayload } from '@/shared/utils/jwt.util';
import { User as PrismaUser } from '@prisma/client';

declare global {
  namespace Express {
    // Extend User interface to include both JwtPayload and PrismaUser properties
    interface User extends Partial<JwtPayload>, Partial<PrismaUser> {
      userId?: string; // Explicitly for JWT payload
      id?: string;     // Explicitly for Prisma User
    }
    
    interface Request {
      user?: User;
    }
  }
}
