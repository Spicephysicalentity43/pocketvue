# Stage 1: Build Frontend
FROM node:20-alpine AS frontend-builder

# Install pnpm
RUN corepack enable pnpm

WORKDIR /app

# Copy package files for dependency installation
COPY package.json pnpm-lock.yaml pnpm-workspace.yaml ./
COPY frontend/package.json ./frontend/

# Install dependencies
RUN pnpm install --frozen-lockfile

# Copy frontend source
COPY frontend ./frontend

# Create backend/ui/dist directory (where Nuxt outputs)
RUN mkdir -p backend/ui/dist

# Build frontend (outputs to backend/ui/dist via nuxt.config.ts)
RUN cd frontend && pnpm run generate

# Stage 2: Build Backend
FROM golang:1.24-alpine AS backend-builder

WORKDIR /app

# Copy backend source
COPY backend ./backend

# Copy generated frontend from previous stage
COPY --from=frontend-builder /app/backend/ui/dist ./backend/ui/dist

# Build the Go binary
RUN cd backend && \
    CGO_ENABLED=0 go build -ldflags="-s -w" -o pocketvue .

# Stage 3: Runtime
FROM alpine:latest

# Install ca-certificates for HTTPS and timezone data
RUN apk --no-cache add ca-certificates tzdata

WORKDIR /app

# Copy the binary from builder
COPY --from=backend-builder /app/backend/pocketvue /app/pocketvue

# Create pb_data directory for persistence
RUN mkdir -p /app/pb_data

# Expose PocketBase default port
EXPOSE 8090

# Volume for persistent data
VOLUME ["/app/pb_data"]

# Run the application
# Note: In production, set FRONTEND_URL environment variable
CMD ["/app/pocketvue", "serve", "--http=0.0.0.0:8090"]
