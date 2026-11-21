FROM alpine:3.24.3@sha256:be2656061b536c1883c4034790e21d0a09c5aaaf51968b89368a3c0371ea2c9a

# install packages required to run the tests
RUN apk add --no-cache jq coreutils bash binutils make npm
RUN apk add fpc --repository=http://dl-cdn.alpinelinux.org/alpine/edge/testing/

RUN npm install -g tap-parser

WORKDIR /opt/test-runner
COPY . .

# Every exercise ships the same two helper units in lib/, and compiling them
# took about 1 s of each run. They are compiled here once, with the flags
# used by the exercises' Makefile. bin/run.sh copies the compiled units into
# the build folder when the solution's lib/ files match these exactly.
RUN mkdir -p precompiled && \
    cp assets/lib/*.pas precompiled/ && \
    cd precompiled && \
    fpc -l- -v0 -g -gl -Sa -Cr -Sehnw FPCUnitTestUtils.pas && \
    fpc -l- -v0 -g -gl -Sa -Cr -Sehnw FPCUnitTAPReporter.pas
ENTRYPOINT ["/opt/test-runner/bin/run.sh"]
