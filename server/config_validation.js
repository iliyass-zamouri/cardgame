// Shared checks for admin-edited JSON configs (daily rewards, marketplace).
// Each helper throws a ConfigError with a message the admin tab shows as is.

const LANGUAGES = ['en', 'fr', 'es', 'pt', 'ar'];

class ConfigError extends Error {}

function invalid(message) {
  throw new ConfigError(message);
}

function isPlainObject(value) {
  return value !== null && typeof value === 'object' && !Array.isArray(value);
}

function requireObject(value, label, allowedKeys) {
  if (!isPlainObject(value)) invalid(`${label} must be an object`);
  const unknown = Object.keys(value).filter((key) => !allowedKeys.includes(key));
  if (unknown.length > 0) invalid(`${label} has unknown field: ${unknown.join(', ')}`);
  return value;
}

function intIn(value, [min, max], label) {
  if (!Number.isInteger(value) || value < min || value > max) {
    invalid(`${label} must be a whole number from ${min} to ${max}`);
  }
  return value;
}

function boolIn(value, label) {
  if (typeof value !== 'boolean') invalid(`${label} must be true or false`);
  return value;
}

function localizedText(value, label, maxLength) {
  requireObject(value, label, LANGUAGES);
  if (typeof value.en !== 'string' || value.en.trim() === '') invalid(`${label}.en is required`);
  const out = {};
  for (const language of LANGUAGES) {
    if (value[language] === undefined) continue;
    if (typeof value[language] !== 'string' || value[language].length > maxLength) {
      invalid(`${label}.${language} must be text up to ${maxLength} characters`);
    }
    out[language] = value[language].trim();
  }
  return out;
}

module.exports = {
  LANGUAGES,
  ConfigError,
  invalid,
  isPlainObject,
  requireObject,
  intIn,
  boolIn,
  localizedText,
};
