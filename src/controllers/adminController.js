const jwt = require('jsonwebtoken');
const bcrypt = require('bcryptjs');
const Complaint = require('../models/Complaint');
const ATM = require('../models/ATM');
const User = require('../models/User');
const Notification = require('../models/Notification');

exports.adminLogin = async (req, res) => {
  try {
    const { email, password, bank_code } = req.body;

    // Input validation
    if (!email || !password) {
      return res.status(400).json({ success: false, message: 'Email and password are required' });
    }

    // Find admin user in database
    const adminUser = await User.findOne({ where: { email: email.toLowerCase().trim(), role: 'admin' } });

    if (!adminUser) {
      // Use generic message to prevent user enumeration
      return res.status(401).json({ success: false, message: 'Invalid admin credentials' });
    }

    // Verify password with bcrypt
    const isMatch = await bcrypt.compare(password, adminUser.password);
    if (!isMatch) {
      return res.status(401).json({ success: false, message: 'Invalid admin credentials' });
    }

    const payload = {
      admin_id: adminUser.user_id,
      user_id: adminUser.user_id,
      bank_code: bank_code || adminUser.bank_code || 'DEFAULT',
      role: 'admin'
    };

    const token = jwt.sign(payload, process.env.JWT_SECRET, { expiresIn: '1d' });

    return res.json({
      success: true,
      token,
      data: {
        user_id: adminUser.user_id,
        name: adminUser.name,
        email: adminUser.email,
        bank_code: payload.bank_code,
      }
    });
  } catch (error) {
    console.error('Admin Login Error:', error);
    res.status(500).json({ success: false, message: 'Internal Server Error' });
  }
};

exports.getComplaints = async (req, res) => {
  try {
    const { status, atm_id, branch_code, page = 1 } = req.query;
    const limit = 10;
    const offset = (page - 1) * limit;

    const whereClause = {};
    if (status) whereClause.status = status;
    if (atm_id) whereClause.atm_id = atm_id;

    // Filter by bank_code and branch_code if provided
    const atmWhere = {};
    if (req.user.bank_code && req.user.bank_code !== 'DEFAULT') {
      atmWhere.bank_code = req.user.bank_code;
    }
    if (branch_code) {
      atmWhere.branch_code = branch_code;
    }

    const { count, rows } = await Complaint.findAndCountAll({
      where: whereClause,
      include: [{
        model: ATM,
        where: atmWhere,
        required: true
      }],
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
      where: { complaint_id: req.params.complaint_id },
      include: [{
        model: ATM,
        required: true
      }]
    });
    
    if (!complaint) return res.status(404).json({ success: false, message: 'Complaint not found' });
    
    // Authorization Check
    if (req.user.bank_code && req.user.bank_code !== 'DEFAULT') {
      if (complaint.ATM.bank_code !== req.user.bank_code) {
        return res.status(403).json({ success: false, message: 'Access denied: This complaint belongs to another bank.' });
      }
    }
    
    res.json({ success: true, data: complaint });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

exports.updateComplaintStatus = async (req, res) => {
  try {
    const { status, remarks, resolved_at } = req.body;
    const complaint = await Complaint.findOne({
      where: { complaint_id: req.params.complaint_id },
      include: [ATM]
    });
    
    if (!complaint) return res.status(404).json({ success: false, message: 'Complaint not found' });

    // Authorization Check
    if (req.user.bank_code && req.user.bank_code !== 'DEFAULT') {
      if (complaint.ATM.bank_code !== req.user.bank_code) {
        return res.status(403).json({ success: false, message: 'Access denied: You can only update complaints for your bank.' });
      }
    }

    complaint.status = status;
    if (remarks) complaint.remarks = remarks;
    if (resolved_at) complaint.resolved_at = resolved_at;

    await complaint.save();

    // Notify the user who reported this
    try {
      await Notification.create({
        user_id: complaint.user_id,
        message: `Your complaint for ATM ${complaint.atm_id} has been updated to: ${status}`,
        type: 'status_update',
        is_read: false
      });
    } catch (notifyErr) {
      console.error('Failed to notify user:', notifyErr);
    }
    
    res.json({ success: true, message: 'Complaint status updated', data: complaint });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

exports.getStats = async (req, res) => {
  try {
    const { branch_code } = req.query;
    const bankCode = req.user.bank_code;
    const atmWhere = {};

    if (bankCode && bankCode !== 'DEFAULT') {
      atmWhere.bank_code = bankCode;
    }
    if (branch_code) {
      atmWhere.branch_code = branch_code;
    }

    const include = [{
      model: ATM,
      where: atmWhere,
      required: true
    }];

    const total = await Complaint.count({ include });
    const resolved = await Complaint.count({ where: { status: 'resolved' }, include });
    const pending = await Complaint.count({ where: { status: 'pending' }, include });
    const in_progress = await Complaint.count({ where: { status: 'in_progress' }, include });
    
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
    const data = { ...req.body };
    
    // Enforcement for bank managers
    if (req.user.bank_code && req.user.bank_code !== 'DEFAULT') {
      data.bank_code = req.user.bank_code;
    }

    const atm = await ATM.create(data);
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

    // Authorization Check
    if (req.user.bank_code && req.user.bank_code !== 'DEFAULT') {
      if (atm.bank_code !== req.user.bank_code) {
        return res.status(403).json({ success: false, message: 'Access denied: You can only update ATMs for your bank.' });
      }
    }

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

    // Authorization Check
    if (req.user.bank_code && req.user.bank_code !== 'DEFAULT') {
      if (atm.bank_code !== req.user.bank_code) {
        return res.status(403).json({ success: false, message: 'Access denied: You can only delete ATMs for your bank.' });
      }
    }

    await atm.destroy();
    res.json({ success: true, message: 'ATM deleted successfully' });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};
