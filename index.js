const express = require('express');
const app = express();
const PORT = 3000;

app.use(express.json());

const jobRoutes = require('./routes/jobs');
app.use('/jobs', jobRoutes);

app.get('/', (req, res) => {
  res.send('Hello from Node.js backend!');
});

app.listen(PORT, () => {
  console.log(`Server running at http://localhost:${PORT}`);
});
