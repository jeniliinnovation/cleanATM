const { DataTypes } = require('sequelize');
const sequelize = require('../config/db');

const DeviceToken = sequelize.define('DeviceToken', {
  id: {
    type: DataTypes.UUID,
    defaultValue: DataTypes.UUIDV4,
    primaryKey: true,
  },
  user_id: {
    type: DataTypes.UUID,
    allowNull: false,
  },
  token: {
    type: DataTypes.STRING,
    allowNull: false,
  },
  device_type: {
    type: DataTypes.STRING,
  }
}, {
  timestamps: true,
  tableName: 'device_tokens'
});

module.exports = DeviceToken;
