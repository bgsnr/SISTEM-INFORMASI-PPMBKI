FROM node:20-alpine AS assets
WORKDIR /app

# Pastikan rollup pakai JS, bukan binary native
ENV ROLLUP_USE_NODE_JS=1 \
    npm_config_fund=false \
    npm_config_audit=false \
    npm_config_optional=true

COPY package*.json ./

# install deps dengan verbose biar ketahuan kalau ada error
RUN npm install --verbose --no-fund --no-audit --include=optional || npm install --verbose

COPY . .

# hapus rollup binary native (musl) dan paksa install ulang versi JS
RUN rm -rf node_modules/@rollup && \
    npm install rollup vite --no-optional --force --verbose && \
    echo "=== Running VITE BUILD in JS mode ===" && \
    node -e "console.log('Rollup version:', require('rollup').version)" && \
    node ./node_modules/vite/bin/vite.js build --debug || \
    (echo '❌ BUILD FAILED - dumping rollup native.js:' && cat /app/node_modules/rollup/dist/native.js || true)
