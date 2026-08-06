require('dotenv').config();

const { GameServer } = require('./game_server');
const { initDb, closeDb } = require('./db/pool');

const gameServer = new GameServer({
  host: process.env.HOST ?? '127.0.0.1',
  port: Number(process.env.PORT ?? 8080),
});

async function main() {
  await initDb();
  const { host, port } = await gameServer.start();
  console.log(`Authoritative game server listening at ws://${host}:${port}`);
  console.log(`Auth HTTP ready at http://${host}:${port}/auth/*`);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});

async function shutdown() {
  await gameServer.stop();
  await closeDb();
  process.exit(0);
}

process.on('SIGINT', shutdown);
process.on('SIGTERM', shutdown);
