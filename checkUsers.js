const User = require('./src/models/User');
(async () => {
  try {
    const users = await User.findAll({ attributes: ['email', 'role', 'bank_code'] });
    console.log(JSON.stringify(users, null, 2));
    process.exit(0);
  } catch (err) {
    console.error(err);
    process.exit(1);
  }
})();
