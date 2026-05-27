const path = require('path');
const fs = require('fs');
const ATM = require('../models/ATM');
const User = require('../models/User');
const Notification = require('../models/Notification');
const Complaint = require('../models/Complaint');

exports.submitComplaint = async (req, res) => {
  try {
    const { atm_id, description, complaint_type } = req.body;
    let photo_url = null;
    let photo_urls = [];
    
    if (req.files && req.files.length > 0) {
      photo_urls = req.files.map(file => file.path.replace(/\\/g, '/'));
      photo_url = photo_urls[0];
    }

    const complaint = await Complaint.create({
      user_id: req.user.user_id,
      atm_id,
      description,
      complaint_type,
      photo_url,
      photo_urls
    });

    // Notify relevant Bank Managers
    try {
      const targetAtm = await ATM.findByPk(atm_id);
      if (targetAtm && targetAtm.bank_code) {
        const managers = await User.findAll({
          where: { 
            role: 'admin', 
            bank_code: targetAtm.bank_code 
          }
        });

        for (const manager of managers) {
          await Notification.create({
            user_id: manager.user_id,
            message: `New ${complaint_type.replace('_', ' ')} complaint filed for ATM: ${atm_id}`,
            type: 'new_complaint',
            is_read: false
          });
        }
      }
    } catch (notifyErr) {
      console.error('Failed to send manager notifications:', notifyErr);
    }

    res.status(201).json({ success: true, message: 'Complaint submitted successfully', data: complaint });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

exports.getComplaints = async (req, res) => {
  try {
    const { status, page = 1 } = req.query;
    const limit = 10;
    const offset = (page - 1) * limit;
    
    const whereClause = { user_id: req.user.user_id };
    if (status) {
      whereClause.status = status;
    }

    const { count, rows } = await Complaint.findAndCountAll({
      where: whereClause,
      include: [ATM],
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
      where: { complaint_id: req.params.complaint_id, user_id: req.user.user_id }
    });
    if (!complaint) return res.status(404).json({ success: false, message: 'Complaint not found' });
    
    res.json({ success: true, data: complaint });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

exports.updateComplaint = async (req, res) => {
  try {
    const { description } = req.body;
    const complaint = await Complaint.findOne({
      where: { complaint_id: req.params.complaint_id, user_id: req.user.user_id }
    });
    if (!complaint) return res.status(404).json({ success: false, message: 'Complaint not found' });

    // Enforce 2-hour edit window
    const createdAt = new Date(complaint.createdAt);
    const now = new Date();
    const hoursElapsed = (now - createdAt) / (1000 * 60 * 60);

    if (hoursElapsed > 2) {
      return res.status(403).json({ success: false, message: 'Edit window (2 hours) has expired' });
    }

    if (complaint.status !== 'pending') {
      return res.status(403).json({ success: false, message: 'Only pending complaints can be edited' });
    }

    if (description) complaint.description = description;

    if (req.files && req.files.length > 0) {
      // Clear old photos
      if (complaint.photo_urls && Array.isArray(complaint.photo_urls)) {
        complaint.photo_urls.forEach(p => {
          if (fs.existsSync(p)) fs.unlinkSync(p);
        });
      } else if (complaint.photo_url && fs.existsSync(complaint.photo_url)) {
        fs.unlinkSync(complaint.photo_url);
      }
      
      complaint.photo_urls = req.files.map(file => file.path.replace(/\\/g, '/'));
      complaint.photo_url = complaint.photo_urls[0];
    }

    await complaint.save();
    
    res.json({ success: true, message: 'Complaint updated', data: complaint });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

exports.deleteComplaint = async (req, res) => {
  try {
    const complaint = await Complaint.findOne({
      where: { complaint_id: req.params.complaint_id, user_id: req.user.user_id }
    });
    if (!complaint) return res.status(404).json({ success: false, message: 'Complaint not found' });

    if (complaint.photo_url && fs.existsSync(complaint.photo_url)) {
      fs.unlinkSync(complaint.photo_url);
    }

    await complaint.destroy();
    
    res.json({ success: true, message: 'Complaint deleted' });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

exports.getComplaintPhoto = async (req, res) => {
  try {
    const complaint = await Complaint.findOne({
      where: { complaint_id: req.params.complaint_id }
    });
    if (!complaint || !complaint.photo_url) return res.status(404).json({ success: false, message: 'Photo not found' });

    const photoPath = path.resolve(complaint.photo_url);
    if (!fs.existsSync(photoPath)) return res.status(404).json({ success: false, message: 'File not found on server' });

    res.sendFile(photoPath);
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};
