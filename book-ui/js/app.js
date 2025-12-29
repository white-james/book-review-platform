// Book Review Platform JavaScript

// Configuration
// Use relative URL - works in all environments (Docker, ACI, AKS with Ingress)
const API_BASE_URL = window.location.hostname === 'localhost' 
    ? 'http://localhost:3000/api' 
    : '/api';  // Relative path - ingress handles routing on port 80

let currentUser = null;

// Initialize app
document.addEventListener('DOMContentLoaded', function() {
    // Check if user is logged in
    const token = localStorage.getItem('token');
    if (token) {
        try {
            const payload = JSON.parse(atob(token.split('.')[1]));
            if (payload.exp > Date.now() / 1000) {
                currentUser = payload;
                updateNavigation(true);
            } else {
                localStorage.removeItem('token');
            }
        } catch (error) {
            localStorage.removeItem('token');
        }
    }
    
    // Show initial section
    showSection('books');
    loadBooks();
});

// Navigation functions
function showSection(sectionName) {
    // Hide all sections
    document.querySelectorAll('.content-section').forEach(section => {
        section.style.display = 'none';
    });
    
    // Show selected section
    const section = document.getElementById(sectionName + 'Section');
    if (section) {
        section.style.display = 'block';
    }
    
    // Update navigation active state
    document.querySelectorAll('.nav-link').forEach(link => {
        link.classList.remove('active');
    });
    
    // Load section-specific data
    if (sectionName === 'books') {
        loadBooks();
    } else if (sectionName === 'myReviews' && currentUser) {
        loadUserReviews();
    }
}

function updateNavigation(isLoggedIn) {
    const loginNav = document.getElementById('loginNav');
    const registerNav = document.getElementById('registerNav');
    const userNav = document.getElementById('userNav');
    const myReviewsNav = document.getElementById('myReviewsNav');
    const addBookSection = document.getElementById('addBookSection');
    
    if (isLoggedIn) {
        loginNav.style.display = 'none';
        registerNav.style.display = 'none';
        userNav.style.display = 'block';
        myReviewsNav.style.display = 'block';
        addBookSection.style.display = 'block';
        document.getElementById('userWelcome').textContent = `Welcome, ${currentUser.username}!`;
    } else {
        loginNav.style.display = 'block';
        registerNav.style.display = 'block';
        userNav.style.display = 'none';
        myReviewsNav.style.display = 'none';
        addBookSection.style.display = 'none';
    }
}

// Authentication functions
async function login(event) {
    event.preventDefault();
    
    const username = document.getElementById('loginUsername').value;
    const password = document.getElementById('loginPassword').value;
    
    try {
        const response = await fetch(`${API_BASE_URL}/auth/login`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
            },
            body: JSON.stringify({ username, password })
        });
        
        const data = await response.json();
        
        if (response.ok) {
            localStorage.setItem('token', data.token);
            currentUser = {
                userId: data.user.id,
                username: data.user.username,
                email: data.user.email
            };
            updateNavigation(true);
            showAlert('Login successful!', 'success');
            showSection('books');
            
            // Clear form
            document.getElementById('loginUsername').value = '';
            document.getElementById('loginPassword').value = '';
        } else {
            showAlert(data.error || 'Login failed', 'danger');
        }
    } catch (error) {
        showAlert('Network error. Please try again.', 'danger');
    }
}

async function register(event) {
    event.preventDefault();
    
    const username = document.getElementById('registerUsername').value;
    const email = document.getElementById('registerEmail').value;
    const password = document.getElementById('registerPassword').value;
    
    try {
        const response = await fetch(`${API_BASE_URL}/auth/register`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
            },
            body: JSON.stringify({ username, email, password })
        });
        
        const data = await response.json();
        
        if (response.ok) {
            localStorage.setItem('token', data.token);
            currentUser = {
                userId: data.user.id,
                username: data.user.username,
                email: data.user.email
            };
            updateNavigation(true);
            showAlert('Registration successful! Welcome!', 'success');
            showSection('books');
            
            // Clear form
            document.getElementById('registerUsername').value = '';
            document.getElementById('registerEmail').value = '';
            document.getElementById('registerPassword').value = '';
        } else {
            const errors = data.errors || [{ msg: data.error }];
            showAlert(errors.map(e => e.msg).join(', '), 'danger');
        }
    } catch (error) {
        showAlert('Network error. Please try again.', 'danger');
    }
}

function logout() {
    localStorage.removeItem('token');
    currentUser = null;
    updateNavigation(false);
    showAlert('Logged out successfully', 'info');
    showSection('books');
}

// Books functions
async function loadBooks() {
    try {
        showLoadingSpinner('booksGrid');
        
        const response = await fetch(`${API_BASE_URL}/books`);
        const books = await response.json();
        
        displayBooks(books);
    } catch (error) {
        showAlert('Failed to load books', 'danger');
        document.getElementById('booksGrid').innerHTML = '<div class="col-12"><div class="empty-state"><i class="fas fa-exclamation-triangle"></i><h4>Failed to load books</h4><p>Please try again later.</p></div></div>';
    }
}

function displayBooks(books) {
    const grid = document.getElementById('booksGrid');
    
    if (books.length === 0) {
        grid.innerHTML = '<div class="col-12"><div class="empty-state"><i class="fas fa-book"></i><h4>No books found</h4><p>Be the first to add a book!</p></div></div>';
        return;
    }
    
    grid.innerHTML = books.map(book => `
        <div class="col-md-4 col-sm-6 mb-4">
            <div class="card book-card h-100" onclick="showBookDetails(${book.id})">
                <div class="card-body d-flex flex-column">
                    <h5 class="card-title">${escapeHtml(book.title)}</h5>
                    <p class="card-text"><strong>Author:</strong> ${escapeHtml(book.author)}</p>
                    <p class="card-text text-muted flex-grow-1">${book.description ? escapeHtml(book.description.substring(0, 100)) + '...' : 'No description available'}</p>
                    <div class="mt-auto">
                        <div class="d-flex justify-content-between align-items-center">
                            <div class="rating-display">
                                ${book.average_rating ? '★'.repeat(Math.round(book.average_rating)) + ' ' + book.average_rating : 'No ratings yet'}
                            </div>
                            <small class="text-muted">${book.review_count} review${book.review_count !== '1' ? 's' : ''}</small>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    `).join('');
}

async function showBookDetails(bookId) {
    try {
        const response = await fetch(`${API_BASE_URL}/books/${bookId}`);
        const book = await response.json();
        
        document.getElementById('bookModalTitle').textContent = book.title;
        document.getElementById('bookModalBody').innerHTML = `
            <div class="book-stats">
                <div class="row">
                    <div class="col-md-6">
                        <h4><i class="fas fa-star"></i> ${book.average_rating || 'No ratings'}</h4>
                        <p>Average Rating</p>
                    </div>
                    <div class="col-md-6">
                        <h4><i class="fas fa-comments"></i> ${book.review_count}</h4>
                        <p>Total Reviews</p>
                    </div>
                </div>
            </div>
            
            <div class="book-info">
                <h5>Book Information</h5>
                <p><strong>Author:</strong> ${escapeHtml(book.author)}</p>
                ${book.isbn ? `<p><strong>ISBN:</strong> ${escapeHtml(book.isbn)}</p>` : ''}
                ${book.description ? `<p><strong>Description:</strong> ${escapeHtml(book.description)}</p>` : ''}
                
                ${currentUser ? `
                    <button class="btn btn-review" onclick="openReviewModal(${book.id})">
                        <i class="fas fa-pen"></i> Write a Review
                    </button>
                ` : '<p class="text-muted">Login to write a review</p>'}
            </div>
            
            <div class="mt-4">
                <h5>Reviews</h5>
                <div id="reviewsList">
                    ${book.reviews && book.reviews.length > 0 ? 
                        book.reviews.map(review => `
                            <div class="review-card card">
                                <div class="card-body">
                                    <div class="d-flex justify-content-between align-items-start">
                                        <div>
                                            <div class="star-rating">${'★'.repeat(review.rating)}</div>
                                            <div class="review-meta">
                                                By ${escapeHtml(review.username)} • ${new Date(review.created_at).toLocaleDateString()}
                                            </div>
                                        </div>
                                    </div>
                                    ${review.review_text ? `<p class="mt-2">${escapeHtml(review.review_text)}</p>` : ''}
                                </div>
                            </div>
                        `).join('') 
                        : '<p class="text-muted">No reviews yet. Be the first to review this book!</p>'
                    }
                </div>
            </div>
        `;
        
        new bootstrap.Modal(document.getElementById('bookModal')).show();
    } catch (error) {
        showAlert('Failed to load book details', 'danger');
    }
}

async function searchBooks() {
    const query = document.getElementById('searchInput').value.trim();
    
    if (!query) {
        loadBooks();
        return;
    }
    
    try {
        showLoadingSpinner('booksGrid');
        
        const response = await fetch(`${API_BASE_URL}/books/search/${encodeURIComponent(query)}`);
        const books = await response.json();
        
        displayBooks(books);
    } catch (error) {
        showAlert('Search failed', 'danger');
    }
}

// Add book functions
function showAddBookForm() {
    document.getElementById('addBookForm').style.display = 'block';
}

function hideAddBookForm() {
    document.getElementById('addBookForm').style.display = 'none';
    // Clear form
    document.getElementById('bookTitle').value = '';
    document.getElementById('bookAuthor').value = '';
    document.getElementById('bookIsbn').value = '';
    document.getElementById('bookDescription').value = '';
}

async function addBook(event) {
    event.preventDefault();
    
    if (!currentUser) {
        showAlert('Please login to add books', 'warning');
        return;
    }
    
    const title = document.getElementById('bookTitle').value;
    const author = document.getElementById('bookAuthor').value;
    const isbn = document.getElementById('bookIsbn').value;
    const description = document.getElementById('bookDescription').value;
    
    try {
        const response = await fetch(`${API_BASE_URL}/books`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                'Authorization': `Bearer ${localStorage.getItem('token')}`
            },
            body: JSON.stringify({ title, author, isbn, description })
        });
        
        const data = await response.json();
        
        if (response.ok) {
            showAlert('Book added successfully!', 'success');
            hideAddBookForm();
            loadBooks();
        } else {
            const errors = data.errors || [{ msg: data.error }];
            showAlert(errors.map(e => e.msg).join(', '), 'danger');
        }
    } catch (error) {
        showAlert('Failed to add book', 'danger');
    }
}

// Review functions
function openReviewModal(bookId) {
    document.getElementById('reviewBookId').value = bookId;
    document.getElementById('reviewRating').value = '';
    document.getElementById('reviewText').value = '';
    new bootstrap.Modal(document.getElementById('reviewModal')).show();
}

async function submitReview(event) {
    event.preventDefault();
    
    if (!currentUser) {
        showAlert('Please login to submit reviews', 'warning');
        return;
    }
    
    const bookId = document.getElementById('reviewBookId').value;
    const rating = document.getElementById('reviewRating').value;
    const reviewText = document.getElementById('reviewText').value;
    
    try {
        const response = await fetch(`${API_BASE_URL}/reviews`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                'Authorization': `Bearer ${localStorage.getItem('token')}`
            },
            body: JSON.stringify({
                book_id: parseInt(bookId),
                rating: parseInt(rating),
                review_text: reviewText
            })
        });
        
        const data = await response.json();
        
        if (response.ok) {
            showAlert('Review submitted successfully!', 'success');
            bootstrap.Modal.getInstance(document.getElementById('reviewModal')).hide();
            bootstrap.Modal.getInstance(document.getElementById('bookModal')).hide();
            loadBooks();
        } else {
            const errors = data.errors || [{ msg: data.error }];
            showAlert(errors.map(e => e.msg).join(', '), 'danger');
        }
    } catch (error) {
        showAlert('Failed to submit review', 'danger');
    }
}

async function loadUserReviews() {
    if (!currentUser) return;
    
    try {
        showLoadingSpinner('myReviewsGrid');
        
        const response = await fetch(`${API_BASE_URL}/reviews/user/${currentUser.userId}`);
        const reviews = await response.json();
        
        const grid = document.getElementById('myReviewsGrid');
        
        if (reviews.length === 0) {
            grid.innerHTML = '<div class="col-12"><div class="empty-state"><i class="fas fa-star"></i><h4>No reviews yet</h4><p>Start by reviewing some books!</p></div></div>';
            return;
        }
        
        grid.innerHTML = reviews.map(review => `
            <div class="col-md-6 mb-4">
                <div class="card review-card">
                    <div class="card-body">
                        <h5 class="card-title">${escapeHtml(review.title)}</h5>
                        <p class="card-text"><strong>Author:</strong> ${escapeHtml(review.author)}</p>
                        <div class="star-rating mb-2">${'★'.repeat(review.rating)}</div>
                        ${review.review_text ? `<p class="card-text">${escapeHtml(review.review_text)}</p>` : ''}
                        <small class="text-muted">Reviewed on ${new Date(review.created_at).toLocaleDateString()}</small>
                    </div>
                </div>
            </div>
        `).join('');
    } catch (error) {
        showAlert('Failed to load your reviews', 'danger');
        document.getElementById('myReviewsGrid').innerHTML = '<div class="col-12"><div class="empty-state"><i class="fas fa-exclamation-triangle"></i><h4>Failed to load reviews</h4><p>Please try again later.</p></div></div>';
    }
}

// Utility functions
function showAlert(message, type) {
    const alertContainer = document.getElementById('alertContainer');
    const alertId = 'alert-' + Date.now();
    
    const alertHtml = `
        <div id="${alertId}" class="alert alert-${type} alert-dismissible fade show" role="alert">
            ${escapeHtml(message)}
            <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
        </div>
    `;
    
    alertContainer.innerHTML = alertHtml;
    
    // Auto-dismiss after 5 seconds
    setTimeout(() => {
        const alert = document.getElementById(alertId);
        if (alert) {
            bootstrap.Alert.getOrCreateInstance(alert).close();
        }
    }, 5000);
}

function showLoadingSpinner(containerId) {
    document.getElementById(containerId).innerHTML = `
        <div class="col-12">
            <div class="loading-spinner">
                <div class="spinner-border text-primary" role="status">
                    <span class="visually-hidden">Loading...</span>
                </div>
                <p class="mt-2">Loading...</p>
            </div>
        </div>
    `;
}

function escapeHtml(text) {
    const div = document.createElement('div');
    div.textContent = text;
    return div.innerHTML;
}

// Event listeners
document.getElementById('searchInput').addEventListener('keypress', function(e) {
    if (e.key === 'Enter') {
        searchBooks();
    }
});