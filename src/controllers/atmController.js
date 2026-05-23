const ATM = require('../models/ATM');
const Complaint = require('../models/Complaint');
const { Op } = require('sequelize');

exports.listAtms = async (req, res) => {
  try {
    const { city, bank, page = 1, per_page = 20 } = req.query;
    const limit = parseInt(per_page);
    const offset = (parseInt(page) - 1) * limit;

    const whereClause = {};
    if (city) whereClause.city = { [Op.like]: `%${city}%` };
    if (bank) whereClause.bank_name = { [Op.like]: `%${bank}%` };

    // Filter by bank_code for bank managers
    if (req.user && req.user.bank_code && req.user.bank_code !== 'DEFAULT') {
      whereClause.bank_code = req.user.bank_code;
    }

    const { count, rows } = await ATM.findAndCountAll({
      where: whereClause,
      limit,
      offset,
    });

    res.json({
      success: true,
      data: {
        atms: rows,
        total: count,
        page: parseInt(page),
        per_page: limit
      }
    });
  } catch (error) {
    console.error(error);
    res.status(500).json({ success: false, message: 'Internal Server Error' });
  }
};

exports.getAtmDetails = async (req, res) => {
  try {
    const atm = await ATM.findByPk(req.params.atm_id);
    if (!atm) {
      return res.status(404).json({ success: false, message: 'ATM not found' });
    }
    res.json({ success: true, data: atm });
  } catch (error) {
    console.error(error);
    res.status(500).json({ success: false, message: 'Internal Server Error' });
  }
};

exports.searchNearbyAtms = async (req, res) => {
  try {
    const { latitude, longitude, radius_km = 5 } = req.query;
    if (!latitude || !longitude) {
      return res.status(400).json({ success: false, message: 'Latitude and longitude are required' });
    }

    // Since we are using basic MySQL without spatial extensions enabled by default everywhere,
    // we use a simple Haversine formula approximation in JS or raw query.
    // For simplicity, we just fetch all and filter in JS if the count isn't massive.
    // A production system would use ST_Distance_Sphere.
    const atms = await ATM.findAll();
    
    const lat = parseFloat(latitude);
    const lon = parseFloat(longitude);
    const radius = parseFloat(radius_km);

    const nearbyAtms = atms.filter(atm => {
      if (!atm.latitude || !atm.longitude) return false;
      const dLat = (atm.latitude - lat) * Math.PI / 180;
      const dLon = (atm.longitude - lon) * Math.PI / 180;
      const a = 
        Math.sin(dLat/2) * Math.sin(dLat/2) +
        Math.cos(lat * Math.PI / 180) * Math.cos(atm.latitude * Math.PI / 180) * 
        Math.sin(dLon/2) * Math.sin(dLon/2);
      const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1-a));
      const distance = 6371 * c; // Radius of earth in km
      return distance <= radius;
    });

    res.json({
      success: true,
      data: {
        atms: nearbyAtms,
        total: nearbyAtms.length
      }
    });

  } catch (error) {
    console.error(error);
    res.status(500).json({ success: false, message: 'Internal Server Error' });
  }
};

exports.getAtmComplaints = async (req, res) => {
  try {
    const atm = await ATM.findByPk(req.params.atm_id);
    if (!atm) {
      return res.status(404).json({ success: false, message: 'ATM not found' });
    }

    const complaints = await Complaint.findAll({
      where: { atm_id: req.params.atm_id },
      attributes: ['complaint_id', 'user_id', 'complaint_type', 'status', 'createdAt'] // Anonymized fields
    });

    res.json({ success: true, data: complaints });
  } catch (error) {
    console.error(error);
    res.status(500).json({ success: false, message: 'Internal Server Error' });
  }
};
