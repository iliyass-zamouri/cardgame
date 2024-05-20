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
    }
});

sequelize.sync()
    .then(() => console.log('Database & tables created!'))
    .catch(err => console.log('Error creating database: ', err));

module.exports = { sequelize, User };
