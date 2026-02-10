const express = require('express');
const http = require('http');
const WebSocket = require('ws');
const { sequelize, User, Match } = require('./db');

const app = express();
const server = http.createServer(app);
const wss = new WebSocket.Server({ server });

let clients = [];
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

// Generate room code
function generateRoomCode(socketId) {
    const timestamp = Date.now().toString();
    const randomSuffix = Math.random().toString(36).substring(2, 4);
    return (timestamp + randomSuffix).slice(-8).toUpperCase();
}

// Ping interval to keep connections alive
const pingInterval = setInterval(() => {
    clients.forEach((ws) => {
        if (ws.readyState === WebSocket.OPEN) {
            ws.ping();
        }
    });
}, 30000); // Ping every 30 seconds

// Clean up on server shutdown
process.on('SIGINT', () => {
    clearInterval(pingInterval);
    server.close(() => {
        console.log('WebSocket server closed');
        process.exit(0);
    });
});

wss.on('connection', (ws) => {
  log('INFO', 'New WebSocket connection', { socketId: ws.id });
  clients.push(ws);
  
  // Add error handling for the WebSocket
  ws.on('error', (error) => {
    log('ERROR', 'WebSocket error', { socketId: ws.id, error: error.message });
  });

  ws.on('message', async (message) => {
    if (Buffer.isBuffer(message)) {
        message = message.toString('utf8');
    }
    
    log('INFO', 'WebSocket message received', { message });
    
    try {
        const data = JSON.parse(message);
        
        switch (data.type) {
            case 'authenticate':
                await handleAuthentication(ws, data);
                break;
            case 'createRoom':
                handleCreateRoom(ws, data);
                break;
            case 'joinRoom':
                handleJoinRoom(ws, data);
                break;
            case 'joinWaitlist':
                handleJoinWaitlist(ws, data);
                break;
            case 'leaveWaitlist':
                handleLeaveWaitlist(ws, data);
                break;
            default:
                log('WARN', 'Unknown message type', { type: data.type });
        }
    } catch (error) {
        log('ERROR', 'Error parsing message', { error: error.message, message });
        ws.send(JSON.stringify({
            type: 'error',
            message: 'Invalid message format'
        }));
    }
  });

  ws.on('close', (code, reason) => {
    log('INFO', 'Client disconnected', { 
        socketId: ws.id, 
        code: code, 
        reason: reason ? reason.toString() : 'No reason provided'
    });
    clients = clients.filter((client) => client !== ws);
    
    // Clean up user data
    if (socketUsers[ws.id]) {
        const userId = socketUsers[ws.id].userId;
        log('INFO', 'Cleaning up user data', { userId, socketId: ws.id });
        delete socketUsers[ws.id];
        
        // Remove from waitlist
        waitlist = waitlist.filter(user => user.userId !== userId);
        
        // Leave room if in one
        for (const roomId in rooms) {
            const room = rooms[roomId];
            if (room.players && room.players.some(p => p.userId === userId)) {
                room.players = room.players.filter(p => p.userId !== userId);
                if (room.players.length === 0) {
                    log('INFO', 'Deleting empty room', { roomId });
                    delete rooms[roomId];
                }
            }
        }
    }
  });
});

async function handleAuthentication(ws, data) {
    const { userId } = data;
    log('INFO', 'WebSocket authentication attempt', { socketId: ws.id, userId });
    
    try {
        const user = await User.findByPk(userId);
        if (user) {
            socketUsers[ws.id] = {
                userId: user.id,
                username: user.username,
                ws: ws
            };
            
            log('INFO', 'WebSocket authentication successful', { 
                socketId: ws.id, 
                userId: user.id, 
                username: user.username 
            });
            
            const authResponse = JSON.stringify({
                type: 'authenticated',
                userId: user.id,
                username: user.username
            });
            
            log('INFO', 'Sending authentication response', { response: authResponse });
            ws.send(authResponse);
        } else {
            log('WARN', 'WebSocket authentication failed - user not found', { userId });
            const errorResponse = JSON.stringify({
                type: 'error',
                message: 'Authentication failed'
            });
            ws.send(errorResponse);
        }
    } catch (error) {
        log('ERROR', 'WebSocket authentication error', { userId, error: error.message });
        const errorResponse = JSON.stringify({
            type: 'error',
            message: 'Authentication error'
        });
        ws.send(errorResponse);
    }
}

function handleCreateRoom(ws, data) {
    const user = socketUsers[ws.id];
    if (!user) {
        log('WARN', 'Create room attempted without authentication', { socketId: ws.id });
        return;
    }
    
    log('INFO', 'Creating room', { userId: user.userId, username: user.username });
    
    const roomCode = generateRoomCode(ws.id);
    const roomId = `room_${roomCode}_${Date.now()}`;
    
    rooms[roomId] = {
        roomCode: roomCode,
        creator: user.username,
        creatorId: user.userId,
        players: [user],
        createdAt: new Date()
    };
    
    log('INFO', 'Room created successfully', { 
        roomId, 
        roomCode, 
        creator: user.username,
        creatorId: user.userId
    });
    
    ws.send(JSON.stringify({
        type: 'roomCreated',
        roomCode: roomCode,
        roomId: roomId,
        creator: user.username
    }));
}

function handleJoinRoom(ws, data) {
    const user = socketUsers[ws.id];
    if (!user) {
        log('WARN', 'Join room attempted without authentication', { socketId: ws.id });
        return;
    }
    
    const { roomCode } = data;
    log('INFO', 'Attempting to join room', { roomCode, userId: user.userId });
    
    // Find room by code
    let targetRoom = null;
    for (const roomId in rooms) {
        if (rooms[roomId].roomCode === roomCode) {
            targetRoom = rooms[roomId];
            break;
        }
    }
    
    if (!targetRoom) {
        log('WARN', 'Room not found', { roomCode });
        ws.send(JSON.stringify({
            type: 'error',
            message: 'Room not found'
        }));
        return;
    }
    
    if (targetRoom.players.length >= 2) {
        log('WARN', 'Room is full', { roomCode });
        ws.send(JSON.stringify({
            type: 'error',
            message: 'Room is full'
        }));
        return;
    }
    
    // Add player to room
    targetRoom.players.push(user);
    
    log('INFO', 'Player joined room successfully', { 
        roomCode, 
        userId: user.userId, 
        playerCount: targetRoom.players.length 
    });
    
    // Notify all players in room
    targetRoom.players.forEach(player => {
        player.ws.send(JSON.stringify({
            type: 'playerJoined',
            roomCode: roomCode,
            players: targetRoom.players.map(p => ({
                userId: p.userId,
                username: p.username
            }))
        }));
    });
    
    // Start game if room is full
    if (targetRoom.players.length === 2) {
        log('INFO', 'Room full, starting game', { roomCode });
        targetRoom.players.forEach(player => {
            player.ws.send(JSON.stringify({
                type: 'gameStart',
                roomCode: roomCode,
                players: targetRoom.players.map(p => ({
                    userId: p.userId,
                    username: p.username
                }))
            }));
        });
    }
}

function handleJoinWaitlist(ws, data) {
    const user = socketUsers[ws.id];
    if (!user) {
        log('WARN', 'Join waitlist attempted without authentication', { socketId: ws.id });
        return;
    }
    
    log('INFO', 'User joined waitlist', { userId: user.userId, username: user.username });
    
    // Check if user is already in waitlist
    if (waitlist.some(u => u.userId === user.userId)) {
        log('WARN', 'User already in waitlist', { userId: user.userId });
        return;
    }
    
    waitlist.push(user);
    
    // Check for match
    if (waitlist.length >= 2) {
        const player1 = waitlist.shift();
        const player2 = waitlist.shift();
        
        const roomCode = generateRoomCode(player1.ws.id);
        const roomId = `room_${roomCode}_${Date.now()}`;
        
        rooms[roomId] = {
            roomCode: roomCode,
            players: [player1, player2],
            createdAt: new Date(),
            isMatchmaking: true
        };
        
        log('INFO', 'Match found, creating room', { 
            roomCode,
            player1: player1.username,
            player2: player2.username
        });
        
        // Notify both players
        [player1, player2].forEach(player => {
            player.ws.send(JSON.stringify({
                type: 'matchFound',
                roomCode: roomCode,
                opponent: player === player1 ? player2.username : player1.username,
                players: [
                    { userId: player1.userId, username: player1.username },
                    { userId: player2.userId, username: player2.username }
                ]
            }));
        });
    } else {
        ws.send(JSON.stringify({
            type: 'waitlistJoined',
            message: 'You are now in the waitlist. Waiting for another player...'
        }));
    }
}

function handleLeaveWaitlist(ws, data) {
    const user = socketUsers[ws.id];
    if (!user) return;
    
    log('INFO', 'User left waitlist', { userId: user.userId, username: user.username });
    
    waitlist = waitlist.filter(u => u.userId !== user.userId);
    
    ws.send(JSON.stringify({
        type: 'waitlistLeft',
        message: 'You left the waitlist'
    }));
}

server.listen(8080, () => {
    console.log('WebSocket server is listening on port 8080');
});
