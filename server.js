require('dotenv').config();
const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');
const sequelize = require('./src/config/db');

// Import routes (we will create these next)
const authRoutes = require('./src/routes/authRoutes');
const userRoutes = require('./src/routes/userRoutes');
const atmRoutes = require('./src/routes/atmRoutes');
const complaintRoutes = require('./src/routes/complaintRoutes');
const adminRoutes = require('./src/routes/adminRoutes');
const notificationRoutes = require('./src/routes/notificationRoutes');

const app = express();

const swaggerUi = require('swagger-ui-express');
const YAML = require('yamljs');
const swaggerDocument = YAML.load('./swagger.yaml');

// Middleware
app.use('/api-docs', swaggerUi.serve, swaggerUi.setup(swaggerDocument));
app.use(helmet());
app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));
app.use(morgan('dev'));

// Routes
app.use('/v1/auth', authRoutes);
app.use('/v1/user', userRoutes);
app.use('/v1/atms', atmRoutes);
app.use('/v1/complaints', complaintRoutes);
app.use('/v1/admin', adminRoutes);
app.use('/v1/notifications', notificationRoutes);

// Base route
app.get('/', (req, res) => {
  res.send('ATM CleanGuard API is running');
});

// Error handling middleware
app.use((err, req, res, next) => {
  console.error(err.stack);
  res.status(500).json({ success: false, message: 'Internal Server Error' });
});

const PORT = process.env.PORT || 5000;

if (require.main === module) {
  app.listen(PORT, async () => {
    console.log(`Server is running on port ${PORT}`);
    console.log(`Swagger Docs are available at http://localhost:${PORT}/api-docs`);
    try {
      await sequelize.authenticate();
      console.log('Database connected successfully');
    } catch (err) {
      console.error('Unable to connect to the database:', err);
    }
  });
}

module.exports = app;
