// Home screen menu layout served through GET /app/config. The client owns
// each entry's look and action; the server only picks which ids show and in
// what order. Unknown ids are dropped here and ignored by older clients.
const HOME_MODES = ['createRoom', 'joinRoom', 'playVsRobot'];
const HOME_NAV = ['shop', 'friends', 'home', 'collection', 'rules'];

function parseIds(raw, allowed) {
  if (raw == null || raw.trim() === '') return [...allowed];
  const ids = raw
    .split(',')
    .map((id) => id.trim())
    .filter((id) => allowed.includes(id));
  return [...new Set(ids)];
}

function homeMenuFromEnv(env = process.env) {
  const nav = parseIds(env.HOME_MENU_NAV, HOME_NAV);
  // Home is the screen itself, so its tab can never be hidden.
  if (!nav.includes('home')) nav.splice(Math.floor(nav.length / 2), 0, 'home');
  return {
    modes: parseIds(env.HOME_MENU_MODES, HOME_MODES),
    nav,
  };
}

module.exports = { HOME_MODES, HOME_NAV, homeMenuFromEnv };
