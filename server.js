// index.js
const express = require('express');
const http = require('http');
const socketIo = require('socket.io');
const { sequelize, User } = require('./db');

const app = express();
const server = http.createServer(app);
const io = socketIo(server);

let rooms = {}; // Store game rooms

app.use(express.json());

app.post('/login', async (req, res) => {
    const { username, password } = req.body;

    try {
        const user = await User.findOne({ where: { username, password } });
        if (user) {
            res.status(200).send({ message: 'Login successful', userId: user.id });
        } else {
            res.status(401).send({ message: 'Invalid credentials' });
        }
    } catch (error) {
        res.status(500).send({ message: 'Server error' });
    }
});

io.on('connection', (socket) => {
    console.log('A user connected:', socket.id);

    socket.on('createRoom', (data) => {
        const roomID = `room_${socket.id}`;
        rooms[roomID] = { players: [socket.id], cards: [] };
        socket.join(roomID);
        socket.emit('roomCreated', { roomID });
        console.log('Room created:', roomID);
    });

    socket.on('joinRoom', (data) => {
        const roomID = data.roomID;
        if (rooms[roomID] && rooms[roomID].players.length < 2) {
            rooms[roomID].players.push(socket.id);
            socket.join(roomID);
            io.to(roomID).emit('start', { players: rooms[roomID].players });
            console.log('User joined room:', roomID);
        } else {
            socket.emit('error', { message: 'Room is full or does not exist' });
        }
    });

    socket.on('playCard', (data) => {
        const roomID = data.roomID;
        const card = data.card;
        if (rooms[roomID]) {
            rooms[roomID].cards.push(card);
            io.to(roomID).emit('cardPlayed', { player: socket.id, card });
            console.log('Card played:', card, 'in room:', roomID);
        }
    });

    socket.on('disconnect', () => {
        console.log('A user disconnected:', socket.id);
        // Clean up rooms
        for (let roomID in rooms) {
            rooms[roomID].players = rooms[roomID].players.filter(player => player !== socket.id);
            if (rooms[roomID].players.length === 0) {
                delete rooms[roomID];
            }
        }
    });
});

server.listen(3000, () => {
    console.log('Server is running on port 3000');
});
