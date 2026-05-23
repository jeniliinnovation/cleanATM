const ATM = require('./ATM');
const Complaint = require('./Complaint');
const User = require('./User');
const Notification = require('./Notification');

// ATM <-> Complaint
ATM.hasMany(Complaint, { foreignKey: 'atm_id' });
Complaint.belongsTo(ATM, { foreignKey: 'atm_id' });

// User <-> Complaint
User.hasMany(Complaint, { foreignKey: 'user_id' });
Complaint.belongsTo(User, { foreignKey: 'user_id' });

// User <-> Notification
User.hasMany(Notification, { foreignKey: 'user_id' });
Notification.belongsTo(User, { foreignKey: 'user_id' });

module.exports = { ATM, Complaint, User, Notification };
