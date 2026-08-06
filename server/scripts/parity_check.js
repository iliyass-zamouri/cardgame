import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { ALL_EVENTS } from '../src/protocol.js';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const eventsPath = path.resolve(
  __dirname,
  '../../packages/game_protocol/lib/src/events.dart',
);
const dart = fs.readFileSync(eventsPath, 'utf8');
const dartEvents = [...dart.matchAll(/static const \w+ = '([^']+)';/g)].map(
  (m) => m[1],
);
const dartSet = new Set(dartEvents);
const jsSet = new Set(ALL_EVENTS);

const missingInJs = dartEvents.filter((e) => !jsSet.has(e));
const missingInDart = ALL_EVENTS.filter((e) => !dartSet.has(e));

if (missingInJs.length || missingInDart.length) {
  console.error('Protocol parity FAILED');
  if (missingInJs.length) console.error('Missing in JS:', missingInJs);
  if (missingInDart.length) console.error('Missing in Dart:', missingInDart);
  process.exit(1);
}

console.log(`Protocol parity OK (${ALL_EVENTS.length} events)`);
