const test = require('node:test');
const assert = require('node:assert/strict');

const { HOME_MODES, HOME_NAV, homeMenuFromEnv } = require('../home_menu');

test('defaults to every entry when unset', () => {
  assert.deepEqual(homeMenuFromEnv({}), { modes: HOME_MODES, nav: HOME_NAV });
});

test('keeps configured order and drops unknown or duplicate ids', () => {
  const menu = homeMenuFromEnv({
    HOME_MENU_MODES: ' playVsRobot, bogus ,createRoom,playVsRobot',
    HOME_MENU_NAV: 'rules,home,shop',
  });
  assert.deepEqual(menu.modes, ['playVsRobot', 'createRoom']);
  assert.deepEqual(menu.nav, ['rules', 'home', 'shop']);
});

test('always keeps the home tab', () => {
  assert.deepEqual(homeMenuFromEnv({ HOME_MENU_NAV: 'shop,friends' }).nav, [
    'shop',
    'home',
    'friends',
  ]);
});

test('an unknown-only list hides every mode', () => {
  assert.deepEqual(homeMenuFromEnv({ HOME_MENU_MODES: 'nope' }).modes, []);
});
