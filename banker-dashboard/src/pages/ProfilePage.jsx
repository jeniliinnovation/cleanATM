import { useState } from 'react';
import TopHeader from '../components/TopHeader';
import { adminAPI } from '../services/api';
import { useAuth } from '../context/AuthContext';
import { useToast } from '../context/ToastContext';
import { 
  User as UserIcon, 
  Mail, 
  Phone, 
  Lock, 
  Save, 
  ShieldCheck,
  Building2
} from 'lucide-react';

export default function ProfilePage() {
  const { user, login } = useAuth();
  const { addToast } = useToast();
  
  const [profileData, setProfileData] = useState({
    name: user?.name || '',
    mobile: user?.mobile || '',
  });

  const [passwordData, setPasswordData] = useState({
    current_password: '',
    new_password: '',
    new_password_confirmation: '',
  });

  const [savingProfile, setSavingProfile] = useState(false);
  const [savingPassword, setSavingPassword] = useState(false);

  const handleProfileUpdate = async (e) => {
    e.preventDefault();
    if (!profileData.name.trim()) return addToast('Name is required', 'error');
    
    try {
      setSavingProfile(true);
      const res = await adminAPI.updateProfile(profileData);
      if (res.data.success) {
        addToast('Profile updated successfully', 'success');
        // Update local user state if possible (requires a refresh or context update)
      }
    } catch (err) {
      addToast(err.response?.data?.message || 'Failed to update profile', 'error');
    } finally {
      setSavingProfile(false);
    }
  };

  const handlePasswordUpdate = async (e) => {
    e.preventDefault();
    if (passwordData.new_password !== passwordData.new_password_confirmation) {
      return addToast('New passwords do not match', 'error');
    }
    if (passwordData.new_password.length < 6) {
      return addToast('Password must be at least 6 characters', 'error');
    }

    try {
      setSavingPassword(true);
      const res = await adminAPI.changePassword(passwordData);
      if (res.data.success) {
        addToast('Password changed successfully', 'success');
        setPasswordData({
          current_password: '',
          new_password: '',
          new_password_confirmation: '',
        });
      }
    } catch (err) {
      addToast(err.response?.data?.message || 'Failed to change password', 'error');
    } finally {
      setSavingPassword(false);
    }
  };

  return (
    <>
      <TopHeader 
        title="Settings & Profile" 
        subtitle="Manage your administrative account details" 
      />

      <div className="page-content">
        <div className="charts-grid" style={{ gridTemplateColumns: 'repeat(auto-fit, minmax(400px, 1fr))' }}>
          
          {/* Profile Details */}
          <div className="chart-card">
            <div style={{ display: 'flex', alignItems: 'center', gap: 12, marginBottom: 20 }}>
              <div style={{ 
                width: 40, height: 40, borderRadius: '50%', background: 'rgba(59, 130, 246, 0.1)',
                display: 'flex', alignItems: 'center', justifyContent: 'center', color: '#3b82f6'
              }}>
                <UserIcon size={20} />
              </div>
              <h3 style={{ margin: 0 }}>Personal Information</h3>
            </div>

            <form onSubmit={handleProfileUpdate}>
              <div className="form-group">
                <label className="form-label">Full Name</label>
                <div className="form-input-wrapper">
                  <UserIcon />
                  <input 
                    className="form-input"
                    value={profileData.name}
                    onChange={(e) => setProfileData({ ...profileData, name: e.target.value })}
                  />
                </div>
              </div>

              <div className="form-group">
                <label className="form-label">Email Address (Read-only)</label>
                <div className="form-input-wrapper" style={{ opacity: 0.7 }}>
                  <Mail />
                  <input 
                    className="form-input"
                    value={user?.email || ''}
                    disabled
                  />
                </div>
              </div>

              <div className="form-group">
                <label className="form-label">Mobile Number</label>
                <div className="form-input-wrapper">
                  <Phone />
                  <input 
                    className="form-input"
                    value={profileData.mobile}
                    onChange={(e) => setProfileData({ ...profileData, mobile: e.target.value })}
                  />
                </div>
              </div>

              <div className="form-group">
                <label className="form-label">Assigned Bank</label>
                <div className="form-input-wrapper" style={{ opacity: 0.7 }}>
                  <Building2 />
                  <input 
                    className="form-input"
                    value={user?.bank_code || 'Global Administrator'}
                    disabled
                  />
                </div>
              </div>

              <button className="btn btn-primary" type="submit" disabled={savingProfile} style={{ width: '100%', marginTop: 10 }}>
                <Save size={18} />
                {savingProfile ? 'Saving...' : 'Update Profile'}
              </button>
            </form>
          </div>

          {/* Change Password */}
          <div className="chart-card">
            <div style={{ display: 'flex', alignItems: 'center', gap: 12, marginBottom: 20 }}>
              <div style={{ 
                width: 40, height: 40, borderRadius: '50%', background: 'rgba(239, 68, 68, 0.1)',
                display: 'flex', alignItems: 'center', justifyContent: 'center', color: '#ef4444'
              }}>
                <Lock size={20} />
              </div>
              <h3 style={{ margin: 0 }}>Security Settings</h3>
            </div>

            <form onSubmit={handlePasswordUpdate}>
              <div className="form-group">
                <label className="form-label">Current Password</label>
                <div className="form-input-wrapper">
                  <ShieldCheck />
                  <input 
                    type="password"
                    className="form-input"
                    placeholder="••••••••"
                    value={passwordData.current_password}
                    onChange={(e) => setPasswordData({ ...passwordData, current_password: e.target.value })}
                  />
                </div>
              </div>

              <div style={{ padding: '1px', background: 'rgba(255,255,255,0.05)', margin: '20px 0' }} />

              <div className="form-group">
                <label className="form-label">New Password</label>
                <div className="form-input-wrapper">
                  <Lock />
                  <input 
                    type="password"
                    className="form-input"
                    placeholder="Min 6 characters"
                    value={passwordData.new_password}
                    onChange={(e) => setPasswordData({ ...passwordData, new_password: e.target.value })}
                  />
                </div>
              </div>

              <div className="form-group">
                <label className="form-label">Confirm New Password</label>
                <div className="form-input-wrapper">
                  <Lock />
                  <input 
                    type="password"
                    className="form-input"
                    placeholder="••••••••"
                    value={passwordData.new_password_confirmation}
                    onChange={(e) => setPasswordData({ ...passwordData, new_password_confirmation: e.target.value })}
                  />
                </div>
              </div>

              <button className="btn btn-secondary" type="submit" disabled={savingPassword} style={{ width: '100%', marginTop: 10, background: '#ef4444' }}>
                <ShieldCheck size={18} />
                {savingPassword ? 'Changing...' : 'Change Password'}
              </button>
            </form>
          </div>

        </div>
      </div>
    </>
  );
}
