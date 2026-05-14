require('dotenv').config();
const mysql = require('mysql2/promise');
const sequelize = require('./src/config/db');

// Import all models to ensure they are registered with Sequelize
require('./src/models/User');
require('./src/models/ATM');
require('./src/models/Complaint');
require('./src/models/Notification');

async function createDatabaseAndSync() {
  try {
    // Connect to MySQL server without selecting a database
    const connection = await mysql.createConnection({
      host: process.env.DB_HOST,
      port: process.env.DB_PORT || 3306,
      user: process.env.DB_USER,
      password: process.env.DB_PASSWORD,
    });

    // Create database if it doesn't exist
    await connection.query(`CREATE DATABASE IF NOT EXISTS \`${process.env.DB_NAME}\`;`);
    console.log(`Database '${process.env.DB_NAME}' checked/created successfully.`);
    await connection.end();

    // Now connect to the database via Sequelize and sync models
    await sequelize.authenticate();
    console.log('Connection to the database has been established successfully.');

    // Sync all models (using default sync to prevent drop constraint errors)
    await sequelize.sync();
    console.log('All models were synchronized successfully.');

    process.exit(0);
  } catch (error) {
    console.error('Unable to connect to the database or sync models:', error);
    process.exit(1);
  }
}

createDatabaseAndSync();
