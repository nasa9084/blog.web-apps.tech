FROM golang:1.22 AS build

WORKDIR /go/src/github.com/nasa9084/blog.web-apps.tech/getogp
COPY . .
RUN CGO_ENABLED=0 go build -o /getogp main.go


FROM alpine:3.19
COPY --from=build /getogp /getogp
ENTRYPOINT [ "/getogp" ]
