//server.js file is the entry point of the application. It connects to MongoDB, enables CORS, and starts the server.

const express = require('express');
const mongoose = require('mongoose');
const cors = require('cors');
const todoRoutes = require('./src/routes/todoRoutes');

const app = express();
const PORT = process.env.PORT || 3000;

// MongoDB connection URL
const dbPassword = 'PassworD%40123';
const dbURL = `mongodb+srv://gobmj:${dbPassword}@cluster0.c948p.mongodb.net/?retryWrites=true&w=majority&appName=Cluster0`;

// Connect to MongoDB
mongoose.connect(dbURL, { useNewUrlParser: true, useUnifiedTopology: true })
  .then(() => console.log('MongoDB connected successfully'))
  .catch(err => console.error('MongoDB connection error:', err));

// Middleware
app.use(cors()); // ✅ Enable CORS before routes
app.use(express.json()); // ✅ JSON parser

// Routes
app.use('/api/todos', todoRoutes);

// Start the server
app.listen(PORT, () => console.log(`Server running on http://localhost:${PORT}`));
