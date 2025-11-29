import jwt, { SignOptions } from 'jsonwebtoken';
import { config } from '@/core/config';

export interface JwtPayload {
  userId: string;
  email: string;
  role: string;
}

export const generateAccessToken = (payload: JwtPayload): string => {
  return jwt.sign(payload, config.JWT_SECRET, {
    expiresIn: config.JWT_ACCESS_EXPIRATION,
  } as any);
};

export const generateRefreshToken = (payload: JwtPayload): string => {
  return jwt.sign(payload, config.JWT_REFRESH_SECRET, {
    expiresIn: config.JWT_REFRESH_EXPIRATION,
  } as any);
};

export const verifyAccessToken = (token: string): JwtPayload => {
  return jwt.verify(token, config.JWT_SECRET) as JwtPayload;
};

export const verifyRefreshToken = (token: string): JwtPayload => {
  return jwt.verify(token, config.JWT_REFRESH_SECRET) as JwtPayload;
};
