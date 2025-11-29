import { z } from 'zod';

// Generic error schema for consistent error responses
export const ErrorDto = z.object({
  success: z.literal(false),
  code: z.number(),
  message: z.string(),
});

// Specific error schemas
export const BadRequestDto = ErrorDto.extend({
  code: z.literal(400),
});

export const UnauthorizedDto = ErrorDto.extend({
  code: z.literal(401),
});

export const ForbiddenDto = ErrorDto.extend({
  code: z.literal(403),
});

export const NotFoundDto = ErrorDto.extend({
  code: z.literal(404),
});

export const ConflictDto = ErrorDto.extend({
  code: z.literal(409),
});

export const TooManyRequestsDto = ErrorDto.extend({
  code: z.literal(429),
});
