FROM alpine:3.24.2@sha256:294b683cb724975bec92580e1e685676bd4b50bda910ddb8c51d4cabeaec77e6

# install packages required to run the tests
RUN apk add --no-cache jq coreutils bash binutils make npm
RUN apk add fpc --repository=http://dl-cdn.alpinelinux.org/alpine/edge/testing/

RUN npm install -g tap-parser

WORKDIR /opt/test-runner
COPY . .
ENTRYPOINT ["/opt/test-runner/bin/run.sh"]
