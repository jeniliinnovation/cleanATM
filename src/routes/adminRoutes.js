const express = require('express');
const router = express.Router();
const adminController = require('../controllers/adminController');
const { authenticate } = require('../middleware/authMiddleware');

// Define an admin check middleware inline
const isAdmin = (req, res, next) => {
  if (req.user && req.user.role === 'admin') {
    next();
  } else {
    return res.status(403).json({ success: false, message: 'Access denied. Admins only.' });
  }
};

router.post('/auth/login', adminController.adminLogin);

// Protect the following routes
router.use(authenticate, isAdmin);

router.get('/complaints', adminController.getComplaints);
router.get('/complaints/:complaint_id', adminController.getComplaintDetails);
router.put('/complaints/:complaint_id/status', adminController.updateComplaintStatus);

router.get('/stats', adminController.getStats);

router.post('/atms', adminController.addAtm);
router.put('/atms/:atm_id', adminController.updateAtm);
router.delete('/atms/:atm_id', adminController.deleteAtm);

module.exports = router;
