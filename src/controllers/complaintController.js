const Complaint = require('../models/Complaint');
const path = require('path');
const fs = require('fs');

exports.submitComplaint = async (req, res) => {
  try {
    const { atm_id, description, complaint_type } = req.body;
    let photo_url = null;
    
    if (req.file) {
      photo_url = req.file.path.replace(/\\/g, '/');
    }

    const complaint = await Complaint.create({
      user_id: req.user.user_id,
      atm_id,
      description,
      complaint_type,
      photo_url
    });

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

    if (description) complaint.description = description;

    if (req.file) {
      if (complaint.photo_url && fs.existsSync(complaint.photo_url)) {
        fs.unlinkSync(complaint.photo_url);
      }
      complaint.photo_url = req.file.path.replace(/\\/g, '/');
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
