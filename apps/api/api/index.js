// Función de Vercel: delega en la app Nest empaquetada (ver src/serverless.ts,
// scripts/bundle-serverless.mjs y docs/DEPLOY_VERCEL.md).
module.exports = require('../dist/bundle/serverless.cjs').default;
