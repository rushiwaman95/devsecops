# ============================================
# Stage 1: Build Stage
FROM cgr.dev/chainguard/node:latest-dev AS builder

WORKDIR /app

COPY src/package*.json ./
RUN npm install --ignore-scripts \
    && npm cache clean --force

COPY src/ ./

# ============================================
# Stage 2: Production Stage (Distroless)
FROM cgr.dev/chainguard/node:latest

# Copy application files
WORKDIR /app
COPY --from=builder --chown=65532:65532 /app ./

# Environment variables
ENV NODE_ENV=production \
    PORT=3000

USER 65532

EXPOSE 3000

CMD ["index.js"]