// src/validators/common.validators.ts
import { z } from 'zod';

/**
 * Validate UUID v4 format
 */
export const isUuid = z.string().refine(
  (val) => /^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i.test(val),
  { message: 'Invalid UUID format' }
);

/**
 * Validate email format (basic but effective)
 */
export const isEmail = z.string().refine(
  (val) => /^\S+@\S+\.\S+$/.test(val.trim()),
  { message: 'Invalid email format' }
);

/**
 * Validate URL format (uses native URL constructor)
 */
export const isURL = z.string().refine(
  (val) => {
    try {
      new URL(val);
      return true;
    } catch {
      return false;
    }
  },
  { message: 'Invalid URL format' }
);