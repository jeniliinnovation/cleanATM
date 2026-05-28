import { useState, useEffect, useCallback } from 'react';
import TopHeader from '../components/TopHeader';
import { adminAPI } from '../services/api';
import { useAuth } from '../context/AuthContext';
import { useToast } from '../context/ToastContext';
import {
  Search,
  Eye,
  X,
  ChevronLeft,
  ChevronRight,
  FileWarning,
  Clock,
  CheckCircle2,
  XCircle,
  AlertTriangle,
  Send,
  Filter,
  Image as ImageIcon,
  RefreshCw,
} from 'lucide-react';

const STATUS_OPTIONS = ['pending', 'in_progress', 'resolved', 'rejected'];

const COMPLAINT_TYPE_LABELS = {
  dirty: '🧹 Dirty',
  ac_issue: '❄️ AC Issue',
  garbage: '🗑️ Garbage',
  damage: '🔨 Damage',
  no_power: '⚡ No Power',
  other: '📋 Other',
};

export default function ComplaintsPage() {
  const [complaints, setComplaints] = useState([]);
  const [loading, setLoading] = useState(true);
  const [pagination, setPagination] = useState({ total: 0, page: 1, pages: 1 });
  const [statusFilter, setStatusFilter] = useState('');
  const [selectedComplaint, setSelectedComplaint] = useState(null);
  const [showDetailModal, setShowDetailModal] = useState(false);
  const [showUpdateModal, setShowUpdateModal] = useState(false);
  const [updateData, setUpdateData] = useState({ status: '', remarks: '' });
  const [updating, setUpdating] = useState(false);
  const [branches, setBranches] = useState([]);
  const [branchFilter, setBranchFilter] = useState('');
  const { addToast } = useToast();
  const { user } = useAuth();

  const fetchComplaints = useCallback(async (page = 1, silent = false) => {
    try {
      if (!silent) setLoading(true);
      const params = { page };
      if (statusFilter) params.status = statusFilter;
      if (branchFilter) params.branch_code = branchFilter;
      if (user?.bank_code) params.bank_code = user.bank_code;
      const res = await adminAPI.getComplaints(params);
      if (res.data.success) {
        setComplaints(res.data.data);
        setPagination(res.data.pagination);
      }
    } catch (err) {
      addToast('Failed to load complaints', 'error');
    } finally {
      setLoading(false);
    }
  }, [statusFilter, addToast]);

  useEffect(() => {
    fetchComplaints(1);

    // Auto-refresh every 30 seconds
    const interval = setInterval(() => {
      fetchComplaints(pagination.page, true);
    }, 30000);

    return () => clearInterval(interval);
  }, [fetchComplaints, branchFilter, pagination.page]);

  useEffect(() => {
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
    fetchBranches();
  }, [user?.bank_code]);

  const openDetail = async (complaint) => {
    try {
      const res = await adminAPI.getComplaintDetails(complaint.complaint_id);
      if (res.data.success) {
        setSelectedComplaint(res.data.data);
        setShowDetailModal(true);
      }
    } catch {
      // Fallback to local data
      setSelectedComplaint(complaint);
      setShowDetailModal(true);
    }
  };

  const openUpdateModal = (complaint) => {
    setSelectedComplaint(complaint);
    setUpdateData({ status: complaint.status, remarks: complaint.remarks || '' });
    setShowUpdateModal(true);
  };

  const handleUpdateStatus = async () => {
    if (!updateData.status) {
      addToast('Please select a status', 'error');
      return;
    }
    // Sanitize remarks
    const sanitizedRemarks = updateData.remarks
      .replace(/<[^>]*>/g, '')
      .trim();

    try {
      setUpdating(true);
      const payload = { status: updateData.status };
      if (sanitizedRemarks) payload.remarks = sanitizedRemarks;
      if (updateData.status === 'resolved') {
        payload.resolved_at = new Date().toISOString();
      }

      await adminAPI.updateComplaintStatus(selectedComplaint.complaint_id, payload);
      addToast('Complaint status updated successfully', 'success');
      setShowUpdateModal(false);
      fetchComplaints(pagination.page);
    } catch (err) {
      addToast(err.response?.data?.message || 'Failed to update status', 'error');
    } finally {
      setUpdating(false);
    }
  };

  const formatDate = (dateStr) => {
    if (!dateStr) return '-';
    return new Date(dateStr).toLocaleDateString('en-IN', {
      day: 'numeric',
      month: 'short',
      year: 'numeric',
      hour: '2-digit',
      minute: '2-digit',
    });
  };

  const getStatusIcon = (status) => {
    switch (status) {
      case 'pending': return <Clock size={14} />;
      case 'in_progress': return <AlertTriangle size={14} />;
      case 'resolved': return <CheckCircle2 size={14} />;
      case 'rejected': return <XCircle size={14} />;
      default: return null;
    }
  };

  return (
    <>
      <TopHeader
        title={user?.bank_code && user.bank_code !== 'DEFAULT' ? `${user.bank_code} Complaints` : "Complaints"}
        subtitle={user?.bank_code && user.bank_code !== 'DEFAULT' ? `Manage complaints for ${user.bank_code} ATMs` : "Manage and resolve ATM complaints"}
      />

      <div className="page-content">
        {/* Filters */}
        <div className="filters-bar">
          <div onClick={() => setStatusFilter('')}
            style={!statusFilter ? {} : { background: 'var(--surface-2)' }}
            className={`filter-chip ${!statusFilter ? 'active' : ''}`}
          >
            <Filter size={14} />
            All
          </div>
          {STATUS_OPTIONS.map((s) => (
            <div
              key={s}
              className={`filter-chip ${statusFilter === s ? 'active' : ''}`}
              onClick={() => setStatusFilter(s)}
            >
              {getStatusIcon(s)}
              {s.replace('_', ' ')}
            </div>
          ))}

          {/* Branch Filter Dropdown */}
          {user?.bank_code && user.bank_code !== 'DEFAULT' && branches.length > 0 && (
            <div style={{ marginLeft: 'auto', display: 'flex', alignItems: 'center', gap: 10 }}>
              <span style={{ fontSize: '0.82rem', color: 'var(--text-secondary)' }}>Branch:</span>
              <select
                className="form-select"
                style={{ width: 'auto', minWidth: 150, height: 36, padding: '0 12px' }}
                value={branchFilter}
                onChange={(e) => setBranchFilter(e.target.value)}
              >
                <option value="">All Branches</option>
                {branches.map(br => (
                  <option key={br} value={br}>{br}</option>
                ))}
              </select>
            </div>
          )}
        </div>

        {/* Table */}
        <div className="card">
          <div className="card-header" style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
            <h3>
              <FileWarning size={18} style={{ marginRight: 8, verticalAlign: 'middle' }} />
              All Complaints ({pagination.total})
            </h3>
            <button 
              className="btn btn-ghost btn-sm" 
              onClick={() => fetchComplaints(pagination.page)}
              disabled={loading}
              title="Reload List"
            >
              <RefreshCw size={16} className={loading ? 'spin' : ''} />
            </button>
          </div>

          {loading ? (
            <div className="spinner-overlay">
              <div className="spinner" />
            </div>
          ) : complaints.length === 0 ? (
            <div className="empty-state">
              <FileWarning />
              <h3>No complaints found</h3>
              <p>Try adjusting your filters</p>
            </div>
          ) : (
            <div className="table-wrapper">
              <table>
                <thead>
                  <tr>
                    <th>ID</th>
                    <th>ATM ID</th>
                    <th>Type</th>
                    <th>Status</th>
                    <th>Date</th>
                    <th>Actions</th>
                  </tr>
                </thead>
                <tbody>
                  {complaints.map((c) => (
                    <tr key={c.complaint_id}>
                      <td style={{ fontFamily: 'monospace', fontSize: '0.78rem', color: 'var(--text-tertiary)' }}>
                        {c.complaint_id.slice(0, 8)}...
                      </td>
                      <td>
                        <span className="type-badge">{c.atm_id}</span>
                      </td>
                      <td>{COMPLAINT_TYPE_LABELS[c.complaint_type] || c.complaint_type}</td>
                      <td>
                        <span className={`status-badge ${c.status}`}>
                          {c.status.replace('_', ' ')}
                        </span>
                      </td>
                      <td style={{ fontSize: '0.82rem', color: 'var(--text-tertiary)' }}>
                        {formatDate(c.createdAt)}
                      </td>
                      <td>
                        <div style={{ display: 'flex', gap: 6 }}>
                          <button
                            className="btn btn-ghost btn-sm"
                            onClick={() => openDetail(c)}
                            title="View Details"
                          >
                            <Eye size={16} />
                          </button>
                          <button
                            className="btn btn-primary btn-sm"
                            onClick={() => openUpdateModal(c)}
                            title="Update Status"
                          >
                            <Send size={14} />
                            Update
                          </button>
                        </div>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          )}

          {/* Pagination */}
          {pagination.pages > 1 && (
            <div className="pagination">
              <button
                disabled={pagination.page <= 1}
                onClick={() => fetchComplaints(pagination.page - 1)}
              >
                <ChevronLeft size={16} />
              </button>
              {Array.from({ length: pagination.pages }, (_, i) => i + 1).map((p) => (
                <button
                  key={p}
                  className={pagination.page === p ? 'active' : ''}
                  onClick={() => fetchComplaints(p)}
                >
                  {p}
                </button>
              ))}
              <button
                disabled={pagination.page >= pagination.pages}
                onClick={() => fetchComplaints(pagination.page + 1)}
              >
                <ChevronRight size={16} />
              </button>
            </div>
          )}
        </div>
      </div>

      {/* Detail Modal */}
      {showDetailModal && selectedComplaint && (
        <div className="modal-overlay" onClick={() => setShowDetailModal(false)}>
          <div className="modal" onClick={(e) => e.stopPropagation()}>
            <div className="modal-header">
              <h3>Complaint Details</h3>
              <button className="modal-close" onClick={() => setShowDetailModal(false)}>
                <X />
              </button>
            </div>
            <div className="modal-body">
              <div className="detail-grid">
                <div className="detail-item">
                  <label>Complaint ID</label>
                  <p style={{ fontFamily: 'monospace', fontSize: '0.78rem' }}>{selectedComplaint.complaint_id}</p>
                </div>
                <div className="detail-item">
                  <label>ATM ID</label>
                  <p>{selectedComplaint.atm_id}</p>
                </div>
                <div className="detail-item">
                  <label>Type</label>
                  <p>{COMPLAINT_TYPE_LABELS[selectedComplaint.complaint_type] || selectedComplaint.complaint_type}</p>
                </div>
                <div className="detail-item">
                  <label>Status</label>
                  <p><span className={`status-badge ${selectedComplaint.status}`}>{selectedComplaint.status.replace('_', ' ')}</span></p>
                </div>
                <div className="detail-item">
                  <label>Reported By</label>
                  <p>{selectedComplaint.user_id}</p>
                </div>
                <div className="detail-item">
                  <label>Date</label>
                  <p>{formatDate(selectedComplaint.createdAt)}</p>
                </div>
                {selectedComplaint.description && (
                  <div className="detail-item full">
                    <label>Description</label>
                    <p>{selectedComplaint.description}</p>
                  </div>
                )}
                {selectedComplaint.remarks && (
                  <div className="detail-item full">
                    <label>Admin Remarks</label>
                    <p>{selectedComplaint.remarks}</p>
                  </div>
                )}
                {selectedComplaint.resolved_at && (
                  <div className="detail-item full">
                    <label>Resolved At</label>
                    <p>{formatDate(selectedComplaint.resolved_at)}</p>
                  </div>
                )}
              </div>
              {/* Images Section */}
              {/* Images Section */}
              <div style={{ marginTop: 24 }}>
                <label className="form-label" style={{ marginBottom: 12, display: 'flex', alignItems: 'center', gap: 6, color: 'var(--text-secondary)' }}>
                  <ImageIcon size={16} /> Visual Evidence
                </label>
                
                {((selectedComplaint.photo_urls && selectedComplaint.photo_urls.length > 0) || selectedComplaint.photo_url) ? (
                  <div className="detail-image-gallery">
                    {selectedComplaint.photo_urls && selectedComplaint.photo_urls.length > 0 ? (
                      selectedComplaint.photo_urls.map((url, idx) => (
                        <div key={idx} className="detail-image-wrapper">
                          <img
                            src={`http://localhost:5000/${url.replace(/\\/g, '/')}`}
                            alt={`Evidence ${idx + 1}`}
                            onClick={() => window.open(`http://localhost:5000/${url.replace(/\\/g, '/')}`, '_blank')}
                            onError={(e) => { e.target.src = 'https://via.placeholder.com/400x300?text=Image+Not+Found'; }}
                          />
                        </div>
                      ))
                    ) : (
                      <div className="detail-image-wrapper">
                        <img
                          src={`http://localhost:5000/${selectedComplaint.photo_url.replace(/\\/g, '/')}`}
                          alt="Evidence"
                          onClick={() => window.open(`http://localhost:5000/${selectedComplaint.photo_url.replace(/\\/g, '/')}`, '_blank')}
                          onError={(e) => { e.target.src = 'https://via.placeholder.com/400x300?text=Image+Not+Found'; }}
                        />
                      </div>
                    )}
                  </div>
                ) : (
                  <div className="no-evidence-placeholder">
                    <ImageIcon size={32} />
                    <p>No visual evidence was attached to this complaint.</p>
                  </div>
                )}
              </div>
            </div>
          </div>
        </div>
      )}

      {/* Update Status Modal */}
      {showUpdateModal && selectedComplaint && (
        <div className="modal-overlay" onClick={() => setShowUpdateModal(false)}>
          <div className="modal" onClick={(e) => e.stopPropagation()}>
            <div className="modal-header">
              <h3>Update Complaint Status</h3>
              <button className="modal-close" onClick={() => setShowUpdateModal(false)}>
                <X />
              </button>
            </div>
            <div className="modal-body">
              <p style={{ fontSize: '0.85rem', color: 'var(--text-tertiary)', marginBottom: 16 }}>
                Complaint: <span style={{ fontFamily: 'monospace' }}>{selectedComplaint.complaint_id.slice(0, 12)}...</span>
              </p>

              <div className="form-group">
                <label className="form-label">Status</label>
                <div className="form-input-wrapper">
                  <AlertTriangle />
                  <select
                    className="form-select"
                    value={updateData.status}
                    onChange={(e) => setUpdateData({ ...updateData, status: e.target.value })}
                  >
                    {STATUS_OPTIONS.map((s) => (
                      <option key={s} value={s}>{s.replace('_', ' ')}</option>
                    ))}
                  </select>
                </div>
              </div>

              <div className="form-group">
                <label className="form-label">Remarks / Notes</label>
                <textarea
                  className="form-input no-icon"
                  rows={4}
                  style={{ resize: 'vertical', padding: 14 }}
                  placeholder="Add notes about this complaint..."
                  value={updateData.remarks}
                  onChange={(e) => setUpdateData({ ...updateData, remarks: e.target.value })}
                  maxLength={1000}
                />
              </div>
            </div>
            <div className="modal-footer">
              <button className="btn btn-secondary" onClick={() => setShowUpdateModal(false)}>
                Cancel
              </button>
              <button className="btn btn-primary" onClick={handleUpdateStatus} disabled={updating}>
                {updating ? 'Updating...' : 'Update Status'}
              </button>
            </div>
          </div>
        </div>
      )}
    </>
  );
}
