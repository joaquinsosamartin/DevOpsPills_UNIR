# Multi-stage, non-root, small runtime
FROM node:22-alpine AS deps
WORKDIR /app
COPY package.json package-lock.json* ./
RUN npm ci --omit=dev || npm ci

FROM node:22-alpine AS runtime
WORKDIR /app
ENV NODE_ENV=production
COPY --from=deps /app/node_modules ./node_modules
COPY server.js ./server.js
# Security: create non-root user
RUN addgroup -S app && adduser -S app -G app
USER app
EXPOSE 8080
ENV PORT=8080
CMD ["node", "server.js"]
