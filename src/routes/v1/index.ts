import express from 'express';
import { authRoutes } from '@/modules/auth';

const router = express.Router();

const defaultRoutes = [
  {
    path: '/auth',
    route: authRoutes,
  },
];

defaultRoutes.forEach((route) => {
  router.use(route.path, route.route);
});

export const v1Routes = router;
