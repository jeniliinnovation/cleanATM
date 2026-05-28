import { useState, useEffect } from 'react';
import TopHeader from '../components/TopHeader';
import { adminAPI } from '../services/api';
import { useAuth } from '../context/AuthContext';
import { useToast } from '../context/ToastContext';
import {
  FileWarning,
  CheckCircle2,
  Clock,
  AlertTriangle,
  TrendingUp,
  BarChart3,
  ArrowUpRight,
  ArrowDownRight,
} from 'lucide-react';
import {
  PieChart, Pie, Cell, ResponsiveContainer,
  BarChart, Bar, XAxis, YAxis, Tooltip, CartesianGrid,
  AreaChart, Area,
} from 'recharts';

import { useTheme } from '../context/ThemeContext';
import { Sun, Moon } from 'lucide-react';

const STATUS_COLORS = {
  'Pending': '#f59e0b',
  'In Progress': '#3b82f6',
  'Resolved': '#10b981',
  'Rejected': '#ef4444'
};

export default function DashboardPage() {
  const [stats, setStats] = useState(null);
  const [loading, setLoading] = useState(true);
  const [branches, setBranches] = useState([]);
  const [selectedBranch, setSelectedBranch] = useState('');
  const { addToast } = useToast();
  const { user } = useAuth();
  const { theme, setTheme } = useTheme();

  useEffect(() => {
    fetchStats();
    fetchBranches();
  }, [user?.bank_code]);

  const fetchBranches = async () => {
    if (!user?.bank_code) return;
    try {
      const res = await adminAPI.getAtms({ bank_code: user.bank_code, per_page: 200 });
      if (res.data.success) {
        const uniqueBranches = [...new Set(res.data.data.atms.map(atm => atm.branch_code).filter(Boolean))].sort();
        setBranches(uniqueBranches);
      }
    } catch (err) {
      console.error('Failed to fetch branches');
    }
  };

  const fetchStats = async (branch = selectedBranch) => {
    try {
      setLoading(true);
      const params = {};
      if (user?.bank_code) params.bank_code = user.bank_code;
      if (branch) params.branch_code = branch;
      const res = await adminAPI.getStats(params);
      if (res.data.success) {
        setStats(res.data.data);
      }
    } catch (err) {
      addToast('Failed to load dashboard stats', 'error');
    } finally {
      setLoading(false);
    }
  };

  const handleBranchChange = (branch) => {
    setSelectedBranch(branch);
    fetchStats(branch);
  };

  if (loading || !stats) {
    return (
      <>
        <TopHeader title="Dashboard" subtitle="Loading analytics..." />
        <div className="page-content">
          <div className="spinner-overlay">
            <div className="spinner" />
          </div>
        </div>
      </>
    );
  }

  const pieData = [
    { name: 'Pending', value: stats.pending || 0 },
    { name: 'In Progress', value: stats.in_progress || 0 },
    { name: 'Resolved', value: stats.resolved || 0 },
    { name: 'Rejected', value: stats.rejected || 0 },
  ].filter((d) => d.value > 0);

  // Synthetic bar data for demo
  const barData = [
    { name: 'Mon', complaints: Math.round(stats.total * 0.12) },
    { name: 'Tue', complaints: Math.round(stats.total * 0.18) },
    { name: 'Wed', complaints: Math.round(stats.total * 0.14) },
    { name: 'Thu', complaints: Math.round(stats.total * 0.22) },
    { name: 'Fri', complaints: Math.round(stats.total * 0.16) },
    { name: 'Sat', complaints: Math.round(stats.total * 0.10) },
    { name: 'Sun', complaints: Math.round(stats.total * 0.08) },
  ];

  // Synthetic area data for resolution trend
  const areaData = [
    { name: 'Week 1', resolved: Math.round(stats.resolved * 0.15) },
    { name: 'Week 2', resolved: Math.round(stats.resolved * 0.30) },
    { name: 'Week 3', resolved: Math.round(stats.resolved * 0.55) },
    { name: 'Week 4', resolved: Math.round(stats.resolved * 0.80) },
    { name: 'Week 5', resolved: stats.resolved },
  ];

  const resolveRate = stats.total > 0 ? ((stats.resolved / stats.total) * 100).toFixed(1) : 0;

  const chartColors = {
    grid: theme === 'dark' ? 'rgba(255,255,255,0.05)' : 'rgba(0,0,0,0.05)',
    tooltipBg: theme === 'dark' ? '#1f2937' : '#ffffff',
    tooltipBorder: theme === 'dark' ? 'rgba(255,255,255,0.1)' : 'rgba(0,0,0,0.1)',
    text: theme === 'dark' ? '#64748b' : '#64748b',
    tooltipText: theme === 'dark' ? '#f1f5f9' : '#0f172a',
  };

  return (
    <>
      <TopHeader
        title={user?.bank_code && user.bank_code !== 'DEFAULT' ? `${user.bank_code} Dashboard` : "Dashboard"}
        subtitle={user?.bank_code && user.bank_code !== 'DEFAULT' ? `Overview for ${user.bank_code} ATM network` : `Welcome back! Here's your overview for ${new Date().toLocaleDateString('en-IN', { weekday: 'long', month: 'long', day: 'numeric' })}`}
      />

      <div className="page-content">
        {/* Filter Section */}
        {user?.bank_code && user.bank_code !== 'DEFAULT' && (
          <div className="dashboard-filters" style={{ marginBottom: 24, display: 'flex', alignItems: 'center', gap: 12 }}>
            <span style={{ fontSize: '0.875rem', color: 'var(--text-secondary)' }}>Filter by Branch:</span>
            <select 
              value={selectedBranch} 
              onChange={(e) => handleBranchChange(e.target.value)}
              style={{
                background: 'var(--bg-card)',
                border: '1px solid var(--border-default)',
                color: 'var(--text-primary)',
                padding: '6px 12px',
                borderRadius: '6px',
                outline: 'none',
                minWidth: 150
              }}
            >
              <option value="">All Branches</option>
              {branches.map(br => (
                <option key={br} value={br}>{br}</option>
              ))}
            </select>
          </div>
        )}

        {/* ─── App Theme Picker ─── */}
        <div className="theme-picker-card">
          <div className="theme-picker-header">
            <div className="theme-picker-title">
              <span className="theme-picker-icon">🎨</span>
              <div>
                <h4>App Theme</h4>
                <p>Choose your preferred display mode</p>
              </div>
            </div>
          </div>
          <div className="theme-options">
            {/* Dark */}
            <button
              id="theme-dark-btn"
              className={`theme-option ${theme === 'dark' ? 'active' : ''}`}
              onClick={() => setTheme('dark')}
            >
              <div className="theme-option-preview dark-preview">
                <div className="preview-sidebar" />
                <div className="preview-body">
                  <div className="preview-bar" />
                  <div className="preview-card" />
                  <div className="preview-card short" />
                </div>
              </div>
              <div className="theme-option-label">
                <Moon size={15} />
                <span>Dark</span>
                {theme === 'dark' && <span className="theme-active-dot" />}
              </div>
            </button>

            {/* Light */}
            <button
              id="theme-light-btn"
              className={`theme-option ${theme === 'light' ? 'active' : ''}`}
              onClick={() => setTheme('light')}
            >
              <div className="theme-option-preview light-preview">
                <div className="preview-sidebar" />
                <div className="preview-body">
                  <div className="preview-bar" />
                  <div className="preview-card" />
                  <div className="preview-card short" />
                </div>
              </div>
              <div className="theme-option-label">
                <Sun size={15} />
                <span>Light</span>
                {theme === 'light' && <span className="theme-active-dot" />}
              </div>
            </button>
          </div>
        </div>

        {/* Stat Cards */}
        <div className="stats-grid">
          {/* ... (keep existing stat blocks but ensure they use CSS variables) ... */}
          <div className="stat-card primary">
            <div className="stat-card-top">
              <div className="stat-card-icon primary">
                <BarChart3 />
              </div>
              <div className="stat-card-trend up">
                <ArrowUpRight size={14} />
                <span>12%</span>
              </div>
            </div>
            <h3>{stats.total}</h3>
            <p>Total Complaints</p>
          </div>

          <div className="stat-card yellow">
            <div className="stat-card-top">
              <div className="stat-card-icon yellow">
                <Clock />
              </div>
              <div className="stat-card-trend down">
                <ArrowDownRight size={14} />
                <span>5%</span>
              </div>
            </div>
            <h3>{stats.pending}</h3>
            <p>Pending Review</p>
          </div>

          <div className="stat-card blue">
            <div className="stat-card-top">
              <div className="stat-card-icon blue">
                <AlertTriangle />
              </div>
              <div className="stat-card-trend up">
                <ArrowUpRight size={14} />
                <span>8%</span>
              </div>
            </div>
            <h3>{stats.in_progress}</h3>
            <p>In Progress</p>
          </div>

          <div className="stat-card green">
            <div className="stat-card-top">
              <div className="stat-card-icon green">
                <CheckCircle2 />
              </div>
              <div className="stat-card-trend up">
                <ArrowUpRight size={14} />
                <span>{resolveRate}%</span>
              </div>
            </div>
            <h3>{stats.resolved}</h3>
            <p>Resolved</p>
          </div>

          <div className="stat-card red">
            <div className="stat-card-top">
              <div className="stat-card-icon red">
                <FileWarning />
              </div>
              <div className="stat-card-trend none">
                <TrendingUp size={14} />
                <span>0%</span>
              </div>
            </div>
            <h3>{stats.rejected || 0}</h3>
            <p>Rejected</p>
          </div>
        </div>

        {/* Charts */}
        <div className="charts-grid">
          <div className="chart-card">
            <h3>Complaint Status Distribution</h3>
            <ResponsiveContainer width="100%" height={280}>
              <PieChart>
                <Pie
                  data={pieData}
                  cx="50%"
                  cy="50%"
                  innerRadius={70}
                  outerRadius={110}
                  paddingAngle={4}
                  dataKey="value"
                  label={({ name, percent }) => `${name} ${(percent * 100).toFixed(0)}%`}
                >
                  {pieData.map((entry, index) => (
                    <Cell key={index} fill={STATUS_COLORS[entry.name] || '#64748b'} />
                  ))}
                </Pie>
                <Tooltip
                  contentStyle={{
                    background: chartColors.tooltipBg,
                    border: `1px solid ${chartColors.tooltipBorder}`,
                    borderRadius: 8,
                    color: chartColors.tooltipText,
                  }}
                  itemStyle={{ color: chartColors.tooltipText }}
                />
              </PieChart>
            </ResponsiveContainer>
          </div>

          <div className="chart-card">
            <h3>Weekly Complaint Volume</h3>
            <ResponsiveContainer width="100%" height={280}>
              <BarChart data={barData}>
                <CartesianGrid strokeDasharray="3 3" stroke={chartColors.grid} vertical={false} />
                <XAxis dataKey="name" tick={{ fill: chartColors.text, fontSize: 12 }} axisLine={false} tickLine={false} />
                <YAxis tick={{ fill: chartColors.text, fontSize: 12 }} axisLine={false} tickLine={false} />
                <Tooltip
                  contentStyle={{
                    background: chartColors.tooltipBg,
                    border: `1px solid ${chartColors.tooltipBorder}`,
                    borderRadius: 8,
                    color: chartColors.tooltipText,
                  }}
                  itemStyle={{ color: chartColors.tooltipText }}
                  cursor={{ fill: 'var(--surface-1)' }}
                />
                <Bar dataKey="complaints" fill="#3b82f6" radius={[6, 6, 0, 0]} />
              </BarChart>
            </ResponsiveContainer>
          </div>

          <div className="chart-card" style={{ gridColumn: '1 / -1' }}>
            <h3>Resolution Trend</h3>
            <ResponsiveContainer width="100%" height={260}>
              <AreaChart data={areaData}>
                <defs>
                  <linearGradient id="gradientGreen" x1="0" y1="0" x2="0" y2="1">
                    <stop offset="5%" stopColor="#10b981" stopOpacity={0.3} />
                    <stop offset="95%" stopColor="#10b981" stopOpacity={0} />
                  </linearGradient>
                </defs>
                <CartesianGrid strokeDasharray="3 3" stroke={chartColors.grid} vertical={false} />
                <XAxis dataKey="name" tick={{ fill: chartColors.text, fontSize: 12 }} axisLine={false} tickLine={false} />
                <YAxis tick={{ fill: chartColors.text, fontSize: 12 }} axisLine={false} tickLine={false} />
                <Tooltip
                  contentStyle={{
                    background: chartColors.tooltipBg,
                    border: `1px solid ${chartColors.tooltipBorder}`,
                    borderRadius: 8,
                    color: chartColors.tooltipText,
                  }}
                  itemStyle={{ color: chartColors.tooltipText }}
                />
                <Area
                  type="monotone"
                  dataKey="resolved"
                  stroke="#10b981"
                  strokeWidth={2}
                  fillOpacity={1}
                  fill="url(#gradientGreen)"
                />
              </AreaChart>
            </ResponsiveContainer>
          </div>
        </div>
      </div>
    </>
  );
}
