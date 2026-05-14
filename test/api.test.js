const request = require('supertest');
const app = require('../server'); // Express app

describe('ATM CleanGuard API Endpoint Tests', () => {

  it('GET / should return successful response', async () => {
    const res = await request(app).get('/');
    expect(res.statusCode).toBe(200);
    expect(res.text).toContain('ATM CleanGuard API is running');
  });

  describe('Auth Routes', () => {
    it('POST /v1/auth/register should fail with missing parameters', async () => {
      const res = await request(app).post('/v1/auth/register').send({});
      expect([400, 500]).toContain(res.statusCode);
    });

    it('POST /v1/auth/login should fail and return 400 or 401 for missing data', async () => {
      const res = await request(app).post('/v1/auth/login').send({});
      expect([400, 401, 500]).toContain(res.statusCode);
    });
  });

  describe('Protected Routes (No Bearer Token)', () => {
    const protectedRoutes = [
      { method: 'get', path: '/v1/user/profile' },
      { method: 'get', path: '/v1/atms' },
      { method: 'post', path: '/v1/complaints' },
      { method: 'get', path: '/v1/notifications' }
    ];

    protectedRoutes.forEach(({ method, path }) => {
      it(`${method.toUpperCase()} ${path} should return 401 Unauthorized`, async () => {
        const res = await request(app)[method](path);
        expect(res.statusCode).toBe(401);
      });
    });
  });

  describe('Admin Protected Routes (No Bearer Token)', () => {
    const adminRoutes = [
      { method: 'get', path: '/v1/admin/stats' },
      { method: 'post', path: '/v1/admin/atms' }
    ];

    adminRoutes.forEach(({ method, path }) => {
      it(`${method.toUpperCase()} ${path} should return 401 Unauthorized or 403 Forbidden`, async () => {
        const res = await request(app)[method](path);
        expect([401, 403]).toContain(res.statusCode);
      });
    });
  });
  
});
