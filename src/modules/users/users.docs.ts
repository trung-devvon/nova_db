import { registry } from '@/docs/openapi.registry';
import { z } from 'zod';
import { getUsersSchema } from './validators/users.validator';

// --- Schemas ---
registry.register('GetUsersQuery', getUsersSchema);

// --- Paths ---

// Get All Users
registry.registerPath({
  method: 'get',
  path: '/users',
  tags: ['Users'],
  summary: 'Get all users (Admin/Sales)',
  security: [{ bearerAuth: [] }],
  request: {
    query: getUsersSchema.shape.query,
  },
  responses: {
    200: {
      description: 'List of users',
      content: {
        'application/json': {
          schema: z.object({
            code: z.number(),
            message: z.string(),
            data: z.object({
              users: z.array(
                z.object({
                  id: z.string(),
                  email: z.string(),
                  name: z.string().nullable(),
                  role: z.string(),
                })
              ),
              pagination: z.object({
                page: z.number(),
                limit: z.number(),
                total: z.number(),
                totalPages: z.number(),
              }),
            }),
          }),
        },
      },
    },
    403: { description: 'Forbidden' },
  },
});

// Get Profile (Users Module)
registry.registerPath({
  method: 'get',
  path: '/users/profile',
  tags: ['Users'],
  summary: 'Get current user profile',
  security: [{ bearerAuth: [] }],
  responses: {
    200: { description: 'Profile retrieved successfully' },
  },
});
