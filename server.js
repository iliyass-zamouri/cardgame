// index.js
const express = require('express');
const http = require('http');
const socketIo = require('socket.io');
const { sequelize, User, Match } = require('./db');
const jwt = require('jsonwebtoken');

const app = express();
const server = http.createServer(app);
const io = socketIo(server);

// JWT Secret - In production, use environment variable
const JWT_SECRET = 'your-super-secret-jwt-key-change-in-production';

let rooms = {}; // Store game rooms
let waitlist = []; // Store waiting users for matchmaking
let socketUsers = {}; // Map socket.id to user info

// Enhanced logging function
function log(level, message, data = null) {
    const timestamp = new Date().toISOString();
    const logEntry = `[${timestamp}] [${level}] ${message}`;
    console.log(logEntry);
    if (data) {
        console.log('Data:', JSON.stringify(data, null, 2));
    }
}

// Generate JWT token
function generateToken(user) {
    return jwt.sign(
        { 
            userId: user.id, 
            username: user.username 
        },
        JWT_SECRET,
        { expiresIn: '7d' } // Token expires in 7 days
    );
}

// Verify JWT token
function verifyToken(token) {
    try {
        return jwt.verify(token, JWT_SECRET);
    } catch (error) {
        log('WARN', 'JWT verification failed', { error: error.message });
        return null;
    }
}

// Middleware to verify JWT for protected routes
function authenticateToken(req, res, next) {
    const authHeader = req.headers['authorization'];
    const token = authHeader && authHeader.split(' ')[1]; // Bearer TOKEN

    if (!token) {
        log('WARN', 'Protected route accessed without token', { path: req.path });
        return res.status(401).send({ message: 'Access token required' });
    }

    const decoded = verifyToken(token);
    if (!decoded) {
        return res.status(403).send({ message: 'Invalid or expired token' });
    }

    req.user = decoded;
    next();
}

app.use(express.json());

// User registration
app.post('/register', async (req, res) => {
    const { username, password } = req.body;
    log('INFO', 'Registration attempt', { username });

    try {
        // Check if user already exists
        const existingUser = await User.findOne({ where: { username } });
        if (existingUser) {
            log('WARN', 'Registration failed - username exists', { username });
            return res.status(400).send({ message: 'Username already exists' });
        }

        // Create new user
        const user = await User.create({ username, password });
        log('INFO', 'Registration successful', { userId: user.id, username });
        res.status(201).send({ message: 'Registration successful', userId: user.id });
    } catch (error) {
        log('ERROR', 'Registration error', { username, error: error.message });
        res.status(500).send({ message: 'Server error' });
    }
});

// User login
app.post('/login', async (req, res) => {
    const { username, password } = req.body;
    log('INFO', 'Login attempt', { username });

    try {
        const user = await User.findOne({ where: { username, password } });
        if (user) {
            const token = generateToken(user);
            log('INFO', 'Login successful', { 
                userId: user.id, 
                username: user.username,
                totalPoints: user.totalPoints 
            });
            res.status(200).send({ 
                message: 'Login successful', 
                token: token,
                userId: user.id,
                username: user.username,
                totalPoints: user.totalPoints,
                wins: user.wins,
                losses: user.losses,
                currentStreak: user.currentStreak
            });
        } else {
            log('WARN', 'Login failed - invalid credentials', { username });
            res.status(401).send({ message: 'Invalid credentials' });
        }
    } catch (error) {
        log('ERROR', 'Login error', { username, error: error.message });
        res.status(500).send({ message: 'Server error' });
    }
});

// Protected routes
app.get('/user/:userId/stats', authenticateToken, async (req, res) => {
    const userId = req.params.userId;
    const authenticatedUserId = req.user.userId;
    
    // Users can only access their own stats
    if (userId !== authenticatedUserId) {
        log('WARN', 'Unauthorized stats access attempt', { 
            authenticatedUserId, 
            requestedUserId: userId 
        });
        return res.status(403).send({ message: 'Access denied' });
    }
    
    log('INFO', 'Stats request', { userId });

    try {
        const user = await User.findByPk(userId);
        if (!user) {
            log('WARN', 'Stats request - user not found', { userId });
            return res.status(404).send({ message: 'User not found' });
        }
        
        log('INFO', 'Stats retrieved', { userId, totalPoints: user.totalPoints });
        res.status(200).send({
            username: user.username,
            totalPoints: user.totalPoints,
            wins: user.wins,
            losses: user.losses,
            currentStreak: user.currentStreak,
            bestStreak: user.bestStreak
        });
    } catch (error) {
        log('ERROR', 'Stats error', { userId, error: error.message });
        res.status(500).send({ message: 'Server error' });
    }
});

app.get('/user/:userId/matches', authenticateToken, async (req, res) => {
    const userId = req.params.userId;
    const authenticatedUserId = req.user.userId;
    
    // Users can only access their own match history
    if (userId !== authenticatedUserId) {
        log('WARN', 'Unauthorized match history access attempt', { 
            authenticatedUserId, 
            requestedUserId: userId 
        });
        return res.status(403).send({ message: 'Access denied' });
    }
    
    log('INFO', 'Match history request', { userId });

    try {
        const matches = await Match.findAll({
            where: {
                [sequelize.Op.or]: [
                    { player1Id: userId },
                    { player2Id: userId }
                ]
            },
            include: [
                { model: User, as: 'player1', attributes: ['username'] },
                { model: User, as: 'player2', attributes: ['username'] },
                { model: User, as: 'winner', attributes: ['username'] }
            ],
            order: [['startedAt', 'DESC']]
        });
        
        log('INFO', 'Match history retrieved', { userId, matchCount: matches.length });
        res.status(200).send(matches);
    } catch (error) {
        log('ERROR', 'Match history error', { userId, error: error.message });
        res.status(500).send({ message: 'Server error' });
    }
});

// Token validation endpoint
app.post('/validate-token', authenticateToken, (req, res) => {
    res.status(200).send({
        valid: true,
        user: req.user
    });
});

io.on('connection', (socket) => {
    log('INFO', 'New socket connection', { socketId: socket.id });

    // User authentication
    socket.on('authenticate', async (data) => {
        const { userId } = data;
        log('INFO', 'Socket authentication attempt', { socketId: socket.id, userId });
        
        try {
            const user = await User.findByPk(userId);
            if (user) {
                socketUsers[socket.id] = {
                    userId: user.id,
                    username: user.username,
                    totalPoints: user.totalPoints
                };
                socket.emit('authenticated', { 
                    userId: user.id, 
                    username: user.username,
                    totalPoints: user.totalPoints 
                });
                log('INFO', 'Socket authentication successful', { 
                    socketId: socket.id, 
                    userId: user.id, 
                    username: user.username 
                });
            } else {
                log('WARN', 'Socket authentication failed - user not found', { socketId: socket.id, userId });
                socket.emit('authenticationError', { message: 'User not found' });
            }
        } catch (error) {
            log('ERROR', 'Socket authentication error', { socketId: socket.id, userId, error: error.message });
            socket.emit('authenticationError', { message: 'Server error' });
        }
    });

    // Create game room
    socket.on('createRoom', (data) => {
        const userInfo = socketUsers[socket.id];
        if (!userInfo) {
            log('WARN', 'Create room failed - not authenticated', { socketId: socket.id });
            return socket.emit('error', { message: 'Please authenticate first' });
        }

        const roomID = `room_${socket.id}_${Date.now()}`;
        const roomCode = roomID.replace('room_', '').slice(-8);
        
        rooms[roomID] = {
            players: [socket.id],
            playerInfo: [userInfo],
            cards: [],
            status: 'waiting',
            createdAt: new Date(),
            roomCode: roomCode
        };
        
        socket.join(roomID);
        
        log('INFO', 'Room created', { 
            roomID, 
            roomCode, 
            creator: userInfo.username,
            creatorId: userInfo.userId 
        });
        
        // Start the game immediately and show room code overlay
        socket.emit('roomCreated', { 
            roomID,
            roomCode,
            isHost: true,
            message: 'Game started! Share this code with your friend.'
        });
    });

    // Join game room
    socket.on('joinRoom', async (data) => {
        const userInfo = socketUsers[socket.id];
        if (!userInfo) {
            log('WARN', 'Join room failed - not authenticated', { socketId: socket.id });
            return socket.emit('error', { message: 'Please authenticate first' });
        }

        const { roomCode } = data;
        log('INFO', 'Room join attempt', { socketId: socket.id, roomCode, username: userInfo.username });
        
        const roomID = Object.keys(rooms).find(id => id.includes(roomCode));
        
        if (!roomID || !rooms[roomID]) {
            log('WARN', 'Join room failed - room not found', { socketId: socket.id, roomCode });
            return socket.emit('error', { message: 'Room not found' });
        }

        if (rooms[roomID].players.length >= 2) {
            log('WARN', 'Join room failed - room full', { socketId: socket.id, roomCode });
            return socket.emit('error', { message: 'Room is full' });
        }

        rooms[roomID].players.push(socket.id);
        rooms[roomID].playerInfo.push(userInfo);
        socket.join(roomID);
        
        log('INFO', 'Player joined room', { 
            roomID, 
            roomCode, 
            player: userInfo.username,
            playerId: userInfo.userId,
            totalPlayers: rooms[roomID].players.length 
        });
        
        // Create match record
        try {
            const match = await Match.create({
                player1Id: rooms[roomID].playerInfo[0].userId,
                player2Id: userInfo.userId,
                player1Points: rooms[roomID].playerInfo[0].totalPoints,
                player2Points: userInfo.totalPoints,
                pointsExchanged: 0,
                status: 'ongoing'
            });
            
            rooms[roomID].matchId = match.id;
            rooms[roomID].status = 'playing';
            
            log('INFO', 'Match created', { 
                matchId: match.id,
                player1: rooms[roomID].playerInfo[0].username,
                player2: userInfo.username
            });
            
            // Notify both players to start game
            io.to(roomID).emit('gameStart', { 
                matchId: match.id,
                players: rooms[roomID].playerInfo,
                roomID,
                roomCode: roomCode
            });
            
        } catch (error) {
            log('ERROR', 'Match creation error', { roomID, error: error.message });
            socket.emit('error', { message: 'Failed to start game' });
        }
    });

    // Join waitlist for matchmaking
    socket.on('joinWaitlist', async () => {
        const userInfo = socketUsers[socket.id];
        if (!userInfo) {
            return socket.emit('error', { message: 'Please authenticate first' });
        }

        // Check if user is already in waitlist
        if (waitlist.find(w => w.socketId === socket.id)) {
            return socket.emit('error', { message: 'Already in waitlist' });
        }

        waitlist.push({
            socketId: socket.id,
            ...userInfo,
            joinedAt: new Date()
        });

        socket.emit('joinedWaitlist', { position: waitlist.length });
        console.log(`${userInfo.username} joined waitlist (${waitlist.length} waiting)`);
        
        // Try to find a match
        await tryMatchmaking();
    });

    // Leave waitlist
    socket.on('leaveWaitlist', () => {
        waitlist = waitlist.filter(w => w.socketId !== socket.id);
        socket.emit('leftWaitlist');
        console.log(`User ${socket.id} left waitlist (${waitlist.length} waiting)`);
    });

    // Play card in game
    socket.on('playCard', (data) => {
        const { roomID, card } = data;
        if (rooms[roomID]) {
            rooms[roomID].cards.push(card);
            rooms[roomID].lastPlayedBy = socket.id;
            rooms[roomID].lastPlayedAt = new Date();
            
            io.to(roomID).emit('cardPlayed', { 
                player: socketUsers[socket.id]?.username || 'Unknown',
                card 
            });
            
            console.log(`Card played by ${socketUsers[socket.id]?.username} in room ${roomID}`);
        }
    });

    // End game and update stats
    socket.on('endGame', async (data) => {
        const { roomID, winnerId, isDraw } = data;
        const room = rooms[roomID];
        
        if (!room || !room.matchId) {
            return socket.emit('error', { message: 'Game not found' });
        }

        try {
            const match = await Match.findByPk(room.matchId);
            if (!match) return;

            const player1 = await User.findByPk(match.player1Id);
            const player2 = await User.findByPk(match.player2Id);

            let pointsExchanged = 0;
            const basePoints = 50; // Base points for winning
            
            if (isDraw) {
                match.status = 'draw';
                pointsExchanged = 10;
                player1.totalPoints += pointsExchanged;
                player2.totalPoints += pointsExchanged;
                player1.currentStreak = 0;
                player2.currentStreak = 0;
            } else {
                const winner = winnerId === match.player1Id ? player1 : player2;
                const loser = winnerId === match.player1Id ? player2 : player1;
                
                // Calculate points based on difference
                const pointDiff = Math.abs(player1.totalPoints - player2.totalPoints);
                const multiplier = pointDiff > 500 ? 1.5 : pointDiff > 200 ? 1.2 : 1.0;
                pointsExchanged = Math.round(basePoints * multiplier);
                
                match.winnerId = winnerId;
                match.status = 'completed';
                
                // Update winner
                winner.totalPoints += pointsExchanged;
                winner.wins += 1;
                winner.currentStreak += 1;
                if (winner.currentStreak > winner.bestStreak) {
                    winner.bestStreak = winner.currentStreak;
                }
                
                // Update loser
                loser.totalPoints = Math.max(0, loser.totalPoints - pointsExchanged);
                loser.losses += 1;
                loser.currentStreak = 0;
            }
            
            match.pointsExchanged = pointsExchanged;
            match.endedAt = new Date();
            
            await match.save();
            await player1.save();
            await player2.save();
            
            // Notify players
            io.to(roomID).emit('gameEnded', {
                winnerId,
                isDraw,
                pointsExchanged,
                player1Stats: {
                    totalPoints: player1.totalPoints,
                    wins: player1.wins,
                    losses: player1.losses,
                    currentStreak: player1.currentStreak
                },
                player2Stats: {
                    totalPoints: player2.totalPoints,
                    wins: player2.wins,
                    losses: player2.losses,
                    currentStreak: player2.currentStreak
                }
            });
            
            console.log(`Game ended in room ${roomID}. Winner: ${winnerId}, Points: ${pointsExchanged}`);
            
            // Clean up room
            delete rooms[roomID];
            
        } catch (error) {
            console.error('End game error:', error);
            socket.emit('error', { message: 'Failed to end game' });
        }
    });

    socket.on('disconnect', () => {
        console.log('A user disconnected:', socket.id);
        
        // Remove from waitlist
        waitlist = waitlist.filter(w => w.socketId !== socket.id);
        
        // Clean up rooms
        for (let roomID in rooms) {
            const room = rooms[roomID];
            if (room.players.includes(socket.id)) {
                // Notify other player
                socket.to(roomID).emit('playerDisconnected', { 
                    message: 'Opponent disconnected' 
                });
                
                // End match if ongoing
                if (room.matchId) {
                    Match.update(
                        { status: 'completed', endedAt: new Date() },
                        { where: { id: room.matchId } }
                    );
                }
                
                delete rooms[roomID];
            }
        }
        
        // Remove user mapping
        delete socketUsers[socket.id];
    });
});

// Matchmaking function
async function tryMatchmaking() {
    if (waitlist.length < 2) return;
    
    // Sort by points for better matching
    waitlist.sort((a, b) => a.totalPoints - b.totalPoints);
    
    // Find best matches (within 200 points difference)
    for (let i = 0; i < waitlist.length - 1; i++) {
        for (let j = i + 1; j < waitlist.length; j++) {
            const player1 = waitlist[i];
            const player2 = waitlist[j];
            
            const pointDiff = Math.abs(player1.totalPoints - player2.totalPoints);
            
            // Match if within 200 points or if waiting more than 30 seconds
            const waitTime = Date.now() - Math.max(player1.joinedAt, player2.joinedAt);
            const shouldMatch = pointDiff <= 200 || waitTime > 30000;
            
            if (shouldMatch) {
                // Create room
                const roomID = `match_${Date.now()}`;
                const player1Socket = io.sockets.sockets.get(player1.socketId);
                const player2Socket = io.sockets.sockets.get(player2.socketId);
                
                if (!player1Socket || !player2Socket) continue;
                
                rooms[roomID] = {
                    players: [player1.socketId, player2.socketId],
                    playerInfo: [player1, player2],
                    cards: [],
                    status: 'playing',
                    createdAt: new Date()
                };
                
                // Create match
                try {
                    const match = await Match.create({
                        player1Id: player1.userId,
                        player2Id: player2.userId,
                        player1Points: player1.totalPoints,
                        player2Points: player2.totalPoints,
                        pointsExchanged: 0,
                        status: 'ongoing'
                    });
                    
                    rooms[roomID].matchId = match.id;
                    
                    // Join both players to room
                    player1Socket.join(roomID);
                    player2Socket.join(roomID);
                    
                    // Notify players
                    player1Socket.emit('matchFound', {
                        opponent: player2,
                        roomID,
                        matchId: match.id
                    });
                    
                    player2Socket.emit('matchFound', {
                        opponent: player1,
                        roomID,
                        matchId: match.id
                    });
                    
                    // Remove from waitlist
                    waitlist = waitlist.filter(w => w.socketId !== player1.socketId && w.socketId !== player2.socketId);
                    
                    console.log(`Matched ${player1.username} vs ${player2.username} (diff: ${pointDiff} points)`);
                    return; // Exit after one match
                    
                } catch (error) {
                    console.error('Match creation error:', error);
                }
            }
        }
    }
}

server.listen(3000, () => {
    console.log('Server is running on port 3000');
});
