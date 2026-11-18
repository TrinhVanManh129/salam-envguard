# Build envguard with the official Salam image, then run it against the
# directory mounted at /work:
#
#   docker build -t envguard .
#   docker run --rm -v "$PWD:/work" envguard
#
# The Salam image runs as an unprivileged user, so the compile step happens
# as root in a separate stage and only the finished binary is copied over.
FROM basemax/salam:latest AS build
USER root
WORKDIR /src
COPY main.salam ./
COPY src ./src
RUN mkdir -p /out && salam build main.salam --output=/out/envguard

FROM basemax/salam:latest
COPY --from=build /out/envguard /usr/local/bin/envguard
WORKDIR /work
ENTRYPOINT ["/usr/local/bin/envguard"]
