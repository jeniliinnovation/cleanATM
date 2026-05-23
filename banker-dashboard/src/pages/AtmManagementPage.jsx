import { useState, useEffect, useCallback } from 'react';
import TopHeader from '../components/TopHeader';
import { adminAPI } from '../services/api';
import { useAuth } from '../context/AuthContext';
import { useToast } from '../context/ToastContext';
import {
  MapPin,
  Plus,
  Pencil,
  Trash2,
  X,
  Search,
  Building2,
  Mail,
  MapPinned,
  ChevronLeft,
  ChevronRight,
  AlertTriangle,
  Loader2,
} from 'lucide-react';

const INITIAL_ATM_FORM = {
  atm_id: '',
  bank_name: '',
  bank_code: '',
  branch_email: '',
  address: '',
  city: '',
  state: '',
  latitude: '',
  longitude: '',
  status: 'clean',
  branch_code: '',
};

export default function AtmManagementPage() {
  const [atms, setAtms] = useState([]);
  const [loading, setLoading] = useState(true);
  const [searchQuery, setSearchQuery] = useState('');
  const [pagination, setPagination] = useState({ total: 0, page: 1, per_page: 20 });
  const [showModal, setShowModal] = useState(false);
  const [modalMode, setModalMode] = useState('add'); // 'add' | 'edit'
  const [formData, setFormData] = useState({ ...INITIAL_ATM_FORM });
  const [formErrors, setFormErrors] = useState({});
  const [saving, setSaving] = useState(false);
  const [deleteConfirm, setDeleteConfirm] = useState(null);
  const [deleting, setDeleting] = useState(false);
  const { addToast } = useToast();
  const { user } = useAuth();

  const fetchAtms = useCallback(async (page = 1) => {
    try {
      setLoading(true);
      const params = { page, per_page: 20 };
      if (searchQuery.trim()) params.bank = searchQuery.trim();
      if (user?.bank_code) params.bank_code = user.bank_code;
      const res = await adminAPI.getAtms(params);
      if (res.data.success) {
        setAtms(res.data.data.atms);
        setPagination({
          total: res.data.data.total,
          page: res.data.data.page,
          per_page: res.data.data.per_page,
        });
      }
    } catch (err) {
      addToast('Failed to load ATMs', 'error');
    } finally {
      setLoading(false);
    }
  }, [searchQuery, addToast]);

  useEffect(() => {
    const debounce = setTimeout(() => fetchAtms(1), 300);
    return () => clearTimeout(debounce);
  }, [fetchAtms]);

  const openAddModal = () => {
    setModalMode('add');
    setFormData({ 
      ...INITIAL_ATM_FORM,
      bank_code: user?.bank_code || '',
    });
    setFormErrors({});
    setShowModal(true);
  };

  const openEditModal = (atm) => {
    setModalMode('edit');
    setFormData({
      atm_id: atm.atm_id,
      bank_name: atm.bank_name,
      bank_code: atm.bank_code || '',
      branch_email: atm.branch_email,
      address: atm.address,
      city: atm.city,
      state: atm.state,
      latitude: atm.latitude || '',
      longitude: atm.longitude || '',
      status: atm.status,
      branch_code: atm.branch_code || '',
    });
    setFormErrors({});
    setShowModal(true);
  };

  const validateForm = () => {
    const errs = {};
    if (!formData.atm_id.trim()) errs.atm_id = 'ATM ID is required';
    if (!formData.bank_name.trim()) errs.bank_name = 'Bank name is required';
    if (!formData.branch_email.trim()) errs.branch_email = 'Branch email is required';
    else if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(formData.branch_email))
      errs.branch_email = 'Enter a valid email';
    if (!formData.address.trim()) errs.address = 'Address is required';
    if (!formData.city.trim()) errs.city = 'City is required';
    if (!formData.state.trim()) errs.state = 'State is required';
    if (formData.latitude && isNaN(Number(formData.latitude)))
      errs.latitude = 'Must be a valid number';
    if (formData.longitude && isNaN(Number(formData.longitude)))
      errs.longitude = 'Must be a valid number';
    setFormErrors(errs);
    return Object.keys(errs).length === 0;
  };

  // Sanitize text input
  const sanitize = (str) => str.replace(/<[^>]*>/g, '').trim();

  const handleSave = async () => {
    if (!validateForm()) return;

    const sanitizedData = {
      atm_id: sanitize(formData.atm_id),
      bank_name: sanitize(formData.bank_name),
      bank_code: sanitize(formData.bank_code) || null,
      branch_email: sanitize(formData.branch_email),
      address: sanitize(formData.address),
      city: sanitize(formData.city),
      state: sanitize(formData.state),
      latitude: formData.latitude ? parseFloat(formData.latitude) : null,
      longitude: formData.longitude ? parseFloat(formData.longitude) : null,
      status: formData.status,
      branch_code: sanitize(formData.branch_code) || null,
    };

    try {
      setSaving(true);
      if (modalMode === 'add') {
        await adminAPI.addAtm(sanitizedData);
        addToast('ATM added successfully', 'success');
      } else {
        const { atm_id, ...updatePayload } = sanitizedData;
        await adminAPI.updateAtm(formData.atm_id, updatePayload);
        addToast('ATM updated successfully', 'success');
      }
      setShowModal(false);
      fetchAtms(pagination.page);
    } catch (err) {
      addToast(err.response?.data?.message || 'Failed to save ATM', 'error');
    } finally {
      setSaving(false);
    }
  };

  const handleDelete = async (atmId) => {
    try {
      setDeleting(true);
      await adminAPI.deleteAtm(atmId);
      addToast('ATM deleted successfully', 'success');
      setDeleteConfirm(null);
      fetchAtms(pagination.page);
    } catch (err) {
      addToast(err.response?.data?.message || 'Failed to delete ATM', 'error');
    } finally {
      setDeleting(false);
    }
  };

  const totalPages = Math.ceil(pagination.total / pagination.per_page);

  return (
    <>
      <TopHeader 
        title={user?.bank_code && user.bank_code !== 'DEFAULT' ? `${user.bank_code} ATM Management` : "ATM Management"} 
        subtitle={user?.bank_code && user.bank_code !== 'DEFAULT' ? `Manage your ${user.bank_code} network locations` : "Add, edit, and manage ATM locations"} 
      />

      <div className="page-content">
        {/* Actions Bar */}
        <div className="filters-bar">
          {(!user?.bank_code || user.bank_code === 'DEFAULT') && (
            <div className="search-input-wrapper">
              <Search />
              <input
                className="search-input"
                placeholder="Search by bank name..."
                value={searchQuery}
                onChange={(e) => setSearchQuery(e.target.value)}
              />
            </div>
          )}
          <div style={{ marginLeft: 'auto' }}>
            <button className="btn btn-primary" onClick={openAddModal}>
              <Plus size={18} />
              Add New ATM
            </button>
          </div>
        </div>

        {/* ATM Table */}
        <div className="card">
          <div className="card-header">
            <h3>
              <MapPin size={18} style={{ marginRight: 8, verticalAlign: 'middle' }} />
              ATM Locations ({pagination.total})
            </h3>
          </div>

          {loading ? (
            <div className="spinner-overlay">
              <div className="spinner" />
            </div>
          ) : atms.length === 0 ? (
            <div className="empty-state">
              <MapPin />
              <h3>No ATMs found</h3>
              <p>Add a new ATM or adjust your search</p>
            </div>
          ) : (
            <div className="table-wrapper">
              <table>
                <thead>
                  <tr>
                    <th>ATM ID</th>
                    <th>Bank/Branch</th>
                    <th>Location</th>
                    <th>City</th>
                    <th>State</th>
                    <th>Status</th>
                    <th>Actions</th>
                  </tr>
                </thead>
                <tbody>
                  {atms.map((atm) => (
                    <tr key={atm.atm_id}>
                      <td>
                        <span className="type-badge">{atm.atm_id}</span>
                      </td>
                      <td>
                        <div style={{ fontWeight: 600 }}>{atm.bank_name}</div>
                        <div style={{ fontSize: '0.72rem', color: 'var(--text-muted)' }}>{atm.branch_code || 'N/A'}</div>
                      </td>
                      <td style={{ fontSize: '0.82rem', color: 'var(--text-tertiary)', maxWidth: 200, overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>
                        {atm.address}
                      </td>
                      <td>{atm.city}</td>
                      <td>{atm.state}</td>
                      <td>
                        <span className={`status-badge ${atm.status}`}>
                          {atm.status}
                        </span>
                      </td>
                      <td>
                        <div style={{ display: 'flex', gap: 6 }}>
                          <button
                            className="btn btn-ghost btn-sm"
                            onClick={() => openEditModal(atm)}
                            title="Edit ATM"
                          >
                            <Pencil size={14} />
                          </button>
                          <button
                            className="btn btn-ghost btn-sm"
                            onClick={() => setDeleteConfirm(atm.atm_id)}
                            title="Delete ATM"
                            style={{ color: 'var(--error)' }}
                          >
                            <Trash2 size={14} />
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
          {totalPages > 1 && (
            <div className="pagination">
              <button
                disabled={pagination.page <= 1}
                onClick={() => fetchAtms(pagination.page - 1)}
              >
                <ChevronLeft size={16} />
              </button>
              {Array.from({ length: totalPages }, (_, i) => i + 1).map((p) => (
                <button
                  key={p}
                  className={pagination.page === p ? 'active' : ''}
                  onClick={() => fetchAtms(p)}
                >
                  {p}
                </button>
              ))}
              <button
                disabled={pagination.page >= totalPages}
                onClick={() => fetchAtms(pagination.page + 1)}
              >
                <ChevronRight size={16} />
              </button>
            </div>
          )}
        </div>
      </div>

      {/* Add/Edit Modal */}
      {showModal && (
        <div className="modal-overlay" onClick={() => setShowModal(false)}>
          <div className="modal" style={{ maxWidth: 580 }} onClick={(e) => e.stopPropagation()}>
            <div className="modal-header">
              <h3>{modalMode === 'add' ? 'Add New ATM' : 'Edit ATM'}</h3>
              <button className="modal-close" onClick={() => setShowModal(false)}>
                <X />
              </button>
            </div>
            <div className="modal-body">
              <div className="detail-grid">
                <div className="detail-item">
                  <div className="form-group" style={{ margin: 0 }}>
                    <label className="form-label">ATM ID *</label>
                    <input
                      className="form-input no-icon"
                      placeholder="ATM-XXX-001"
                      value={formData.atm_id}
                      onChange={(e) => setFormData({ ...formData, atm_id: e.target.value })}
                      disabled={modalMode === 'edit'}
                      style={modalMode === 'edit' ? { opacity: 0.6 } : {}}
                    />
                    {formErrors.atm_id && <p className="form-error">{formErrors.atm_id}</p>}
                  </div>
                </div>
                <div className="detail-item">
                  <div className="form-group" style={{ margin: 0 }}>
                    <label className="form-label">Bank Name *</label>
                    <input
                      className="form-input no-icon"
                      placeholder="State Bank"
                      value={formData.bank_name}
                      onChange={(e) => setFormData({ ...formData, bank_name: e.target.value })}
                      disabled={user?.bank_code && user.bank_code !== 'DEFAULT'}
                      style={user?.bank_code && user.bank_code !== 'DEFAULT' ? { opacity: 0.8, cursor: 'not-allowed' } : {}}
                    />
                    {formErrors.bank_name && <p className="form-error">{formErrors.bank_name}</p>}
                  </div>
                </div>
                <div className="detail-item">
                  <div className="form-group" style={{ margin: 0 }}>
                    <label className="form-label">Bank Code</label>
                    <input
                      className="form-input no-icon"
                      placeholder="SBIN"
                      value={formData.bank_code}
                      onChange={(e) => setFormData({ ...formData, bank_code: e.target.value })}
                      maxLength={10}
                      disabled={!!user?.bank_code}
                      style={user?.bank_code ? { opacity: 0.8, cursor: 'not-allowed' } : {}}
                    />
                  </div>
                </div>
                <div className="detail-item">
                  <div className="form-group" style={{ margin: 0 }}>
                    <label className="form-label">Branch Code</label>
                    <input
                      className="form-input no-icon"
                      placeholder="BR-XXXX-01"
                      value={formData.branch_code || ''}
                      onChange={(e) => setFormData({ ...formData, branch_code: e.target.value })}
                    />
                  </div>
                </div>
                <div className="detail-item">
                  <div className="form-group" style={{ margin: 0 }}>
                    <label className="form-label">Branch Email *</label>
                    <input
                      className="form-input no-icon"
                      type="email"
                      placeholder="branch@bank.com"
                      value={formData.branch_email}
                      onChange={(e) => setFormData({ ...formData, branch_email: e.target.value })}
                    />
                    {formErrors.branch_email && <p className="form-error">{formErrors.branch_email}</p>}
                  </div>
                </div>
                <div className="detail-item full">
                  <div className="form-group" style={{ margin: 0 }}>
                    <label className="form-label">Address *</label>
                    <input
                      className="form-input no-icon"
                      placeholder="Full address..."
                      value={formData.address}
                      onChange={(e) => setFormData({ ...formData, address: e.target.value })}
                    />
                    {formErrors.address && <p className="form-error">{formErrors.address}</p>}
                  </div>
                </div>
                <div className="detail-item">
                  <div className="form-group" style={{ margin: 0 }}>
                    <label className="form-label">City *</label>
                    <input
                      className="form-input no-icon"
                      placeholder="Mumbai"
                      value={formData.city}
                      onChange={(e) => setFormData({ ...formData, city: e.target.value })}
                    />
                    {formErrors.city && <p className="form-error">{formErrors.city}</p>}
                  </div>
                </div>
                <div className="detail-item">
                  <div className="form-group" style={{ margin: 0 }}>
                    <label className="form-label">State *</label>
                    <input
                      className="form-input no-icon"
                      placeholder="Maharashtra"
                      value={formData.state}
                      onChange={(e) => setFormData({ ...formData, state: e.target.value })}
                    />
                    {formErrors.state && <p className="form-error">{formErrors.state}</p>}
                  </div>
                </div>
                <div className="detail-item">
                  <div className="form-group" style={{ margin: 0 }}>
                    <label className="form-label">Latitude</label>
                    <input
                      className="form-input no-icon"
                      placeholder="18.9438"
                      value={formData.latitude}
                      onChange={(e) => setFormData({ ...formData, latitude: e.target.value })}
                    />
                    {formErrors.latitude && <p className="form-error">{formErrors.latitude}</p>}
                  </div>
                </div>
                <div className="detail-item">
                  <div className="form-group" style={{ margin: 0 }}>
                    <label className="form-label">Longitude</label>
                    <input
                      className="form-input no-icon"
                      placeholder="72.8236"
                      value={formData.longitude}
                      onChange={(e) => setFormData({ ...formData, longitude: e.target.value })}
                    />
                    {formErrors.longitude && <p className="form-error">{formErrors.longitude}</p>}
                  </div>
                </div>
                <div className="detail-item">
                  <div className="form-group" style={{ margin: 0 }}>
                    <label className="form-label">Status</label>
                    <select
                      className="form-input no-icon"
                      value={formData.status}
                      onChange={(e) => setFormData({ ...formData, status: e.target.value })}
                      style={{ cursor: 'pointer' }}
                    >
                      <option value="clean">Clean</option>
                      <option value="dirty">Dirty</option>
                      <option value="maintenance">Maintenance</option>
                    </select>
                  </div>
                </div>
              </div>
            </div>
            <div className="modal-footer">
              <button className="btn btn-secondary" onClick={() => setShowModal(false)}>
                Cancel
              </button>
              <button className="btn btn-primary" onClick={handleSave} disabled={saving}>
                {saving ? (
                  <>
                    <Loader2 size={16} style={{ animation: 'spin 0.8s linear infinite' }} />
                    Saving...
                  </>
                ) : (
                  modalMode === 'add' ? 'Add ATM' : 'Save Changes'
                )}
              </button>
            </div>
          </div>
        </div>
      )}

      {/* Delete Confirmation */}
      {deleteConfirm && (
        <div className="modal-overlay" onClick={() => setDeleteConfirm(null)}>
          <div className="modal" style={{ maxWidth: 400 }} onClick={(e) => e.stopPropagation()}>
            <div className="modal-header">
              <h3 style={{ color: 'var(--error)' }}>
                <AlertTriangle size={20} style={{ marginRight: 8, verticalAlign: 'middle' }} />
                Delete ATM
              </h3>
              <button className="modal-close" onClick={() => setDeleteConfirm(null)}>
                <X />
              </button>
            </div>
            <div className="modal-body">
              <p style={{ color: 'var(--text-secondary)' }}>
                Are you sure you want to delete ATM <strong>{deleteConfirm}</strong>?
                This action cannot be undone.
              </p>
            </div>
            <div className="modal-footer">
              <button className="btn btn-secondary" onClick={() => setDeleteConfirm(null)}>
                Cancel
              </button>
              <button
                className="btn btn-danger"
                onClick={() => handleDelete(deleteConfirm)}
                disabled={deleting}
              >
                {deleting ? 'Deleting...' : 'Delete ATM'}
              </button>
            </div>
          </div>
        </div>
      )}
    </>
  );
}
