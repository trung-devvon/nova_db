import { Request, Response, NextFunction } from 'express';
import ApiError from '@/shared/utils/ApiError';
import { config } from '@/core/config';
import { httpStatus } from '@/shared/utils/httpStatus';

export const errorHandler = (err: any, req: Request, res: Response, next: NextFunction) => {
  let { statusCode, message } = err;

  if (config.NODE_ENV === 'production' && !err.isOperational) {
    statusCode = httpStatus.INTERNAL_SERVER_ERROR;
    message = 'Internal Server Error';
  }

  res.locals.errorMessage = err.message;

  const response = {
    code: statusCode || httpStatus.INTERNAL_SERVER_ERROR,
    message,
    // stack: err.stack, // Stack trace removed as requested
  };

  if (config.NODE_ENV === 'development') {
    console.error(err);
  }

  res.status(statusCode || httpStatus.INTERNAL_SERVER_ERROR).send(response);
};

export const errorConverter = (err: any, req: Request, res: Response, next: NextFunction) => {
  let error = err;
  if (!(error instanceof ApiError)) {
    const statusCode =
      error.statusCode || error instanceof Error ? httpStatus.BAD_REQUEST : httpStatus.INTERNAL_SERVER_ERROR;
    const message = error.message || String(error);
    error = new ApiError(statusCode, message, false, err.stack);
  }
  next(error);
};
