const jwt = require('jsonwebtoken');
const Complaint = require('../models/Complaint');
const ATM = require('../models/ATM');

exports.adminLogin = async (req, res) => {
  try {
    const { email, password, bank_code } = req.body;
    // Mocking admin authentication for simplicity
    if (email === 'admin@admin.com' && password === 'admin123') {
      const payload = {
        admin_id: '1',
        bank_code: bank_code || 'DEFAULT',
        role: 'admin'
      };
      const token = jwt.sign(payload, process.env.JWT_SECRET || 'secret', { expiresIn: '1d' });
      return res.json({ success: true, token });
    }
    return res.status(401).json({ success: false, message: 'Invalid admin credentials' });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

exports.getComplaints = async (req, res) => {
  try {
    const { status, atm_id, from_date, to_date, page = 1 } = req.query;
    const limit = 10;
    const offset = (page - 1) * limit;

    const whereClause = {};
    if (status) whereClause.status = status;
    if (atm_id) whereClause.atm_id = atm_id;
    // Further date filtering can be added here if needed

    const { count, rows } = await Complaint.findAndCountAll({
      where: whereClause,
      limit,
      offset,
      order: [['createdAt', 'DESC']]
    });

    res.json({
      success: true,
      data: rows,
      pagination: {
        total: count,
        page: parseInt(page),
        pages: Math.ceil(count / limit)
      }
    });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

exports.getComplaintDetails = async (req, res) => {
  try {
    const complaint = await Complaint.findOne({
      where: { complaint_id: req.params.complaint_id }
    });
    if (!complaint) return res.status(404).json({ success: false, message: 'Complaint not found' });
    
    res.json({ success: true, data: complaint });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

exports.updateComplaintStatus = async (req, res) => {
  try {
    const { status, remarks, resolved_at } = req.body;
    const complaint = await Complaint.findOne({
      where: { complaint_id: req.params.complaint_id }
    });
    if (!complaint) return res.status(404).json({ success: false, message: 'Complaint not found' });

    complaint.status = status;
    if (remarks) complaint.remarks = remarks;
    if (resolved_at) complaint.resolved_at = resolved_at;

    await complaint.save();
    
    res.json({ success: true, message: 'Complaint status updated', data: complaint });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

exports.getStats = async (req, res) => {
  try {
    const total = await Complaint.count();
    const resolved = await Complaint.count({ where: { status: 'resolved' } });
    const pending = await Complaint.count({ where: { status: 'pending' } });
    const in_progress = await Complaint.count({ where: { status: 'in_progress' } });
    
    res.json({
      success: true,
      data: {
        total,
        resolved,
        pending,
        in_progress
      }
    });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

exports.addAtm = async (req, res) => {
  try {
    const atm = await ATM.create(req.body);
    res.status(201).json({ success: true, message: 'ATM created successfully', data: atm });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

exports.updateAtm = async (req, res) => {
  try {
    const { atm_id } = req.params;
    const atm = await ATM.findByPk(atm_id);
    if (!atm) return res.status(404).json({ success: false, message: 'ATM not found' });

    await atm.update(req.body);
    res.json({ success: true, message: 'ATM updated successfully', data: atm });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

exports.deleteAtm = async (req, res) => {
  try {
    const { atm_id } = req.params;
    const atm = await ATM.findByPk(atm_id);
    if (!atm) return res.status(404).json({ success: false, message: 'ATM not found' });

    await atm.destroy();
    res.json({ success: true, message: 'ATM deleted successfully' });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};
