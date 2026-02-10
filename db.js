// db.js
const { Sequelize } = require('sequelize');

const sequelize = new Sequelize('cardgame_db', 'root', '', {
    host: 'localhost',
    dialect: 'mysql'
});

const User = sequelize.define('User', {
    username: {
        type: Sequelize.STRING,
        allowNull: false,
        unique: true
    },
    password: {
        type: Sequelize.STRING,
        allowNull: false
    },
    totalPoints: {
        type: Sequelize.INTEGER,
        defaultValue: 1000 // Starting points
    },
    wins: {
        type: Sequelize.INTEGER,
        defaultValue: 0
    },
    losses: {
        type: Sequelize.INTEGER,
        defaultValue: 0
    },
    currentStreak: {
        type: Sequelize.INTEGER,
        defaultValue: 0
    },
    bestStreak: {
        type: Sequelize.INTEGER,
        defaultValue: 0
    }
});

const Match = sequelize.define('Match', {
    player1Id: {
        type: Sequelize.INTEGER,
        allowNull: false
    },
    player2Id: {
        type: Sequelize.INTEGER,
        allowNull: false
    },
    winnerId: {
        type: Sequelize.INTEGER,
        allowNull: true // null if draw/ongoing
    },
    player1Points: {
        type: Sequelize.INTEGER,
        allowNull: false
    },
    player2Points: {
        type: Sequelize.INTEGER,
        allowNull: false
    },
    pointsExchanged: {
        type: Sequelize.INTEGER,
        allowNull: false
    },
    status: {
        type: Sequelize.ENUM('ongoing', 'completed', 'draw'),
        defaultValue: 'ongoing'
    },
    startedAt: {
        type: Sequelize.DATE,
        defaultValue: Sequelize.NOW
    },
    endedAt: {
        type: Sequelize.DATE,
        allowNull: true
    }
});

// Define relationships
User.hasMany(Match, { as: 'player1Matches', foreignKey: 'player1Id' });
User.hasMany(Match, { as: 'player2Matches', foreignKey: 'player2Id' });
Match.belongsTo(User, { as: 'player1', foreignKey: 'player1Id' });
Match.belongsTo(User, { as: 'player2', foreignKey: 'player2Id' });
Match.belongsTo(User, { as: 'winner', foreignKey: 'winnerId' });

sequelize.sync()
    .then(() => console.log('Database & tables created!'))
    .catch(err => console.log('Error creating database: ', err));

module.exports = { sequelize, User, Match };
