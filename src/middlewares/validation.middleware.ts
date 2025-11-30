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
      const errorMessages = error.issues.map((err) => {
        const path = err.path.join('.');
        return { path: path.replace('body.', ''), message: err.message };
      });

      // Filter to keep only the first error per field
      const uniqueErrors = errorMessages.filter((err, index, self) =>
        index === self.findIndex((t) => t.path === err.path)
      );

      const formattedMessage = uniqueErrors.map((e) => `${e.path}: ${e.message}`).join(', ');
      return next(new ApiError(httpStatus.BAD_REQUEST, formattedMessage));
    }
    next(error);
  }
};
