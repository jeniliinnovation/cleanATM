const { DataTypes } = require('sequelize');
const sequelize = require('../config/db');

const Complaint = sequelize.define('Complaint', {
  complaint_id: {
    type: DataTypes.UUID,
    defaultValue: DataTypes.UUIDV4,
    primaryKey: true,
  },
  user_id: {
    type: DataTypes.STRING,
    allowNull: false,
  },
  atm_id: {
    type: DataTypes.STRING,
    allowNull: false,
  },
  description: {
    type: DataTypes.TEXT,
  },
  complaint_type: {
    type: DataTypes.ENUM('dirty', 'ac_issue', 'garbage', 'damage', 'no_power', 'other', 'atm_dirty', 'no_cash', 'machine_error', 'vandalism'),
    allowNull: false,
  },
  photo_url: {
    type: DataTypes.STRING,
  },
  photo_urls: {
    type: DataTypes.JSON,
  },
  status: {
    type: DataTypes.ENUM('pending', 'in_progress', 'resolved', 'rejected'),
    defaultValue: 'pending',
  },
  remarks: {
    type: DataTypes.TEXT,
  },
  resolved_at: {
    type: DataTypes.DATE,
  }
}, {
  timestamps: true,
  tableName: 'complaints'
});

module.exports = Complaint;
