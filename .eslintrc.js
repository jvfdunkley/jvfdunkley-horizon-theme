/* eslint-env node */

module.exports = {
  extends: ['eslint:recommended'],
  globals: {
    console: false,
    require: false,
    Swiper: 'readonly',
  },
  env: {
    es6: true,
    browser: true,
  },
  rules: {
    indent: ['off', 4],
    'no-var': 'error',
    'no-console': 'off',
    'no-irregular-whitespace': 'error',
    'no-mixed-spaces-and-tabs': 'error',
    'no-unused-vars': 'error',
  },
  parser: 'babel-eslint',
  parserOptions: {
    sourceType: 'module',
    ecmaVersion: 6,
    ecmaFeatures: {
      experimentalObjectRestSpread: true,
    },
  },
};
