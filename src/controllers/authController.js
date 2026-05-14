const User = require('../models/User');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');

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

exports.logout = async (req, res) => {
  // In a stateless JWT implementation, logout is usually handled client-side by deleting the token.
  // We can just return success here.
  res.json({ success: true, message: 'Logged out successfully' });
};

exports.forgotPassword = async (req, res) => {
  // Mock function for now. Real implementation would send an email.
  res.json({ success: true, message: 'If the email exists, a reset link will be sent.' });
};

exports.resetPassword = async (req, res) => {
  // Mock function for now
  res.json({ success: true, message: 'Password reset successfully' });
};
