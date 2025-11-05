FROM alpine:3.22

# install packages required to run the tests
RUN apk add --no-cache jq coreutils bash binutils make npm
RUN apk add fpc --repository=http://dl-cdn.alpinelinux.org/alpine/edge/testing/

RUN npm install -g tap-parser

WORKDIR /opt/test-runner
COPY . .
ENTRYPOINT ["/opt/test-runner/bin/run.sh"]
