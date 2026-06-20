# syntax=docker/dockerfile:1.7

FROM golang:1.26-bookworm AS builder

WORKDIR /src

COPY go.mod go.sum ./

RUN --mount=type=cache,target=/go/pkg/mod \
    --mount=type=cache,target=/root/.cache/go-build \
    go mod download

COPY server.go ./

RUN --mount=type=cache,target=/go/pkg/mod \
    --mount=type=cache,target=/root/.cache/go-build \
    CGO_ENABLED=0 GOOS=linux GOARCH=amd64 \
    mkdir -p /out && \
    go build -trimpath -ldflags="-s -w -checklinkname=0" -o /out/wdtt-server ./server.go


FROM debian:bookworm-slim

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        bash \
        ca-certificates \
        iproute2 \
        iptables \
        nftables \
        procps \
    && rm -rf /var/lib/apt/lists/*

COPY --from=builder /out/wdtt-server /usr/local/bin/wdtt-server

RUN chmod +x /usr/local/bin/wdtt-server \
    && mkdir -p /etc/wdtt

VOLUME ["/etc/wdtt"]

EXPOSE 56000/udp 56001/udp

ENTRYPOINT ["/usr/local/bin/wdtt-server"]
CMD ["-listen", "0.0.0.0:56000", "-wg-port", "56001", "-config-dir", "/etc/wdtt"]
