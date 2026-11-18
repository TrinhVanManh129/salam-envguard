# Build envguard with the official Salam image, then run it against the
# directory mounted at /work:
#
#   docker build -t envguard .
#   docker run --rm -v "$PWD:/work" envguard
FROM basemax/salam:latest

WORKDIR /src
COPY main.salam ./
COPY src ./src
RUN mkdir -p /out && salam build main.salam --output=/out/envguard

WORKDIR /work
ENTRYPOINT ["/out/envguard"]
