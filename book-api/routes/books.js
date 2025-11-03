const express = require('express');
const { body, validationResult } = require('express-validator');
const auth = require('../middleware/auth');
const pool = require('../db');

const router = express.Router();

// Get all books
router.get('/', async (req, res) => {
  try {
    const result = await pool.query(`
      SELECT b.*, 
             COUNT(r.id) as review_count,
             ROUND(AVG(r.rating), 1) as average_rating
      FROM books b
      LEFT JOIN reviews r ON b.id = r.book_id
      GROUP BY b.id
      ORDER BY b.created_at DESC
    `);
    
    res.json(result.rows);
  } catch (error) {
    console.error('Error fetching books:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Get single book
router.get('/:id', async (req, res) => {
  try {
    const bookId = req.params.id;
    
    const bookResult = await pool.query(`
      SELECT b.*, 
             COUNT(r.id) as review_count,
             ROUND(AVG(r.rating), 1) as average_rating
      FROM books b
      LEFT JOIN reviews r ON b.id = r.book_id
      WHERE b.id = $1
      GROUP BY b.id
    `, [bookId]);

    if (bookResult.rows.length === 0) {
      return res.status(404).json({ error: 'Book not found' });
    }

    // Get reviews for this book
    const reviewsResult = await pool.query(`
      SELECT r.*, u.username
      FROM reviews r
      JOIN users u ON r.user_id = u.id
      WHERE r.book_id = $1
      ORDER BY r.created_at DESC
    `, [bookId]);

    const book = bookResult.rows[0];
    book.reviews = reviewsResult.rows;

    res.json(book);
  } catch (error) {
    console.error('Error fetching book:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Add new book (protected route)
router.post('/', auth, [
  body('title').notEmpty().trim(),
  body('author').notEmpty().trim(),
  body('description').optional().trim(),
  body('isbn').optional().trim()
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }

    const { title, author, description, isbn } = req.body;

    const result = await pool.query(
      'INSERT INTO books (title, author, description, isbn) VALUES ($1, $2, $3, $4) RETURNING *',
      [title, author, description, isbn]
    );

    res.status(201).json(result.rows[0]);
  } catch (error) {
    console.error('Error adding book:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Search books
router.get('/search/:query', async (req, res) => {
  try {
    const searchQuery = `%${req.params.query}%`;
    
    const result = await pool.query(`
      SELECT b.*, 
             COUNT(r.id) as review_count,
             ROUND(AVG(r.rating), 1) as average_rating
      FROM books b
      LEFT JOIN reviews r ON b.id = r.book_id
      WHERE b.title ILIKE $1 OR b.author ILIKE $1
      GROUP BY b.id
      ORDER BY b.created_at DESC
    `, [searchQuery]);
    
    res.json(result.rows);
  } catch (error) {
    console.error('Error searching books:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

module.exports = router;