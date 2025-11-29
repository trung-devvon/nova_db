import express, { Express } from 'express';
import helmet from 'helmet';
import cors from 'cors';
import compression from 'compression';
import hpp from 'hpp';
import cookieParser from 'cookie-parser';
import prisma from '@/core/db';
import { config } from '@/core/config';
import swaggerUi from 'swagger-ui-express';
import yaml from 'js-yaml';
import fs from 'fs';
import path from 'path';
import { v1Routes } from '@/routes/v1';
import ApiError from '@/shared/utils/ApiError';
import { httpStatus } from '@/shared/utils/httpStatus';

const app: Express = express();

// --- Middlewares ---
// Set security HTTP headers
app.use(helmet());

// Enable CORS
app.use(cors());

// Prevent HTTP Parameter Pollution
app.use(hpp());

// Gzip compression
app.use(compression());

// Parse cookies
app.use(cookieParser());

// Body parsing
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// --- API Docs ---
if (config.NODE_ENV === 'development') {
  try {
    const openApiPath = path.resolve(process.cwd(), 'docs/api/openapi.yaml');
    const file = fs.readFileSync(openApiPath, 'utf8');
    const swaggerDocument = yaml.load(file);

    if (typeof swaggerDocument === 'object' && swaggerDocument !== null) {
      app.use('/api-docs', swaggerUi.serve, swaggerUi.setup(swaggerDocument));
    } else {
      console.error('Failed to load a valid OpenAPI specification.');
    }
  } catch (error) {
    console.error('Could not read or parse OpenAPI YAML file.', error);
  }
}

// --- API Routes ---
app.use('/api/v1', v1Routes);

// --- Error Handling ---
// Send back a 404 error for any unknown api request
app.use((req, res, next) => {
  next(new ApiError(httpStatus.NOT_FOUND, 'Not found'));
});


const startServer = async () => {
  try {
    // Check database connection
    await prisma.$connect();
    console.log('[db]: Connected to database successfully.');

    app.listen(config.PORT, () => {
      console.log(`[server]: Server is running at http://localhost:${config.PORT}`);
      console.log(`[server]: Current environment: ${config.NODE_ENV}`);
    });
  } catch (error) {
    console.error('[db]: Could not connect to the database.', error);
    process.exit(1);
  }
};

startServer();
