// Where a push notification can send a player when tapped. The app resolves
// the same routes in lib/services/notification_deeplink.dart. `legacy` routes
// are the ones app builds from before the full catalogue already open; older
// builds land on Home for the rest.
const { POTS, potById } = require('../pots');

const SHOP_TABS = [
  ['decks', 'Card decks'],
  ['avatars', 'Avatars'],
  ['exchange', 'Exchange'],
];
const RANKING_TABS = [
  ['leaderboard', 'Leaderboard'],
  ['history', 'Match history'],
];
const ROOM_CODE = /^[A-Z0-9]{4,8}$/;

const DEEPLINK_ROUTES = [
  { path: '/', label: 'Home', group: 'screens', legacy: true },
  { path: '/play', label: 'Pot picker', group: 'play', params: ['pot'] },
  { path: '/robot', label: 'Play vs robot', group: 'play' },
  { path: '/join', label: 'Join a room', group: 'play', legacy: true, params: ['roomId'] },
  { path: '/daily', label: 'Daily streak', group: 'screens' },
  { path: '/shop', label: 'Shop', group: 'screens', params: ['tab'] },
  { path: '/collection', label: 'Collection', group: 'screens' },
  { path: '/friends', label: 'Friends', group: 'screens', legacy: true },
  { path: '/ranking', label: 'Ranking', group: 'screens', legacy: true, params: ['tab'] },
  { path: '/profile', label: 'Profile', group: 'screens' },
  { path: '/notifications', label: 'Inbox', group: 'screens' },
  { path: '/settings', label: 'Settings', group: 'screens' },
  { path: '/rules', label: 'How to play', group: 'screens' },
  { path: '/tutorial', label: 'Tutorial', group: 'screens' },
  { path: '/rate', label: 'Rate the app', group: 'screens' },
];

/** Older app builds called the room invite `/table`. */
const PATH_ALIASES = { '/table': '/join' };

function routeFor(path) {
  return DEEPLINK_ROUTES.find((entry) => entry.path === path) || null;
}

function tabLabel(tabs, id) {
  return tabs.find(([key]) => key === id)?.[1] || id;
}

/**
 * Checks a deeplink an admin typed or picked and returns it in canonical
 * form: `{ route }`, with route null for none, or `{ error }`.
 */
function normalizeDeeplink(raw) {
  if (raw == null) return { route: null };
  if (typeof raw !== 'string') return { error: 'route must be a string' };
  const trimmed = raw.trim();
  if (!trimmed) return { route: null };
  if (!trimmed.startsWith('/') || trimmed.startsWith('//')) {
    return { error: 'route must start with a single /' };
  }

  let url;
  try {
    url = new URL(trimmed, 'http://app.invalid');
  } catch {
    return { error: `route ${trimmed} is not a valid path` };
  }
  let path = url.pathname.length > 1 ? url.pathname.replace(/\/+$/, '') : '/';
  path = PATH_ALIASES[path] || path;
  const entry = routeFor(path);
  if (!entry) return { error: `unknown deeplink ${path}` };

  const allowed = entry.params || [];
  const params = new URLSearchParams();
  for (const key of url.searchParams.keys()) {
    if (!allowed.includes(key)) return { error: `${path} does not take ?${key}` };
  }

  if (path === '/play') {
    const pot = url.searchParams.get('pot');
    if (pot) {
      if (!potById(pot)) return { error: `unknown pot ${pot}` };
      params.set('pot', pot);
    }
  } else if (path === '/join') {
    const roomId = (url.searchParams.get('roomId') || '').trim().toUpperCase();
    if (!ROOM_CODE.test(roomId)) return { error: '/join needs ?roomId= with a 4–8 letter room code' };
    params.set('roomId', roomId);
  } else if (path === '/shop' || path === '/ranking') {
    const tab = url.searchParams.get('tab');
    const tabs = path === '/shop' ? SHOP_TABS : RANKING_TABS;
    if (tab) {
      if (!tabs.some(([key]) => key === tab)) return { error: `unknown ${path} tab ${tab}` };
      params.set('tab', tab);
    }
  }

  const query = params.toString();
  return { route: query ? `${path}?${query}` : path };
}

/** A short human label for a stored route, for push history. */
function describeDeeplink(route) {
  if (route == null || route === '') return 'None';
  const { route: canonical, error } = normalizeDeeplink(route);
  if (error || !canonical) return `Unknown · ${route}`;
  const url = new URL(canonical, 'http://app.invalid');
  const entry = routeFor(url.pathname);
  const pot = url.searchParams.get('pot');
  const tab = url.searchParams.get('tab');
  const roomId = url.searchParams.get('roomId');
  if (pot) return `${potById(pot).city} pot`;
  if (roomId) return `Join room ${roomId}`;
  if (tab) return `${entry.label} · ${tabLabel(url.pathname === '/shop' ? SHOP_TABS : RANKING_TABS, tab)}`;
  return entry.label;
}

const LINK_GROUPS = ['Screens', 'Play', 'Pots', 'Shop', 'Ranking'];

/**
 * Every deeplink a push can carry, one entry per concrete route: each screen,
 * each pot, each shop and ranking tab. `/join` needs a room code added.
 */
function deeplinkLinks() {
  const links = [];
  const add = (group, route, label, legacy = false) => links.push({ group, route, label, legacy });
  for (const entry of DEEPLINK_ROUTES) {
    if (entry.path === '/play') {
      add('Play', '/play', 'Pot picker');
      for (const pot of POTS) {
        add('Pots', `/play?pot=${pot.id}`, `${pot.city} · pot ${pot.pool} ${pot.currency}, entry ${Math.floor(pot.pool / 2)}`);
      }
    } else if (entry.path === '/join') {
      add('Play', '/join', 'Join a room (needs a room code)', true);
    } else if (entry.path === '/shop') {
      for (const [id, label] of SHOP_TABS) add('Shop', `/shop?tab=${id}`, `Shop · ${label}`);
    } else if (entry.path === '/ranking') {
      for (const [id, label] of RANKING_TABS) {
        add('Ranking', `/ranking?tab=${id}`, `Ranking · ${label}`, id === 'leaderboard');
      }
    } else {
      add(entry.group === 'play' ? 'Play' : 'Screens', entry.path, entry.label, !!entry.legacy);
    }
  }
  return LINK_GROUPS.flatMap((group) => links.filter((link) => link.group === group));
}

/** Everything the admin push composer needs to build its picker. */
function deeplinkCatalog() {
  return {
    links: deeplinkLinks(),
    routes: DEEPLINK_ROUTES.map((entry) => ({ ...entry, params: entry.params || [] })),
    pots: POTS.map((pot) => ({ ...pot, entry: Math.floor(pot.pool / 2) })),
    shopTabs: SHOP_TABS.map(([id, label]) => ({ id, label })),
    rankingTabs: RANKING_TABS.map(([id, label]) => ({ id, label })),
  };
}

module.exports = {
  DEEPLINK_ROUTES,
  normalizeDeeplink,
  describeDeeplink,
  deeplinkCatalog,
};
