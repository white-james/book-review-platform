// Database connection module
require('dotenv').config();
const { Pool } = require('pg');

// Database connection with retry logic
const pool = new Pool({
  user: process.env.DB_USER || 'postgres',
  host: process.env.DB_HOST || 'localhost',
  database: process.env.DB_NAME || 'bookreviews',
  password: process.env.DB_PASSWORD || 'password',
  port: process.env.DB_PORT || 5432,
  // Add connection retry settings
  connectionTimeoutMillis: 10000,
  idleTimeoutMillis: 30000,
});

// Test database connection with retry
const maxRetries = 10;
const retryDelay = 3000; // 3 seconds

async function connectWithRetry(attempt = 1) {
  try {
    const client = await pool.connect();
    console.log('Database connection established');
    client.release();
  } catch (err) {
    console.error(`Database connection attempt ${attempt}/${maxRetries} failed:`, err.message);
    
    if (attempt < maxRetries) {
      console.log(`Retrying in ${retryDelay/1000} seconds...`);
      setTimeout(() => connectWithRetry(attempt + 1), retryDelay);
    } else {
      console.error('Max connection retries reached. Database may be unavailable.');
    }
  }
}

// Start connection attempts
connectWithRetry();

module.exports = pool;