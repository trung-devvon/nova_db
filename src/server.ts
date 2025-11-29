import app from './index';
import prisma from '@/core/db';
import { config } from '@/core/config';

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
