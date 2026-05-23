import axios from 'axios';

const API_BASE = 'http://localhost:5000/v1';

// Create axios instance
const api = axios.create({
  baseURL: API_BASE,
  timeout: 15000,
  headers: {
    'Content-Type': 'application/json',
  },
});

// Token management - stored in memory (not localStorage) for XSS protection
let authToken = null;
let tokenExpiresAt = null;

export const setAuthToken = (token) => {
  authToken = token;
  // Decode JWT to get expiry (without library - simple base64 decode)
  if (token) {
    try {
      const payload = JSON.parse(atob(token.split('.')[1]));
      tokenExpiresAt = payload.exp ? payload.exp * 1000 : null;
    } catch {
      tokenExpiresAt = null;
    }
  } else {
    tokenExpiresAt = null;
  }
};

export const getAuthToken = () => authToken;

export const isTokenExpired = () => {
  if (!tokenExpiresAt) return true;
  return Date.now() >= tokenExpiresAt;
};

export const getTokenRemainingMs = () => {
  if (!tokenExpiresAt) return 0;
  return Math.max(0, tokenExpiresAt - Date.now());
};

// Request interceptor - attach token
api.interceptors.request.use(
  (config) => {
    if (authToken) {
      // Check if token is expired before making request
      if (isTokenExpired()) {
        return Promise.reject({ isExpired: true, message: 'Token expired' });
      }
      config.headers.Authorization = `Bearer ${authToken}`;
    }
    return config;
  },
  (error) => Promise.reject(error)
);

// Response interceptor - handle auth errors
api.interceptors.response.use(
  (response) => response,
  (error) => {
    if (error.response?.status === 401 || error.response?.status === 403) {
      // Clear token on auth failure
      authToken = null;
      tokenExpiresAt = null;
      // Redirect to login
      window.location.href = '/login';
    }
    return Promise.reject(error);
  }
);

// ==========================================
// Auth API
// ==========================================
export const authAPI = {
  login: (email, password, bank_code) =>
    api.post('/admin/auth/login', { email, password, bank_code }),
};

// ==========================================
// Admin API
// ==========================================
export const adminAPI = {
  // Stats
  getStats: (params = {}) => api.get('/admin/stats', { params }),

  // Complaints
  getComplaints: (params = {}) => api.get('/admin/complaints', { params }),
  getComplaintDetails: (id) => api.get(`/admin/complaints/${id}`),
  updateComplaintStatus: (id, data) => api.put(`/admin/complaints/${id}/status`, data),

  // ATMs
  getAtms: (params = {}) => api.get('/atms', { params }),
  addAtm: (data) => api.post('/admin/atms', data),
  updateAtm: (id, data) => api.put(`/admin/atms/${id}`, data),
  deleteAtm: (id) => api.delete(`/admin/atms/${id}`),
  updateProfile: (data) => api.put('/user/profile', data),
  changePassword: (data) => api.put('/user/change-password', data),
};

export default api;
