FROM alpine as builder

# Build environment
ARG DANTE_SOURCE=https://www.inet.no/dante/files/dante-1.4.2.tar.gz
ARG BUILD_DEPS="file gawk make gcc g++ linux-pam-dev miniupnpc-dev libgss-dev krb5-dev cyrus-sasl-dev"

WORKDIR /root

# Get source
RUN apk add --update curl                 \
  && curl -o dante.tar.gz ${DANTE_SOURCE} \
  && tar -xf dante.tar.gz                 \
  && rm dante.tar.gz                      \
  && mv dante* dante

WORKDIR /root/dante

# Install build deps
RUN apk add --update ${BUILD_DEPS}

# Configure installition
RUN env CC=gcc                                \
      CFLAGS='-Os -fomit-frame-pointer'       \
      LDFLAGS='-Wl,--as-needed'               \
      CPPFLAGS='-Os -fomit-frame-pointer'     \
      CXXFLAGS='-Os -fomit-frame-pointer'     \
      ac_cv_func_sched_setscheduler="no"      \
  ./configure                                 \
      --build=x86_64-alpine-linux             \
      --host=x86_64-alpine-linux              \
      --prefix=/usr                           \
      --datadir=/usr/share/dante              \
      --sysconfdir=/etc/dante                 \
      --with-sockd-conf=/etc/dante/sockd.conf \
      --with-socks-conf=/etc/dante/dante.conf \
      --libexecdir=/usr/lib/dante             \
      --localstatedir=/var                    \
      --disable-client                        \
      --enable-release                        \
      --enable-shared

# Run build and install
RUN make -j4 install

# Collect buildment
COPY ./sockd.conf /etc/dante/
RUN mkdir -p /newroot/etc/dante \
      /newroot/usr/sbin         \
  && cp /usr/sbin/sockd         \
      /newroot/usr/sbin/        \
  && cp /etc/dante/*            \
      /newroot/etc/dante/

# New empty stage
FROM alpine

COPY --from=builder /newroot /

RUN apk add --update         \
      linux-pam              \
      miniupnpc              \
      libgss                 \
      krb5                   \
      cyrus-sasl             \
      shadow                 \
  && sed -i "s/CREATE_MAIL_SPOOL=yes/CREATE_MAIL_SPOOL=no/g" /etc/default/useradd \
  && rm -rf /var/cache/apk/*

CMD ["sockd"]
