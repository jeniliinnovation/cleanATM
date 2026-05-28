const sequelize = require('./src/config/db');
const Complaint = require('./src/models/Complaint');
require('./src/models/associations');

async function check() {
  try {
    const complaints = await Complaint.findAll({
        attributes: ['complaint_id', 'status', 'atm_id']
    });
    console.log('--- Current Complaints Status ---');
    complaints.forEach(c => {
      console.log(`ID: ${c.complaint_id} | Status: ${c.status} | ATM: ${c.atm_id}`);
    });
    process.exit(0);
  } catch (err) {
    console.error(err);
    process.exit(1);
  }
}

check();
