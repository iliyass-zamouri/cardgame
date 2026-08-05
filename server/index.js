const { GameServer } = require('./game_server');

const gameServer = new GameServer({
  host: process.env.HOST ?? '127.0.0.1',
  port: Number(process.env.PORT ?? 8080),
});

gameServer.start()
  .then(({ host, port }) => {
    console.log(`Authoritative game server listening at ws://${host}:${port}`);
  })
  .catch((error) => {
    console.error(error);
    process.exitCode = 1;
  });

async function shutdown() {
  await gameServer.stop();
  process.exit(0);
}

process.on('SIGINT', shutdown);
process.on('SIGTERM', shutdown);
