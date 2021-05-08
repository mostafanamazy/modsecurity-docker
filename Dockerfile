FROM debian:buster-slim

RUN apt update \
    && apt install -qq --no-install-recommends --no-install-suggests -y \
        g++ flex bison curl doxygen libyajl-dev libgeoip-dev \
        libtool dh-autoreconf libcurl4-gnutls-dev libxml2 libpcre++-dev libxml2-dev \
        apt-utils autoconf automake build-essential git liblmdb-dev pkgconf zlib1g-dev \
        openssl libgd-dev ca-certificates libssl-dev libhiredis-dev libpcre3-dev libz-dev libgeoip1 libsodium23 \
    && apt clean \
    && rm -rf /var/lib/apt/lists/*

ENV MODSEC_VER='v3/master'
ENV NGINX_VER='1.19.1'
WORKDIR /opt
RUN git clone --depth 1 -b ${MODSEC_VER} --single-branch https://github.com/SpiderLabs/ModSecurity \
    && git clone --depth 1 https://github.com/SpiderLabs/ModSecurity-nginx.git \
    && git clone --depth 1 -b release-${NGINX_VER} https://github.com/nginx/nginx.git

WORKDIR /opt/ModSecurity
RUN git submodule init && git submodule update && sh build.sh \
    && ./configure \
    && make -j`nproc` \
    && make -j`nproc` install \
    && make clean 

ARG NGINX_EXTRA_FLAGS
WORKDIR /opt/nginx
COPY conf/nginx.conf ./conf/nginx.conf

RUN ./auto/configure --with-ld-opt='-lstdc++ -lm' --with-cc-opt='-O2 -g0' --with-threads --with-compat --with-http_ssl_module \
        --with-http_v2_module --with-http_gzip_static_module --with-http_stub_status_module \
        --with-file-aio --with-http_slice_module --add-dynamic-module=/opt/ModSecurity-nginx/ ${NGINX_EXTRA_FLAGS} \
    && make -j`nproc` modules \
    && make -j`nproc` \
    && make -j`nproc` install \
    && cp objs/ngx_http_modsecurity_module.so /usr/local/nginx/modules \
    && make clean 

WORKDIR /usr/local/nginx/modsec
COPY ./conf/main.conf ./
RUN cp /opt/ModSecurity/modsecurity.conf-recommended modsecurity.conf \
    && sed -i 's/SecRuleEngine DetectionOnly/SecRuleEngine On/g' modsecurity.conf \
    && cp /opt/ModSecurity/unicode.mapping .

RUN /usr/local/nginx/sbin/nginx -t

ENTRYPOINT ["/usr/local/nginx/sbin/nginx", "-g", "daemon off;"]
