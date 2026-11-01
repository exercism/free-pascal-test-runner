FROM alpine:3.24.3@sha256:be2656061b536c1883c4034790e21d0a09c5aaaf51968b89368a3c0371ea2c9a

# install packages required to run the tests
RUN apk add --no-cache jq coreutils bash binutils make npm
RUN apk add fpc --repository=http://dl-cdn.alpinelinux.org/alpine/edge/testing/

RUN npm install -g tap-parser

WORKDIR /opt/test-runner
COPY . .
ENTRYPOINT ["/opt/test-runner/bin/run.sh"]
