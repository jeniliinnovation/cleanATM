import { createContext, useContext, useState, useCallback, useEffect, useRef } from 'react';
import { authAPI, setAuthToken, getAuthToken, isTokenExpired, getTokenRemainingMs } from '../services/api';
import { useToast } from './ToastContext';

const AuthContext = createContext(null);

// Session timeout = 30 minutes of inactivity
const SESSION_TIMEOUT_MS = 30 * 60 * 1000;
// Warn 2 minutes before timeout
const SESSION_WARNING_MS = 2 * 60 * 1000;

export function AuthProvider({ children }) {
  const [user, setUser] = useState(null);
  const [loading, setLoading] = useState(false);
  const [sessionWarning, setSessionWarning] = useState(false);
  const lastActivityRef = useRef(Date.now());
  const timeoutRef = useRef(null);
  const warningRef = useRef(null);
  const { addToast } = useToast();

  // Track user activity
  const updateActivity = useCallback(() => {
    lastActivityRef.current = Date.now();
    setSessionWarning(false);
  }, []);

  // Setup activity listeners
  useEffect(() => {
    if (!user) return;

    const events = ['mousedown', 'keydown', 'scroll', 'touchstart', 'mousemove'];
    events.forEach((event) => window.addEventListener(event, updateActivity, { passive: true }));

    return () => {
      events.forEach((event) => window.removeEventListener(event, updateActivity));
    };
  }, [user, updateActivity]);

  // Session timeout checker
  useEffect(() => {
    if (!user) return;

    const checkSession = () => {
      const elapsed = Date.now() - lastActivityRef.current;

      // Check JWT token expiry
      if (isTokenExpired()) {
        logout();
        addToast('Session expired. Please login again.', 'error');
        return;
      }

      // Check inactivity timeout
      if (elapsed >= SESSION_TIMEOUT_MS) {
        logout();
        addToast('Session timed out due to inactivity.', 'error');
        return;
      }

      // Show warning before timeout
      if (elapsed >= SESSION_TIMEOUT_MS - SESSION_WARNING_MS) {
        setSessionWarning(true);
      }
    };

    timeoutRef.current = setInterval(checkSession, 10000); // Check every 10s

    return () => {
      if (timeoutRef.current) clearInterval(timeoutRef.current);
      if (warningRef.current) clearTimeout(warningRef.current);
    };
  }, [user]);

  const login = useCallback(async (email, password, bankCode) => {
    setLoading(true);
    try {
      // Input validation
      if (!email || !password) {
        throw new Error('Email and password are required');
      }
      // Basic email format check
      const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
      if (!emailRegex.test(email)) {
        throw new Error('Please enter a valid email address');
      }

      const response = await authAPI.login(email, password, bankCode);

      if (response.data.success && response.data.token) {
        const token = response.data.token;
        setAuthToken(token);

        // Decode token to get user info
        const payload = JSON.parse(atob(token.split('.')[1]));
        setUser({
          id: payload.admin_id,
          role: payload.role,
          bank_code: payload.bank_code,
          email: email,
        });
        lastActivityRef.current = Date.now();
        addToast('Login successful! Welcome back.', 'success');
        return true;
      } else {
        throw new Error('Login failed');
      }
    } catch (error) {
      const msg = error.response?.data?.message || error.message || 'Login failed';
      addToast(msg, 'error');
      return false;
    } finally {
      setLoading(false);
    }
  }, [addToast]);

  const logout = useCallback(() => {
    setUser(null);
    setAuthToken(null);
    setSessionWarning(false);
    if (timeoutRef.current) clearInterval(timeoutRef.current);
  }, []);

  const extendSession = useCallback(() => {
    lastActivityRef.current = Date.now();
    setSessionWarning(false);
    addToast('Session extended.', 'info');
  }, [addToast]);

  return (
    <AuthContext.Provider
      value={{
        user,
        loading,
        login,
        logout,
        sessionWarning,
        extendSession,
        isAuthenticated: !!user && !isTokenExpired(),
      }}
    >
      {children}
    </AuthContext.Provider>
  );
}

export const useAuth = () => {
  const context = useContext(AuthContext);
  if (!context) throw new Error('useAuth must be used within AuthProvider');
  return context;
};
