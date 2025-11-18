# stage is named builder
FROM golang:1.7.3 AS builder 
WORKDIR /go/src/github.com/alexellis/herf-counter/
RUN go get -d -v golang.org/x/net/html
COPY app.go .
# here we compile the application to get the exe file from it
RUN  CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -o app .

# start new stage
FROM alpine:latest
RUN apk --no-cache add ca-certificate
WORKDIR /root/
# copy compiled code from "builder" stage to new stage
COPY --from=builder /go/src/github.com/alexellis/herf-counter/app .
CMD ["./app"]

# first stage will NOT be copied to the final docker image, only what we copy from it to the last stage will be saved