const nodemailer = require('nodemailer');
require('dotenv').config();

const transporter = nodemailer.createTransport({
  host: process.env.SMTP_HOST,
  port: process.env.SMTP_PORT,
  secure: process.env.SMTP_SECURE === 'true',
  auth: {
    user: process.env.SMTP_USER,
    pass: process.env.SMTP_PASS
  }
});

exports.sendComplaintEmail = async (bankEmail, complaintDetails) => {
  try {
    const mailOptions = {
      from: `"ATM CleanGuard" <${process.env.SMTP_USER}>`,
      to: bankEmail,
      subject: `New ATM Complaint: ${complaintDetails.complaint_id} — ${complaintDetails.atm_id}`,
      html: `
        <h3>New ATM Complaint Received</h3>
        <ul>
          <li><b>Complaint ID:</b> ${complaintDetails.complaint_id}</li>
          <li><b>ATM ID:</b> ${complaintDetails.atm_id}</li>
          <li><b>User ID:</b> ${complaintDetails.user_id}</li>
          <li><b>Complaint Type:</b> ${complaintDetails.complaint_type}</li>
          <li><b>Details:</b> ${complaintDetails.description}</li>
        </ul>
        <p>Please log in to the admin portal to view the photo and take action.</p>
      `
    };

    const info = await transporter.sendMail(mailOptions);
    console.log('Message sent: %s', info.messageId);
    return true;
  } catch (error) {
    console.error('Error sending email:', error);
    return false;
  }
};
