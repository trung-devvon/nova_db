import request from 'supertest';
import app from '../../src/index';

describe('Auth API', () => {
  describe('POST /api/v1/auth/register', () => {
    it('should register a new user successfully', async () => {
      const res = await request(app).post('/api/v1/auth/register').send({
        email: `test_${Date.now()}@example.com`,
        password: 'password123',
        name: 'Test User',
      });

      expect(res.statusCode).toEqual(201);
      expect(res.body.data.user).toHaveProperty('id');
      expect(res.body.data.user).toHaveProperty('email');
    });

    it('should return 400 if email is invalid', async () => {
      const res = await request(app).post('/api/v1/auth/register').send({
        email: 'invalid-email',
        password: 'password123',
      });

      expect(res.statusCode).toEqual(400);
    });
  });
});
