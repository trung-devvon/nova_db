// src/core/config/index.ts
import dotenv from 'dotenv';
import path from 'path';
import { z } from 'zod';

// Load environment variables based on NODE_ENV
const envFile = `.env.${process.env.NODE_ENV || 'development'}`;
const dotenvResult = dotenv.config({ path: path.resolve(process.cwd(), envFile) });

if (dotenvResult.error) {
  console.error(`Could not load ${envFile} file. Please check if it exists and is readable.`);
  throw dotenvResult.error;
}

const envVarsSchema = z.object({
  NODE_ENV: z.enum(['development', 'production']).default('development'),
  PORT: z.coerce.number().default(3000),
  DATABASE_URL: z.string().url(),
  JWT_SECRET: z.string().min(1, 'JWT_SECRET is required'),
  JWT_REFRESH_SECRET: z.string().min(1, 'JWT_REFRESH_SECRET is required'),
  JWT_ACCESS_EXPIRATION: z.string().default('15m'),
  JWT_REFRESH_EXPIRATION: z.string().default('7d'),
  EMAIL_HOST: z.string().default('smtp.gmail.com'),
  EMAIL_PORT: z.coerce.number().default(587),
  EMAIL_USER: z.string().min(1, 'EMAIL_USER is required'),
  EMAIL_PASSWORD: z.string().min(1, 'EMAIL_PASSWORD is required'),
  EMAIL_FROM: z.string().email().default('noreply@novacrm.com'),
  EMAIL_FROM_NAME: z.string().default('NOVA CRM'),
  FRONTEND_URL: z.string().url().default('http://localhost:5173'),
  GOOGLE_CLIENT_ID: z.string().min(1, 'GOOGLE_CLIENT_ID is required'),
  GOOGLE_CLIENT_SECRET: z.string().min(1, 'GOOGLE_CLIENT_SECRET is required'),
  GOOGLE_CALLBACK_URL: z.string().url().default('http://localhost:3000/api/v1/auth/google/callback'),
});

const parsedEnv = envVarsSchema.safeParse(process.env);

if (!parsedEnv.success) {
  console.error('❌ Invalid environment variables:', parsedEnv.error.flatten().fieldErrors);
  throw new Error('Invalid environment variables.');
}

export const config = parsedEnv.data;
