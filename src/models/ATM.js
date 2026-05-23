const { DataTypes } = require('sequelize');
const sequelize = require('../config/db');

const ATM = sequelize.define('ATM', {
  atm_id: {
    type: DataTypes.STRING,
    primaryKey: true,
    allowNull: false
  },
  bank_name: {
    type: DataTypes.STRING,
    allowNull: false,
  },
  bank_code: {
    type: DataTypes.STRING,
    allowNull: true,
  },
  branch_code: {
    type: DataTypes.STRING,
    allowNull: true,
  },
  branch_email: {
    type: DataTypes.STRING,
    allowNull: false,
  },
  address: {
    type: DataTypes.TEXT,
    allowNull: false,
  },
  city: {
    type: DataTypes.STRING,
    allowNull: false,
  },
  state: {
    type: DataTypes.STRING,
    allowNull: false,
  },
  latitude: {
    type: DataTypes.FLOAT,
    allowNull: true,
  },
  longitude: {
    type: DataTypes.FLOAT,
    allowNull: true,
  },
  status: {
    type: DataTypes.ENUM('clean', 'dirty', 'maintenance'),
    defaultValue: 'clean'
  }
}, {
  timestamps: true,
});

module.exports = ATM;
