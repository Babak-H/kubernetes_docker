###### Name this build stage "builder".
FROM golang:1.7.3 AS builder

WORKDIR /go/src/github.com/alexellis/herf-counter/

RUN go get -d -v golang.org/x/net/html

COPY app.go .

# Compile the application into a Linux binary.
RUN CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -o app .

###### Start a smaller final image.
FROM alpine:latest

RUN apk add --no-cache ca-certificates

WORKDIR /root/

# Copy only the compiled binary from the builder stage.
COPY --from=builder /go/src/github.com/alexellis/herf-counter/app .

CMD ["./app"]

# The builder stage is not copied into the final image unless files are explicitly copied from it.
