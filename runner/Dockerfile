FROM alpine:3.20

RUN apk --no-cache add ca-certificates go nodejs python3 openjdk21 && adduser -D -u 1000 runner

WORKDIR /runner

COPY runner.py /runner/runner.py

EXPOSE 8090

USER runner

CMD ["python3", "/runner/runner.py"]
