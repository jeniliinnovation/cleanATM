import { NavLink, useLocation } from 'react-router-dom';
import { useAuth } from '../context/AuthContext';
import {
  LayoutDashboard,
  MessageSquareWarning,
  MapPin,
  Settings,
  LogOut,
  Shield,
  ChevronLeft,
  ChevronRight,
  User,
} from 'lucide-react';
import { useState } from 'react';

export default function Sidebar({ collapsed, setCollapsed }) {
  const { user, logout } = useAuth();
  const location = useLocation();

  const navItems = [
    { to: '/', icon: <LayoutDashboard />, label: 'Dashboard' },
    { to: '/complaints', icon: <MessageSquareWarning />, label: 'Complaints' },
    { to: '/atms', icon: <MapPin />, label: 'ATM Management' },
    { to: '/profile', icon: <User />, label: 'My Profile' },
    { to: '/settings', icon: <Settings />, label: 'Settings' },
  ];

  const initials = user?.email
    ? user.email.charAt(0).toUpperCase()
    : 'A';

  return (
    <aside className={`sidebar ${collapsed ? 'collapsed' : ''}`}>
      <div className="sidebar-toggle" onClick={() => setCollapsed(!collapsed)}>
        {collapsed ? <ChevronRight /> : <ChevronLeft />}
      </div>

      <div className="sidebar-brand">
        <div className="sidebar-brand-icon">
          <Shield />
        </div>
        <div className="sidebar-brand-text">
          <h1>CleanGuard</h1>
          <span>Banker Portal</span>
        </div>
      </div>

      <nav className="sidebar-nav">
        <div className="nav-section">
          <div className="nav-label">Main Menu</div>
          {navItems.map((item) => (
            <NavLink
              key={item.to}
              to={item.to}
              end={item.to === '/'}
              className={({ isActive }) => `nav-item ${isActive ? 'active' : ''}`}
            >
              {item.icon}
              <span>{item.label}</span>
              {item.badge && <span className="nav-badge">{item.badge}</span>}
            </NavLink>
          ))}
        </div>

        <div className="nav-section">
          <div className="nav-label">Account</div>
          <div className="nav-item" onClick={logout} style={{ cursor: 'pointer' }}>
            <LogOut />
            <span>Sign Out</span>
          </div>
        </div>
      </nav>

      <div className="sidebar-footer">
        <div className="sidebar-footer-avatar">{initials}</div>
        <div className="sidebar-footer-info">
          <p>{user?.bank_code ? `${user.bank_code} Manager` : 'Super Admin'}</p>
          <p>{user?.email || 'admin@cleanguard.com'}</p>
        </div>
      </div>
    </aside>
  );
}
