import { useAuth } from '../context/AuthContext';
import { Bell, Search, RefreshCw, Sun, Moon } from 'lucide-react';
import { useTheme } from '../context/ThemeContext';

export default function TopHeader({ title, subtitle }) {
  const { user } = useAuth();
  const { theme, toggleTheme } = useTheme();

  const initials = user?.email
    ? user.email.charAt(0).toUpperCase()
    : 'A';

  return (
    <header className="top-header">
      <div className="header-left">
        <h2>{title}</h2>
        {subtitle && <p>{subtitle}</p>}
      </div>
      <div className="header-right">
        <button 
          className="header-btn" 
          onClick={toggleTheme} 
          title={theme === 'dark' ? 'Switch to Light Mode' : 'Switch to Dark Mode'}
        >
          {theme === 'dark' ? <Sun /> : <Moon />}
        </button>
        <button className="header-btn" title="Refresh">
          <RefreshCw />
        </button>
        <button className="header-btn" title="Notifications">
          <Bell />
          <span className="notification-dot"></span>
        </button>
        <div className="header-avatar" title={user?.email}>
          {initials}
        </div>
      </div>
    </header>
  );
}
