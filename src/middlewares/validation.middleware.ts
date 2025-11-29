import { Request, Response, NextFunction } from 'express';
import { ZodTypeAny, ZodError } from 'zod';
import ApiError from '@/shared/utils/ApiError';
import { httpStatus } from '@/shared/utils/httpStatus';

export const validate = (schema: ZodTypeAny) => async (req: Request, res: Response, next: NextFunction) => {
  try {
    await schema.parseAsync({
      body: req.body,
      query: req.query,
      params: req.params,
    });
    next();
  } catch (error) {
    if (error instanceof ZodError) {
      const errorMessages = error.issues.map((err) => `${err.path.join('.')}: ${err.message}`).join(', ');
      return next(new ApiError(httpStatus.BAD_REQUEST, errorMessages));
    }
    next(error);
  }
};
