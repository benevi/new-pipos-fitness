// Función de Vercel: delega en la app Nest compilada (ver src/serverless.ts y docs/DEPLOY_VERCEL.md).
module.exports = require('../dist/serverless.js').default;
