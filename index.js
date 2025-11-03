
const express = require('express');
const path = require('path');

const app = express();

// Serve static files from 'public' folder
app.use(express.static(path.join(__dirname, 'public')));

// Route for home page
app.get('/', (req, res) => {
  res.sendFile(path.join(__dirname, 'views', 'index.html'));
});

const PORT = 8090;
app.listen(PORT, () => {
  console.log(`Server running on http://localhost:${PORT}`);
});

