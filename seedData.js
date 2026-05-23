const sequelize = require('./src/config/db');
const User = require('./src/models/User');
const ATM = require('./src/models/ATM');
const Complaint = require('./src/models/Complaint');
const Notification = require('./src/models/Notification');
const bcrypt = require('bcryptjs');

async function seed() {
  try {
    await sequelize.authenticate();
    console.log('Connected to database.');

    // Disable FK checks and sync schema
    await sequelize.query('SET FOREIGN_KEY_CHECKS = 0');
    await sequelize.sync({ force: true });
    await sequelize.query('SET FOREIGN_KEY_CHECKS = 1');
    console.log('Database wiped and recreated.');

    const password = await bcrypt.hash('password123', 10);

    // 1. Create Users
    const users = [
      { user_id: 'USR-001', name: 'Global Admin', email: 'admin@cleanguard.com', mobile: '9988776655', password, role: 'admin' },
      { user_id: 'USR-002', name: 'SBI Manager', email: 'sbi@cleanguard.com', mobile: '9988776654', password, role: 'admin', bank_code: 'SBIN' },
      { user_id: 'USR-003', name: 'HDFC Manager', email: 'hdfc@cleanguard.com', mobile: '9988776653', password, role: 'admin', bank_code: 'HDFB' },
      { user_id: 'USR-004', name: 'Rahul Sharma', email: 'rahul@example.com', mobile: '9123456789', password, role: 'user' },
      { user_id: 'USR-005', name: 'Demo User', email: 'test@example.com', mobile: '1234567890', password, role: 'user' },
    ];

    for (const u of users) {
      await User.create(u);
    }
    console.log(`✔ ${users.length} Users created.`);

    // 2. Create ATMs
    const atms = [
      { atm_id: 'ATM-SBI-001', bank_name: 'State Bank', bank_code: 'SBIN', branch_code: 'BR-SBI-01', branch_email: 'b1@sbi.com', address: 'Plot 4, Marine Drive', city: 'Mumbai', state: 'Maharashtra', latitude: 18.9438, longitude: 72.8236, status: 'clean' },
      { atm_id: 'ATM-HDF-001', bank_name: 'HDFC Bank', bank_code: 'HDFB', branch_code: 'BR-HDF-22', branch_email: 'b2@hdfc.com', address: 'Gateway of India Road', city: 'Mumbai', state: 'Maharashtra', latitude: 18.9220, longitude: 72.8347, status: 'dirty' },
      { atm_id: 'ATM-ICI-001', bank_name: 'ICICI Bank', bank_code: 'ICIC', branch_code: 'BR-ICI-05', branch_email: 'b3@icici.com', address: 'Juhu Tara Road', city: 'Mumbai', state: 'Maharashtra', latitude: 19.1030, longitude: 72.8270, status: 'maintenance' },
      { atm_id: 'ATM-AXI-001', bank_name: 'Axis Bank', bank_code: 'UTIB', branch_code: 'BR-AXI-92', branch_email: 'b4@axis.com', address: 'Connaught Place', city: 'Delhi', state: 'Delhi', latitude: 28.6315, longitude: 77.2167, status: 'clean' },
      { atm_id: 'ATM-AXI-002', bank_name: 'Axis Bank', bank_code: 'UTIB', branch_code: 'BR-AXI-98', branch_email: 'b4_2@axis.com', address: 'Nariman Point, Marine Drive', city: 'Mumbai', state: 'Maharashtra', latitude: 18.9256, longitude: 72.8242, status: 'clean' },
      { atm_id: 'ATM-AXI-003', bank_name: 'Axis Bank', bank_code: 'UTIB', branch_code: 'BR-AXI-11', branch_email: 'b4_3@axis.com', address: 'Indiranagar 100 Feet Rd', city: 'Bangalore', state: 'Karnataka', latitude: 12.9718, longitude: 77.6411, status: 'dirty' },
      { atm_id: 'ATM-AXI-004', bank_name: 'Axis Bank', bank_code: 'UTIB', branch_code: 'BR-AXI-04', branch_email: 'b4_4@axis.com', address: 'Nungambakkam High Road', city: 'Chennai', state: 'Tamil Nadu', latitude: 13.0620, longitude: 80.2422, status: 'maintenance' },
      { atm_id: 'ATM-PNB-001', bank_name: 'PNB', bank_code: 'PUNB', branch_code: 'BR-PNB-61', branch_email: 'b5@pnb.com', address: 'Chandni Chowk', city: 'Delhi', state: 'Delhi', latitude: 28.6505, longitude: 77.2309, status: 'clean' },
      { atm_id: 'ATM-SBI-002', bank_name: 'State Bank', bank_code: 'SBIN', branch_code: 'BR-SBI-09', branch_email: 'b6@sbi.com', address: 'Park Street', city: 'Kolkata', state: 'West Bengal', latitude: 22.5539, longitude: 88.3512, status: 'dirty' },
      { atm_id: 'ATM-BOB-001', bank_name: 'Bank of Baroda', bank_code: 'BARB', branch_code: 'BR-BOB-33', branch_email: 'b7@bob.com', address: 'MG Road', city: 'Bangalore', state: 'Karnataka', latitude: 12.9733, longitude: 77.6117, status: 'clean' },
      { atm_id: 'ATM-CAN-001', bank_name: 'Canara Bank', bank_code: 'CNRB', branch_code: 'BR-CAN-77', branch_email: 'b8@canara.com', address: 'Brigade Road', city: 'Bangalore', state: 'Karnataka', latitude: 12.9700, longitude: 77.6067, status: 'maintenance' },
      { atm_id: 'ATM-SBI-003', bank_name: 'State Bank', bank_code: 'SBIN', branch_code: 'BR-SBI-14', branch_email: 'b9@sbi.com', address: 'Anna Salai', city: 'Chennai', state: 'Tamil Nadu', latitude: 13.0604, longitude: 80.2496, status: 'clean' },
      { atm_id: 'ATM-YES-001', bank_name: 'Yes Bank', bank_code: 'YESB', branch_code: 'BR-YES-88', branch_email: 'b10@yes.com', address: 'Banjara Hills', city: 'Hyderabad', state: 'Telangana', latitude: 17.4158, longitude: 78.4350, status: 'dirty' },
    ];

    for (const a of atms) {
      await ATM.create(a);
    }
    console.log(`✔ ${atms.length} ATMs created.`);

    // 3. Create Complaints
    const complaints = [
      { complaint_id: require('crypto').randomUUID(), user_id: 'USR-002', atm_id: 'ATM-BOB-001', description: 'Floor is very sticky and smells like spills.', complaint_type: 'dirty', status: 'pending' },
      { complaint_id: require('crypto').randomUUID(), user_id: 'USR-002', atm_id: 'ATM-AXI-003', description: 'The atm was very dirty for know. Dust everywhere.', complaint_type: 'dirty', status: 'pending' },
      { complaint_id: require('crypto').randomUUID(), user_id: 'USR-003', atm_id: 'ATM-SBI-002', description: 'Garbage found inside the ATM cabin near the trash bin.', complaint_type: 'garbage', status: 'in_progress' },
      { complaint_id: require('crypto').randomUUID(), user_id: 'USR-004', atm_id: 'ATM-YES-001', description: 'Walls have stains and room smells bad. Needs cleaning.', complaint_type: 'dirty', status: 'resolved' },
      { complaint_id: require('crypto').randomUUID(), user_id: 'USR-005', atm_id: 'ATM-HDF-001', description: 'Screen is cracked and area is unhygienic.', complaint_type: 'damage', status: 'pending' },
      { complaint_id: require('crypto').randomUUID(), user_id: 'USR-002', atm_id: 'ATM-SBI-001', description: 'AC is not working and it feels very stuffy.', complaint_type: 'ac_issue', status: 'pending' },
      { complaint_id: require('crypto').randomUUID(), user_id: 'USR-003', atm_id: 'ATM-AXI-004', description: 'Maintenance required: Keypad buttons are stuck.', complaint_type: 'other', status: 'pending' },
      { complaint_id: require('crypto').randomUUID(), user_id: 'USR-005', atm_id: 'ATM-ICI-001', description: 'Old receipts are scattered all over the floor.', complaint_type: 'garbage', status: 'resolved' },
      { complaint_id: require('crypto').randomUUID(), user_id: 'USR-004', atm_id: 'ATM-PNB-001', description: 'Door handle is broken and hard to open.', complaint_type: 'damage', status: 'in_progress' },
      { complaint_id: require('crypto').randomUUID(), user_id: 'USR-002', atm_id: 'ATM-YES-001', description: 'Spider webs in the corners. Very neglected.', complaint_type: 'dirty', status: 'pending' },
      { complaint_id: require('crypto').randomUUID(), user_id: 'USR-003', atm_id: 'ATM-SBI-002', description: 'Overflowing dustbin inside the cabin.', complaint_type: 'garbage', status: 'pending' },
      { complaint_id: require('crypto').randomUUID(), user_id: 'USR-005', atm_id: 'ATM-AXI-003', description: 'Card reader slot is jammed.', complaint_type: 'damage', status: 'resolved' },
      { complaint_id: require('crypto').randomUUID(), user_id: 'USR-004', atm_id: 'ATM-BOB-001', description: 'Smells of smoke inside the ATM room.', complaint_type: 'dirty', status: 'pending' },
      { complaint_id: require('crypto').randomUUID(), user_id: 'USR-002', atm_id: 'ATM-SBI-001', description: 'Light is flickering, making it scary at night.', complaint_type: 'no_power', status: 'in_progress' },
      { complaint_id: require('crypto').randomUUID(), user_id: 'USR-003', atm_id: 'ATM-ICI-001', description: 'Vandalism on the walls (graffiti).', complaint_type: 'damage', status: 'pending' },
    ];

    for (const c of complaints) {
      await Complaint.create(c);
    }
    console.log(`✔ ${complaints.length} Complaints created.`);

    // 4. Create Dummy Notifications
    const notifications = [
      { user_id: 'USR-002', message: 'Your report for Axis Bank ATM (ATM-AXI-003) is now being reviewed.', type: 'status_update' },
      { user_id: 'USR-002', message: 'Thank you for reporting! Your contribution helps keep ATMs clean.', type: 'system' },
      { user_id: 'USR-002', message: 'New security alert: Always check for skimmers before using an ATM.', type: 'security' },
      { user_id: 'USR-005', message: 'Welcome to CleanGuard! Start reporting nearby issues to earn rewards.', type: 'system' },
      { user_id: 'USR-005', message: 'Your latest report for HDFC Bank has been resolved.', type: 'status_update' },
      { user_id: 'USR-002', message: 'Weekly Summary: You helped report 3 issues this week! Good job.', type: 'stats' },
      { user_id: 'USR-003', message: 'New message from the cleaning crew regarding your report.', type: 'message' },
    ];

    for (const n of notifications) {
      await Notification.create(n);
    }
    console.log(`✔ ${notifications.length} Notifications created.`);

    console.log('✅ Production Seeding complete!');
    process.exit(0);
  } catch (error) {
    console.error('❌ Seeding failed:', error);
    process.exit(1);
  }
}

seed();

