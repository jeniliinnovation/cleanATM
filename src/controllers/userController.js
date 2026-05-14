const bcrypt = require('bcryptjs');
const User = require('../models/User');

exports.getProfile = async (req, res) => {
  try {
    const user = await User.findByPk(req.user.user_id, {
      attributes: { exclude: ['password'] }
    });
    if (!user) return res.status(404).json({ success: false, message: 'User not found' });
    res.json({ success: true, data: user });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

exports.updateProfile = async (req, res) => {
  try {
    const { name, mobile } = req.body;
    const user = await User.findByPk(req.user.user_id);
    if (!user) return res.status(404).json({ success: false, message: 'User not found' });

    user.name = name || user.name;
    user.mobile = mobile || user.mobile;
    await user.save();

    res.json({ success: true, message: 'Profile updated successfully', data: { name: user.name, mobile: user.mobile } });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

exports.changePassword = async (req, res) => {
  try {
    const { current_password, new_password, new_password_confirmation } = req.body;
    if (new_password !== new_password_confirmation) {
      return res.status(400).json({ success: false, message: 'Passwords do not match' });
    }

    const user = await User.findByPk(req.user.user_id);
    if (!user) return res.status(404).json({ success: false, message: 'User not found' });

    const isMatch = await bcrypt.compare(current_password, user.password);
    if (!isMatch) return res.status(400).json({ success: false, message: 'Invalid current password' });

    const salt = await bcrypt.genSalt(10);
    user.password = await bcrypt.hash(new_password, salt);
    await user.save();

    res.json({ success: true, message: 'Password changed successfully' });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

exports.deleteAccount = async (req, res) => {
  try {
    const { password } = req.body;
    const user = await User.findByPk(req.user.user_id);
    if (!user) return res.status(404).json({ success: false, message: 'User not found' });

    const isMatch = await bcrypt.compare(password, user.password);
    if (!isMatch) return res.status(400).json({ success: false, message: 'Invalid password' });

    await user.destroy();
    res.json({ success: true, message: 'Account deleted successfully' });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};
