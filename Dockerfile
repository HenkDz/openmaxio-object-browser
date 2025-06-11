
# Build stage for frontend
FROM node:18-alpine as frontend-builder
WORKDIR /app/web-app
COPY web-app/package.json web-app/yarn.lock ./
RUN corepack enable && yarn install --frozen-lockfile
COPY web-app/ ./
RUN yarn build

# Build stage for backend
FROM golang:1.21-alpine as backend-builder
WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download
COPY . .
COPY --from=frontend-builder /app/web-app/build ./web-app/build
RUN CGO_ENABLED=0 GOOS=linux go build -trimpath --tags=kqueue --ldflags "-s -w" -o console ./cmd/console

# Final stage
FROM alpine:latest
RUN apk --no-cache add ca-certificates
WORKDIR /root/
COPY --from=backend-builder /app/console .
EXPOSE 9090
CMD ["./console", "server"]