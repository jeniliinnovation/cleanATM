const Notification = require('../models/Notification');
const DeviceToken = require('../models/DeviceToken');

exports.fetchNotifications = async (req, res) => {
  try {
    const { is_read, page = 1 } = req.query;
    const limit = 10;
    const offset = (page - 1) * limit;

    const whereClause = { user_id: req.user.user_id };
    if (is_read !== undefined) {
      whereClause.is_read = is_read === 'true';
    }

    const { count, rows } = await Notification.findAndCountAll({
      where: whereClause,
      limit,
      offset,
      order: [['createdAt', 'DESC']]
    });

    res.json({
      success: true,
      data: rows,
      pagination: {
        total: count,
        page: parseInt(page),
        pages: Math.ceil(count / limit)
      }
    });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

exports.markAsRead = async (req, res) => {
  try {
    const notification = await Notification.findOne({
      where: { id: req.params.id, user_id: req.user.user_id }
    });
    if (!notification) return res.status(404).json({ success: false, message: 'Notification not found' });

    notification.is_read = true;
    await notification.save();

    res.json({ success: true, message: 'Notification marked as read' });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

exports.markAllAsRead = async (req, res) => {
  try {
    await Notification.update(
      { is_read: true },
      { where: { user_id: req.user.user_id, is_read: false } }
    );
    res.json({ success: true, message: 'All notifications marked as read' });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

exports.deleteNotification = async (req, res) => {
  try {
    const notification = await Notification.findOne({
      where: { id: req.params.id, user_id: req.user.user_id }
    });
    if (!notification) return res.status(404).json({ success: false, message: 'Notification not found' });

    await notification.destroy();
    res.json({ success: true, message: 'Notification deleted' });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

exports.registerDevice = async (req, res) => {
  try {
    const { fcm_token, device_type } = req.body;
    
    // Check if token already exists for this user
    let tokenRecord = await DeviceToken.findOne({
      where: { user_id: req.user.user_id, token: fcm_token }
    });

    if (!tokenRecord) {
      await DeviceToken.create({
        user_id: req.user.user_id,
        token: fcm_token,
        device_type
      });
    }

    res.json({ success: true, message: 'Device registered successfully' });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};
