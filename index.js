const express = require('express');
const cors = require('cors');
const mysql = require('mysql2');
const url = require('url');
require('dotenv').config();

const app = express();
app.use(cors());
app.use(express.json());

// Parse DATABASE_URL for mysql2
const dbUrl = process.env.DATABASE_URL;
const params = url.parse(dbUrl);
const [user, password] = params.auth.split(':');
const dbConfig = {
    host: params.hostname,
    user,
    password,
    database: params.pathname.replace('/', ''),
    port: params.port,
    ssl: { rejectUnauthorized: true }
};

// Use a connection pool for serverless environments
const pool = mysql.createPool({
    ...dbConfig,
    waitForConnections: true,
    connectionLimit: 3,
    queueLimit: 0
});

// Basic route
app.get('/', (req, res) => {
    res.send('Hello world!!');
});

// Get all users
app.get('/users', (req, res) => {
    pool.query('SELECT * FROM users', function (err, results, fields) {
        if (err) {
            console.error('Error fetching users:', err);
            return res.status(500).send('Error fetching users');
        }
        res.send(results);
    });
});

// Get user by ID
app.get('/users/:id', (req, res) => {
    const id = req.params.id;
    pool.query('SELECT * FROM users WHERE id = ?', [id], function (err, results, fields) {
        if (err) {
            console.error('Error fetching user:', err);
            return res.status(500).send('Error fetching user');
        }
        res.send(results);
    });
});

// Get todo list for a specific user
app.get('/users/:id/todos', (req, res) => {
    const userId = req.params.id;
    pool.query('SELECT * FROM todo_list WHERE user_id = ?', [userId], function (err, results, fields) {
        if (err) {
            console.error('Error fetching todos:', err);
            return res.status(500).send('Error fetching todos');
        }
        res.send(results);
    });
});

// Add a new user
app.post('/users', (req, res) => {
    pool.query(
        'INSERT INTO `users` (`email`, `password`) VALUES (?, ?)',
        [req.body.email, req.body.password],
        function (err, results, fields) {
            if (err) {
                console.error('Error in POST /users:', err);
                return res.status(500).send('Error adding user');
            }
            res.status(200).send(results);
        }
    );
});

// Update user
app.put('/users', (req, res) => {
    pool.query(
        'UPDATE `users` SET `email`=?, `password`=? WHERE id =?',
        [req.body.email, req.body.password, req.body.id],
        function (err, results, fields) {
            if (err) {
                console.error('Error updating user:', err);
                return res.status(500).send('Error updating user');
            }
            res.send(results);
        }
    );
});

// Delete user
app.delete('/users', (req, res) => {
    pool.query(
        'DELETE FROM `users` WHERE id =?',
        [req.body.id],
        function (err, results, fields) {
            if (err) {
                console.error('Error deleting user:', err);
                return res.status(500).send('Error deleting user');
            }
            res.send(results);
        }
    );
});

// Do NOT call app.listen() in Vercel serverless functions

// Export the app for Vercel serverless functions
module.exports = app;
