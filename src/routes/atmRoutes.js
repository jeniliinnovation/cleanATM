const express = require('express');
const router = express.Router();
const atmController = require('../controllers/atmController');
const { authenticate } = require('../middleware/authMiddleware');

router.use(authenticate);

router.get('/', atmController.listAtms);
router.get('/nearby', atmController.searchNearbyAtms);
router.get('/:atm_id', atmController.getAtmDetails);
router.get('/:atm_id/complaints', atmController.getAtmComplaints);

module.exports = router;
