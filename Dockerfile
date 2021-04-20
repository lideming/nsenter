# Build static binaries
FROM archlinux:latest AS builder
ENV VERSION 2.33

RUN pacman -Syu curl gcc make --needed --noconfirm \
     && pacman -Scc --noconfirm
RUN mkdir /src

WORKDIR /src
RUN curl -L https://www.kernel.org/pub/linux/utils/util-linux/v$VERSION/util-linux-$VERSION.tar.gz \
     | tar -zxf- \
     && ln -s util-linux-$VERSION util-linux

WORKDIR /src/util-linux
RUN ./configure --without-ncurses \
     && make LDFLAGS=-all-static nsenter \
     && cp nsenter /

WORKDIR /src
ADD importenv.c /src/importenv.c
RUN make LDFLAGS=-static CFLAGS=-Wall importenv \
    && cp importenv /

# Build the final image
FROM alpine:latest

COPY --from=builder /importenv /nsenter /
ADD docker-enter installer /

CMD /installer
