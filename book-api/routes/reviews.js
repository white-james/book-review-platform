const express = require('express');
const { body, validationResult } = require('express-validator');
const auth = require('../middleware/auth');
const pool = require('../db');

const router = express.Router();

// Get all reviews for a book
router.get('/book/:bookId', async (req, res) => {
  try {
    const result = await pool.query(`
      SELECT r.*, u.username, b.title, b.author
      FROM reviews r
      JOIN users u ON r.user_id = u.id
      JOIN books b ON r.book_id = b.id
      WHERE r.book_id = $1
      ORDER BY r.created_at DESC
    `, [req.params.bookId]);
    
    res.json(result.rows);
  } catch (error) {
    console.error('Error fetching reviews:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Get all reviews by a user
router.get('/user/:userId', async (req, res) => {
  try {
    const result = await pool.query(`
      SELECT r.*, u.username, b.title, b.author
      FROM reviews r
      JOIN users u ON r.user_id = u.id
      JOIN books b ON r.book_id = b.id
      WHERE r.user_id = $1
      ORDER BY r.created_at DESC
    `, [req.params.userId]);
    
    res.json(result.rows);
  } catch (error) {
    console.error('Error fetching user reviews:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Add a new review (protected route)
router.post('/', auth, [
  body('book_id').isInt({ min: 1 }),
  body('rating').isInt({ min: 1, max: 5 }),
  body('review_text').optional().trim()
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }

    const { book_id, rating, review_text } = req.body;
    const user_id = req.user.userId;

    // Check if book exists
    const bookCheck = await pool.query('SELECT id FROM books WHERE id = $1', [book_id]);
    if (bookCheck.rows.length === 0) {
      return res.status(404).json({ error: 'Book not found' });
    }

    // Check if user already reviewed this book
    const existingReview = await pool.query(
      'SELECT id FROM reviews WHERE user_id = $1 AND book_id = $2',
      [user_id, book_id]
    );

    if (existingReview.rows.length > 0) {
      return res.status(400).json({ error: 'You have already reviewed this book' });
    }

    // Insert review
    const result = await pool.query(`
      INSERT INTO reviews (user_id, book_id, rating, review_text)
      VALUES ($1, $2, $3, $4)
      RETURNING *
    `, [user_id, book_id, rating, review_text]);

    // Get the review with user and book info
    const reviewResult = await pool.query(`
      SELECT r.*, u.username, b.title, b.author
      FROM reviews r
      JOIN users u ON r.user_id = u.id
      JOIN books b ON r.book_id = b.id
      WHERE r.id = $1
    `, [result.rows[0].id]);

    res.status(201).json(reviewResult.rows[0]);
  } catch (error) {
    console.error('Error adding review:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Update a review (protected route)
router.put('/:id', auth, [
  body('rating').optional().isInt({ min: 1, max: 5 }),
  body('review_text').optional().trim()
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }

    const reviewId = req.params.id;
    const user_id = req.user.userId;
    const { rating, review_text } = req.body;

    // Check if review exists and belongs to user
    const reviewCheck = await pool.query(
      'SELECT * FROM reviews WHERE id = $1 AND user_id = $2',
      [reviewId, user_id]
    );

    if (reviewCheck.rows.length === 0) {
      return res.status(404).json({ error: 'Review not found or unauthorized' });
    }

    // Update review
    const updateQuery = `
      UPDATE reviews 
      SET rating = COALESCE($3, rating), 
          review_text = COALESCE($4, review_text)
      WHERE id = $1 AND user_id = $2
      RETURNING *
    `;

    const result = await pool.query(updateQuery, [reviewId, user_id, rating, review_text]);

    res.json(result.rows[0]);
  } catch (error) {
    console.error('Error updating review:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Delete a review (protected route)
router.delete('/:id', auth, async (req, res) => {
  try {
    const reviewId = req.params.id;
    const user_id = req.user.userId;

    const result = await pool.query(
      'DELETE FROM reviews WHERE id = $1 AND user_id = $2 RETURNING *',
      [reviewId, user_id]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Review not found or unauthorized' });
    }

    res.json({ message: 'Review deleted successfully' });
  } catch (error) {
    console.error('Error deleting review:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

module.exports = router;