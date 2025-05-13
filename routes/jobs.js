const express = require('express');
const router = express.Router();

router.get('/', (req, res) => {
  res.json({ message: 'List of jobs (mock data)' });
});

module.exports = router;
