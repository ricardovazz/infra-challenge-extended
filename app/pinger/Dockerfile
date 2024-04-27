FROM golang:alpine

WORKDIR /app

COPY . .

RUN CGO_ENABLED=0 GOARCH=amd64 GOOS=linux go build -a --installsuffix cgo --ldflags="-s -w" -o /pinger

ENTRYPOINT [ "/pinger" ]