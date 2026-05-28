const sequelize = require('./src/config/db');
const Complaint = require('./src/models/Complaint');
require('./src/models/associations');

async function check() {
  try {
    const c = await Complaint.findByPk('553703b5-3741-4939-891b-c033ab7c82e6');
    if (c) {
      console.log('--- Complaint Data ---');
      console.log('ID:', c.complaint_id);
      console.log('photo_url:', c.photo_url);
      console.log('photo_urls:', c.photo_urls);
    } else {
      console.log('Complaint not found');
    }
    process.exit(0);
  } catch (err) {
    console.error(err);
    process.exit(1);
  }
}

check();
