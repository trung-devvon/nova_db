import { z } from 'zod';
import { UserRole } from '@prisma/client';

export const getUsersSchema = z.object({
  query: z.object({
    page: z.string().regex(/^\d+$/, 'Page must be a number').optional(),
    limit: z.string().regex(/^\d+$/, 'Limit must be a number').optional(),
    search: z.string().optional(),
    role: z.nativeEnum(UserRole).optional(),
    sortBy: z.string().optional(),
    sortOrder: z.enum(['asc', 'desc']).optional(),
  }).strict(),
});

export type GetUsersInput = z.infer<typeof getUsersSchema>['query'];
