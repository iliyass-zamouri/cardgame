import { initDb, closeDb } from '../infra/db.js';

await initDb();
console.log('Migrations complete');
await closeDb();
