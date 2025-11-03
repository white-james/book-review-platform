-- Initialize the Book Review Platform database

-- Create database (run this separately if needed)
-- CREATE DATABASE bookreviews;

-- Create users table
CREATE TABLE IF NOT EXISTS users (
    id SERIAL PRIMARY KEY,
    username VARCHAR(50) UNIQUE NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create books table
CREATE TABLE IF NOT EXISTS books (
    id SERIAL PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    author VARCHAR(255) NOT NULL,
    isbn VARCHAR(20),
    description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create reviews table
CREATE TABLE IF NOT EXISTS reviews (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
    book_id INTEGER REFERENCES books(id) ON DELETE CASCADE,
    rating INTEGER CHECK (rating >= 1 AND rating <= 5),
    review_text TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(user_id, book_id)
);

-- Insert some sample data
INSERT INTO books (title, author, description, isbn) VALUES 
('The Great Gatsby', 'F. Scott Fitzgerald', 'A classic American novel set in the Jazz Age, exploring themes of wealth, love, and the American Dream.', '9780743273565'),
('To Kill a Mockingbird', 'Harper Lee', 'A gripping tale of racial injustice and childhood innocence in the American South.', '9780446310789'),
('1984', 'George Orwell', 'A dystopian social science fiction novel about totalitarian control and surveillance.', '9780451524935'),
('Pride and Prejudice', 'Jane Austen', 'A romantic novel about manners, upbringing, morality, education, and marriage in Georgian England.', '9780141439518'),
('The Catcher in the Rye', 'J.D. Salinger', 'A controversial novel about teenage rebellion and alienation in post-war America.', '9780316769174')
ON CONFLICT DO NOTHING;

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_reviews_book_id ON reviews(book_id);
CREATE INDEX IF NOT EXISTS idx_reviews_user_id ON reviews(user_id);
CREATE INDEX IF NOT EXISTS idx_books_title ON books(title);
CREATE INDEX IF NOT EXISTS idx_books_author ON books(author);