const sequelize = require('./src/config/db');
const Complaint = require('./src/models/Complaint');
require('./src/models/associations');

async function check() {
  try {
    const stats = await Complaint.findAll({
        attributes: [
            [sequelize.fn('COUNT', sequelize.col('status')), 'count'],
            'status'
        ],
        group: ['status']
    });
    console.log('--- Database Stats ---');
    stats.forEach(s => {
      console.log(`${s.status}: ${s.get('count')}`);
    });
    process.exit(0);
  } catch (err) {
    console.error(err);
    process.exit(1);
  }
}

check();
