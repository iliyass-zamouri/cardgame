const test = require('node:test');
const assert = require('node:assert/strict');
const {
  DEFAULTS,
  FEEDBACK_TAGS,
  validateConfig,
  normalizeConfig,
  clientView,
  createAppReviewStore,
  staticAppReviewStore,
} = require('../app_review_config');

function draft() {
  return JSON.parse(JSON.stringify(DEFAULTS));
}

function memoryStore(initial = null) {
  let current = initial;
  let previous = null;
  return createAppReviewStore({
    read: async () => current,
    write: async (config) => {
      current = config;
    },
    readPrevious: async () => previous,
    writePrevious: async (config) => {
      previous = config;
    },
    onReadError: () => {},
  });
}

test('the defaults are a valid config', () => {
  const { config, error } = validateConfig(draft());
  assert.equal(error, undefined);
  assert.deepEqual(config, draft());
});

test('validateConfig rejects bad values with a message the admin can act on', () => {
  const cases = [
    [(c) => { c.storeMinStars = 6; }, /storeMinStars must be a whole number from 1 to 5/],
    [(c) => { c.storeMinStars = 3.5; }, /storeMinStars/],
    [(c) => { c.flow.ios = 'always'; }, /flow.ios must be one of gated, native_only/],
    [(c) => { c.iosAppStoreId = 'id123'; }, /iosAppStoreId/],
    [(c) => { c.rules.maxPrompts = 0; }, /rules.maxPrompts/],
    [(c) => { c.rules.extra = 1; }, /rules has unknown field: extra/],
    [(c) => { c.triggers.win = 'yes'; }, /triggers.win must be true or false/],
    [(c) => { c.feedback.tags = ['bugs', 'nope']; }, /feedback.tags must be one of/],
    [(c) => { c.push.sendWindowUtc = [16]; }, /sendWindowUtc must be \[startHour, endHour\]/],
    [(c) => { c.push.sendWindowUtc = [16, 24]; }, /sendWindowUtc end/],
    [(c) => { c.push.title = { fr: 'Salut' }; }, /push.title.en is required/],
    [(c) => { c.push.body.en = 'x'.repeat(201); }, /push.body.en must be text up to 200/],
    [(c) => { delete c.push; }, /push must be an object/],
  ];
  for (const [mutate, message] of cases) {
    const config = draft();
    mutate(config);
    const result = validateConfig(config);
    assert.equal(result.error, 'invalid_value', String(message));
    assert.match(result.message, message);
  }
});

test('validateConfig trims the App Store id and keeps tags in canonical order', () => {
  const config = draft();
  config.iosAppStoreId = ' 6450000000 ';
  config.feedback.tags = ['other', 'bugs', 'bugs', 'ads'];
  const result = validateConfig(config).config;
  assert.equal(result.iosAppStoreId, '6450000000');
  assert.deepEqual(result.feedback.tags, ['bugs', 'ads', 'other']);
  assert.ok(result.feedback.tags.every((tag) => FEEDBACK_TAGS.includes(tag)));
});

test('normalizeConfig falls back to the defaults for a broken stored value', () => {
  const originalError = console.error;
  console.error = () => {};
  try {
    assert.equal(normalizeConfig(null), DEFAULTS);
    assert.equal(normalizeConfig({ enabled: 'maybe' }), DEFAULTS);
  } finally {
    console.error = originalError;
  }
});

test('clientView picks the flow for the platform and hides the admin-only knobs', () => {
  const config = draft();
  config.flow.ios = 'native_only';
  config.iosAppStoreId = '123';
  assert.equal(clientView(config, 'android').flow, 'gated');
  assert.equal(clientView(config, 'ios').flow, 'native_only');
  assert.equal(clientView(config, 'macos').flow, 'native_only');
  const other = clientView(config, 'other');
  assert.equal(other.hasStore, false);
  assert.equal(other.flow, 'gated');
  const view = clientView(config, 'ios');
  assert.equal(view.iosAppStoreId, '123');
  assert.equal(view.rules, undefined);
  assert.equal(view.push, undefined);
});

test('the store saves, keeps the previous version and reverts', async () => {
  const store = memoryStore();
  await store.refresh();
  assert.equal(store.current().source, 'default');
  assert.equal(await store.hasPrevious(), false);

  const first = draft();
  first.storeMinStars = 5;
  await store.set(first);
  assert.equal(store.current().storeMinStars, 5);
  assert.equal(store.current().source, 'admin');

  const second = draft();
  second.storeMinStars = 3;
  await store.set(second);
  assert.equal(await store.hasPrevious(), true);

  const restored = await store.revert();
  assert.equal(restored.storeMinStars, 5);
  // A second revert undoes the first.
  assert.equal((await store.revert()).storeMinStars, 3);
});

test('revert without a previous version fails with no_previous', async () => {
  await assert.rejects(memoryStore().revert(), { code: 'no_previous' });
  await assert.rejects(staticAppReviewStore().revert(), { code: 'no_previous' });
  await assert.rejects(staticAppReviewStore().set(draft()), { code: 'read_only' });
});
