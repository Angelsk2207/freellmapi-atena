# 🪶 FreeLLMAPI Kibitz — Single-stage, ainda mais leve
FROM node:20-alpine

WORKDIR /app

# Build tools para better-sqlite3
RUN apk add --no-cache python3 make g++ git

# Clone o código fonte original
RUN git clone https://github.com/tashfeenahmed/freellmapi.git . \
    && git checkout v0.5.0

# Instala APENAS produção + dev necessários pro build
RUN npm ci --ignore-scripts && npm rebuild better-sqlite3

# Compila o servidor
RUN npm run build:server

# Remove o que não precisa em runtime
RUN rm -rf client src test node_modules/.cache

# Remove devDependencies
RUN npm prune --omit=dev

ENV NODE_ENV=production
ENV PORT=3000
ENV HOST=0.0.0.0

EXPOSE 3000
WORKDIR /app/server
CMD ["node", "dist/index.js"]
