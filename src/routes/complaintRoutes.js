const express = require('express');
const router = express.Router();
const multer = require('multer');
const fs = require('fs');
const complaintController = require('../controllers/complaintController');
const { authenticate } = require('../middleware/authMiddleware');

const storage = multer.diskStorage({
  destination: function (req, file, cb) {
    const dir = 'uploads/complaints';
    if (!fs.existsSync(dir)){
        fs.mkdirSync(dir, { recursive: true });
    }
    cb(null, dir);
  },
  filename: function (req, file, cb) {
    cb(null, Date.now() + '-' + file.originalname);
  }
});
const upload = multer({ storage: storage });

router.use(authenticate);

router.post('/', upload.single('photo'), complaintController.submitComplaint);
router.get('/', complaintController.getComplaints);
router.get('/:complaint_id', complaintController.getComplaintDetails);
router.put('/:complaint_id', upload.single('photo'), complaintController.updateComplaint);
router.delete('/:complaint_id', complaintController.deleteComplaint);
router.get('/:complaint_id/photo', complaintController.getComplaintPhoto);

module.exports = router;
