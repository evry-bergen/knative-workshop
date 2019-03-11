FROM golang as builder

WORKDIR /go/src/app
COPY labs/4-guestbook/ .

RUN go get -d -v ./...
RUN go install -v ./...

FROM gcr.io/distroless/base

COPY --from=builder /go/bin/app /
COPY --from=builder /go/src/app/template.html /
EXPOSE 8080

CMD ["/app"]
