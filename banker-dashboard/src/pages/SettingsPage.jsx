import { useState } from 'react';
import TopHeader from '../components/TopHeader';
import { useAuth } from '../context/AuthContext';
import { useToast } from '../context/ToastContext';
import {
  Shield,
  Bell,
  Moon,
  Globe,
  Lock,
  LogOut,
  Fingerprint,
  Clock,
  Eye,
  Database,
  Info,
} from 'lucide-react';

export default function SettingsPage() {
  const { user, logout } = useAuth();
  const { addToast } = useToast();
  const [settings, setSettings] = useState({
    notifications: true,
    darkMode: true,
    autoRefresh: true,
    sessionTimeout: true,
    twoFactor: false,
  });

  const toggleSetting = (key) => {
    setSettings((prev) => ({ ...prev, [key]: !prev[key] }));
    addToast(`Setting updated`, 'info');
  };

  return (
    <>
      <TopHeader title="Settings" subtitle="Manage your dashboard preferences" />

      <div className="page-content">
        {/* Account Info */}
        <div className="card" style={{ marginBottom: 24 }}>
          <div className="card-header">
            <h3>
              <Shield size={18} style={{ marginRight: 8, verticalAlign: 'middle' }} />
              Account Information
            </h3>
          </div>
          <div className="card-body">
            <div className="detail-grid">
              <div className="detail-item">
                <label>Role</label>
                <p style={{ textTransform: 'capitalize' }}>{user?.role || 'Admin'}</p>
              </div>
              <div className="detail-item">
                <label>Bank Code</label>
                <p>{user?.bank_code || 'DEFAULT'}</p>
              </div>
              <div className="detail-item">
                <label>Email</label>
                <p>{user?.email || '-'}</p>
              </div>
              <div className="detail-item">
                <label>Session</label>
                <p style={{ color: 'var(--success)' }}>● Active</p>
              </div>
            </div>
          </div>
        </div>

        {/* Preferences */}
        <div className="card" style={{ marginBottom: 24 }}>
          <div className="card-header">
            <h3>
              <Globe size={18} style={{ marginRight: 8, verticalAlign: 'middle' }} />
              Preferences
            </h3>
          </div>
          <div className="card-body">
            <div className="settings-section">
              <div className="settings-row">
                <div className="settings-row-left">
                  <h4><Bell size={16} style={{ marginRight: 8, verticalAlign: 'middle' }} /> Notifications</h4>
                  <p>Receive alerts for new complaints and status changes</p>
                </div>
                <div
                  className={`toggle ${settings.notifications ? 'active' : ''}`}
                  onClick={() => toggleSetting('notifications')}
                />
              </div>

              <div className="settings-row">
                <div className="settings-row-left">
                  <h4><Moon size={16} style={{ marginRight: 8, verticalAlign: 'middle' }} /> Dark Mode</h4>
                  <p>Use dark theme for the dashboard</p>
                </div>
                <div
                  className={`toggle ${settings.darkMode ? 'active' : ''}`}
                  onClick={() => toggleSetting('darkMode')}
                />
              </div>

              <div className="settings-row">
                <div className="settings-row-left">
                  <h4><Database size={16} style={{ marginRight: 8, verticalAlign: 'middle' }} /> Auto Refresh</h4>
                  <p>Automatically refresh data every 30 seconds</p>
                </div>
                <div
                  className={`toggle ${settings.autoRefresh ? 'active' : ''}`}
                  onClick={() => toggleSetting('autoRefresh')}
                />
              </div>
            </div>
          </div>
        </div>

        {/* Security */}
        <div className="card" style={{ marginBottom: 24 }}>
          <div className="card-header">
            <h3>
              <Lock size={18} style={{ marginRight: 8, verticalAlign: 'middle' }} />
              Security
            </h3>
          </div>
          <div className="card-body">
            <div className="settings-section">
              <div className="settings-row">
                <div className="settings-row-left">
                  <h4><Clock size={16} style={{ marginRight: 8, verticalAlign: 'middle' }} /> Session Timeout</h4>
                  <p>Auto-logout after 30 minutes of inactivity</p>
                </div>
                <div
                  className={`toggle ${settings.sessionTimeout ? 'active' : ''}`}
                  onClick={() => toggleSetting('sessionTimeout')}
                />
              </div>

              <div className="settings-row">
                <div className="settings-row-left">
                  <h4><Fingerprint size={16} style={{ marginRight: 8, verticalAlign: 'middle' }} /> Two-Factor Auth</h4>
                  <p>Add an extra layer of security to your account</p>
                </div>
                <div
                  className={`toggle ${settings.twoFactor ? 'active' : ''}`}
                  onClick={() => toggleSetting('twoFactor')}
                />
              </div>

              <div className="settings-row">
                <div className="settings-row-left">
                  <h4><Eye size={16} style={{ marginRight: 8, verticalAlign: 'middle' }} /> Security Features</h4>
                  <p>In-memory JWT, input sanitization, XSS protection, CSRF-safe</p>
                </div>
                <span className="status-badge resolved">Active</span>
              </div>
            </div>
          </div>
        </div>

        {/* About */}
        <div className="card" style={{ marginBottom: 24 }}>
          <div className="card-header">
            <h3>
              <Info size={18} style={{ marginRight: 8, verticalAlign: 'middle' }} />
              About
            </h3>
          </div>
          <div className="card-body">
            <div className="detail-grid">
              <div className="detail-item">
                <label>Application</label>
                <p>CleanGuard Banker Dashboard</p>
              </div>
              <div className="detail-item">
                <label>Version</label>
                <p>2.0.0</p>
              </div>
              <div className="detail-item">
                <label>Framework</label>
                <p>React 18 + Vite</p>
              </div>
              <div className="detail-item">
                <label>API Server</label>
                <p>Express.js v5</p>
              </div>
            </div>
          </div>
        </div>

        {/* Logout */}
        <button className="btn btn-danger btn-lg" onClick={logout} style={{ marginTop: 8 }}>
          <LogOut size={18} />
          Sign Out
        </button>
      </div>
    </>
  );
}
