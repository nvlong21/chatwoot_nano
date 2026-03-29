# Stage 1: Build Vue frontend
FROM node:20-alpine AS frontend-builder
WORKDIR /app/frontend
COPY frontend/package.json frontend/pnpm-lock.yaml* ./
RUN npm install -g pnpm && pnpm install
COPY frontend/ .
RUN pnpm build

# Stage 2: Build Go binary
FROM golang:1.21-alpine AS go-builder
WORKDIR /app
COPY go.mod ./
COPY . .
RUN go mod tidy && go mod download
RUN CGO_ENABLED=0 GOOS=linux go build -ldflags="-s -w" -o super_admin_server . && \
    CGO_ENABLED=0 GOOS=linux go build -ldflags="-s -w" -o create_super_admin ./cmd/create_super_admin

# Stage 3: Final minimal image
FROM alpine:3.19
RUN apk add --no-cache ca-certificates tzdata
WORKDIR /app
COPY --from=go-builder /app/super_admin_server .
COPY --from=go-builder /app/create_super_admin .
COPY --from=frontend-builder /app/frontend/dist ./frontend/dist
EXPOSE 4000
CMD ["./super_admin_server"]
