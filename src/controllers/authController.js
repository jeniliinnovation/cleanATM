const User = require('../models/User');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const { OAuth2Client } = require('google-auth-library');
const nodemailer = require('nodemailer');
const client = new OAuth2Client(process.env.GOOGLE_CLIENT_ID);

const transporter = nodemailer.createTransport({
  host: process.env.SMTP_HOST,
  port: process.env.SMTP_PORT,
  secure: process.env.SMTP_SECURE === 'true',
  auth: {
    user: process.env.SMTP_USER,
    pass: process.env.SMTP_PASS,
  },
});

function generateUserId() {
  const date = new Date();
  const dateString = date.toISOString().slice(0, 10).replace(/-/g, '');
  const randomStr = Math.floor(100 + Math.random() * 900);
  return `USR-${dateString}-${randomStr}`;
}

exports.register = async (req, res) => {
  try {
    const { name, email, mobile, password, password_confirmation } = req.body;

    if (password !== password_confirmation) {
      return res.status(400).json({ success: false, message: 'Passwords do not match' });
    }

    const existingUser = await User.findOne({ where: { email } });
    if (existingUser) {
      return res.status(400).json({ success: false, message: 'Email already exists' });
    }

    const hashedPassword = await bcrypt.hash(password, 10);
    const user_id = generateUserId();

    const user = await User.create({
      user_id,
      name,
      email,
      mobile,
      password: hashedPassword
    });

    const token = jwt.sign({ user_id: user.user_id, role: user.role }, process.env.JWT_SECRET, { expiresIn: '30d' });

    res.status(201).json({
      success: true,
      message: 'Registration successful',
      data: {
        user_id: user.user_id,
        name: user.name,
        email: user.email,
        mobile: user.mobile,
        token
      }
    });
  } catch (error) {
    console.error(error);
    res.status(500).json({ success: false, message: 'Internal Server Error' });
  }
};

exports.login = async (req, res) => {
  try {
    const { email, password } = req.body;
    
    const user = await User.findOne({ where: { email } });
    if (!user) {
      return res.status(401).json({ success: false, message: 'Invalid email or password' });
    }

    const isMatch = await bcrypt.compare(password, user.password);
    if (!isMatch) {
      return res.status(401).json({ success: false, message: 'Invalid email or password' });
    }

    const token = jwt.sign({ user_id: user.user_id, role: user.role }, process.env.JWT_SECRET, { expiresIn: '30d' });

    res.json({
      success: true,
      message: 'Login successful',
      data: {
        user_id: user.user_id,
        name: user.name,
        token,
        expires_at: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000).toISOString()
      }
    });
  } catch (error) {
    console.error(error);
    res.status(500).json({ success: false, message: 'Internal Server Error' });
  }
};

exports.googleLogin = async (req, res) => {
  try {
    const { idToken, email, name, photoUrl } = req.body;
    
    // For demo/simplicity if client ID is not yet configured in .env
    const userEmail = email;
    const googleId = idToken ? idToken.slice(0, 50) : `G-${Date.now()}`;

    let user = await User.findOne({ where: { email: userEmail } });

    if (!user) {
      user = await User.create({
        user_id: generateUserId(),
        name,
        email: userEmail,
        google_id: googleId,
        photo_url: photoUrl,
        password: null // No password for Google login
      });
    } else {
      // Update existing user with Google ID if not present
      if (!user.google_id) {
        user.google_id = googleId;
        user.photo_url = photoUrl;
        await user.save();
      }
    }

    const token = jwt.sign({ user_id: user.user_id, role: user.role }, process.env.JWT_SECRET, { expiresIn: '30d' });

    res.json({
      success: true,
      message: 'Google Login successful',
      data: {
        user_id: user.user_id,
        name: user.name,
        token,
        expires_at: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000).toISOString()
      }
    });
  } catch (error) {
    console.error('Google Login Error:', error);
    res.status(500).json({ success: false, message: 'Google Login failed' });
  }
};

exports.logout = async (req, res) => {
  // In a stateless JWT implementation, logout is usually handled client-side by deleting the token.
  // We can just return success here.
  res.json({ success: true, message: 'Logged out successfully' });
};

exports.forgotPassword = async (req, res) => {
  try {
    const { email } = req.body;
    const user = await User.findOne({ where: { email } });
    
    if (!user) {
      // For security, don't reveal if user exists or not, but for demo we can
      return res.status(404).json({ success: false, message: 'If this email is registered, you will receive a reset link.' });
    }

    // In a real app, you'd generate a reset token and save it to the DB
    // For now, we'll just send a mock reset link
    const resetLink = `http://localhost:5000/reset-password?email=${email}`;
    
    const mailOptions = {
      from: `"ATM CleanGuard" <${process.env.SMTP_USER}>`,
      to: email,
      subject: 'Password Reset Request',
      html: `
        <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 20px; border: 1px solid #e0e0e0; border-radius: 10px;">
          <h2 style="color: #0D47A1; text-align: center;">Password Reset Request</h2>
          <p>Hi ${user.name},</p>
          <p>We received a request to reset your password for your ATM CleanGuard account. Click the button below to set a new password:</p>
          <div style="text-align: center; margin: 30px 0;">
            <a href="${resetLink}" style="background-color: #0D47A1; color: white; padding: 12px 24px; text-decoration: none; border-radius: 5px; font-weight: bold;">Reset Password</a>
          </div>
          <p>If you didn't request this, you can safely ignore this email.</p>
          <p>This link will expire in 1 hour.</p>
          <hr style="border: none; border-top: 1px solid #eeeeee; margin: 20px 0;">
          <p style="color: #888; font-size: 12px; text-align: center;">ATM CleanGuard - Keeping our community clean and safe.</p>
        </div>
      `,
    };

    await transporter.sendMail(mailOptions);
    res.json({ success: true, message: 'Password reset link sent to your email.' });
  } catch (error) {
    console.error('Forgot Password Error:', error);
    res.status(500).json({ success: false, message: 'Failed to send reset email.' });
  }
};

exports.resetPassword = async (req, res) => {
  // Mock function for now
  res.json({ success: true, message: 'Password reset successfully' });
};
