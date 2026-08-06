FROM golang:1.23-alpine AS builder

ENV GOTOOLCHAIN=auto

WORKDIR /app

COPY go.mod go.sum ./
RUN go mod download

COPY . .
RUN CGO_ENABLED=0 GOOS=linux go build -o /server ./cmd/server

FROM alpine:3.20

RUN apk --no-cache add ca-certificates && adduser -D -u 1000 appuser

COPY --from=builder /server /server

EXPOSE 8080

USER appuser

CMD ["/server"]
