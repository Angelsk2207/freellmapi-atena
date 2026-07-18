# 🏗️ FreeLLMAPI Nano — Construção enxuta para Back4app free
# Estratégia: compila só o servidor, sem frontend, em Alpine

# ── Stage 1: Build ──
FROM node:20-alpine AS builder

WORKDIR /build

# Build tools necessários para compilar better-sqlite3 nativo
RUN apk add --no-cache python3 make g++ git

# Clona o repositório original (tagged release estável)
RUN git clone https://github.com/tashfeenahmed/freellmapi.git . \
    && git checkout v0.5.0

# Instala TODAS as dependências (dev inclusas para build)
RUN npm ci

# Compila APENAS o servidor
RUN npm run build:server

# Remove devDependencies — não precisam em runtime
RUN npm prune --omit=dev

# Remove o frontend React inteiro — é só peso morto
RUN rm -rf client

# ── Stage 2: Runtime (minúscula) ──
FROM node:20-alpine

WORKDIR /app

# Copia só o essencial do stage de build
COPY --from=builder /build/package.json /build/package-lock.json ./
COPY --from=builder /build/node_modules ./node_modules
COPY --from=builder /build/shared ./shared
COPY --from=builder /build/server ./server

# Diretório de dados do SQLite
RUN mkdir -p /app/server/data

ENV NODE_ENV=production
ENV PORT=3000
ENV HOST=0.0.0.0

EXPOSE 3000

# Health check mais leve (wget em vez de curl)
HEALTHCHECK --interval=30s --timeout=10s --start-period=30s --retries=3 \
  CMD wget -qO- http://localhost:3000/health || exit 1

WORKDIR /app/server
CMD ["node", "dist/index.js"]