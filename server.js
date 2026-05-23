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
require('./src/models/associations');

const app = express();

const swaggerUi = require('swagger-ui-express');
const YAML = require('yamljs');
const swaggerDocument = YAML.load('./swagger.yaml');

// Middleware
app.use(cors()); // CORS should be first
app.use(helmet({
  crossOriginResourcePolicy: { policy: "cross-origin" },
  contentSecurityPolicy: false, // Disable CSP for local development
}));
app.use('/api-docs', swaggerUi.serve, swaggerUi.setup(swaggerDocument));
app.use((req, res, next) => {
  res.header('Access-Control-Allow-Origin', '*');
  res.header('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE, OPTIONS');
  res.header('Access-Control-Allow-Headers', 'Origin, X-Requested-With, Content-Type, Accept, Authorization');
  next();
});
app.use(express.json());
app.use(express.urlencoded({ extended: true }));
app.use(morgan('dev'));

const path = require('path');

// Routes
app.use('/v1/auth', authRoutes);
app.use('/v1/user', userRoutes);
app.use('/v1/atms', atmRoutes);
app.use('/v1/complaints', complaintRoutes);
app.use('/v1/admin', adminRoutes);
app.use('/v1/notifications', notificationRoutes);

// Static files (uploads and built frontend)
app.use('/uploads', cors(), express.static(path.join(__dirname, 'uploads'), {
  setHeaders: (res, path, stat) => {
    res.set('Access-Control-Allow-Origin', '*');
    res.set('Cross-Origin-Resource-Policy', 'cross-origin');
  }
}));
app.use(express.static(path.join(__dirname, 'frontend/build/web')));

// SPA Fallback: Serve index.html for any unknown routes (to allow Flutter routing)
app.get(/.*/, (req, res) => {
  // If it's an API route that wasn't matched, it will still go here, but API routes are prefixed with /v1/
  // and they are matched above. If they weren't matched, they are basically invalid API calls or SPA routes.
  if (req.path.startsWith('/v1/')) {
    return res.status(404).json({ success: false, message: 'API endpoint not found' });
  }
  res.sendFile(path.join(__dirname, 'frontend/build/web/index.html'));
});

// Error handling middleware
app.use((err, req, res, next) => {
  console.error(err.stack);
  res.status(500).json({ success: false, message: 'Internal Server Error' });
});

const PORT = process.env.PORT || 5000;

const startServer = async () => {
  try {
    await sequelize.authenticate();
    await sequelize.sync({ alter: true });
    console.log('✅ Database connected successfully');

    app.listen(PORT, () => {
      console.log(`🚀 Server is running on port ${PORT}`);
      console.log(`📡 Swagger Docs are available at http://localhost:${PORT}/api-docs`);
    });
  } catch (err) {
    console.error('❌ Unable to start server:', err);
    process.exit(1);
  }
};

if (require.main === module) {
  startServer();
}

module.exports = app;
