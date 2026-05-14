# ATM CleanGuard

**ATM CleanGuard** is a robust digital complaint management system that allows users to easily report ATM cleanliness and maintenance issues. The system provides a seamless experience for end-users to register concerns while enabling bank authorities to track and resolve these operational issues transparently.

## 🚀 Key Features

* **Digital Ticketing System**: End-users can upload photos and report issues (dirty, AC malfunction, no power, etc.) instantly via the API.
* **Role-Based Access**: Specialized administrative dashboards tailored for bank staff.
* **Dynamic Notifications**: Fully integrated Firebase Cloud Messaging system providing realtime notifications for status updates.
* **High Security Framework**: Protected endpoints via Bearer JSON Web Tokens (JWT).
* **Robust File Handling**: Features local upload support for storing issue-related imagery seamlessly.
* **Auto-Mailing Architecture**: Fully scalable structure setup to integrate cleanly with SMTP/JavaMail triggers.

## 🛠 Technology Stack

* **Backend Environment**: Node.js, Express.js
* **Database**: MySQL managed via Sequelize ORM
* **Security & Auth**: bcryptjs, jsonwebtoken, Helmet.js
* **API Documentation**: Interactive Swagger UI mapping
* **Testing Suite**: Jest, Supertest
* **Storage**: Local Multer-managed object storage

## 🏁 Getting Started

### Prerequisites
* Node.js v16+
* MySQL Server
* Firebase application credentials

### 1. Clone & Install
```bash
git clone https://github.com/jeniliinnovation/cleanATM.git
cd cleanATM
npm install
```

### 2. Environment Configuration
Create a `.env` file at the root folder specifying:
```env
# Server
PORT=5000

# Database 
DB_NAME=clean_atm_db
DB_USER=root
DB_PASS=your_password
DB_HOST=localhost

# Security
JWT_SECRET=your_jwt_strong_secret

# Other Services
SMTP_EMAIL=your_smtp_email
SMTP_PASSWORD=your_smtp_app_password
```

### 3. Run the Server
```bash
# Start in background natively
node server.js
```

## 📖 API Documentation Walkthrough

Once running, the interactive interactive **Swagger API interface** is actively hosted natively at:
👉 `http://localhost:5000/api-docs`

It covers comprehensively all 32 APIs mapping the underlying system logic:
* The `/v1/auth/` pathways for robust user logins endpoints.
* Specialized `/v1/user/` interfaces covering profile alterations seamlessly.
* `/v1/complaints/` providing fully loaded image-supported tickets.
* Unfettered `/v1/admin/` pathways to overview and resolve ATM issues.
* Seamless `/v1/notifications/` management endpoints.

## 🧪 Testing

To fire the functional integrations endpoints checking server statuses and authorization policies:
```bash
npm install --save-dev jest supertest
npm test
```

## 🔐 Database Implementation

The API automatically syncs and configures native tables upon initial connection utilizing `sequelize.authenticate()`.

*Table Architecture:*
* `User`: Stores encrypted credentials and identity profiles natively.
* `ATM`: Physical geolocation constraints defining specific bank branch domains.
* `Complaint`: Tracks ongoing timeline statuses mapping `user_id` and `atm_id`.
* `Notification` & `DeviceToken`: Aggregates FCM data payloads securely.
