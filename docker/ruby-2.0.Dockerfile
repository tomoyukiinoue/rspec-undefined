# Ruby 2.0.0-p648 (from source) on debian:stretch-slim
# - stretch ships OpenSSL 1.0.2 which Ruby 2.0 requires (Ruby 2.0 does not build against OpenSSL 1.1+).
# - stretch is EOL; we switch apt to archive.debian.org to install build deps.
FROM debian:stretch-slim

RUN set -eux; \
    printf 'deb http://archive.debian.org/debian stretch main\ndeb http://archive.debian.org/debian-security stretch/updates main\n' > /etc/apt/sources.list; \
    printf 'Acquire::Check-Valid-Until "false";\n' > /etc/apt/apt.conf.d/99no-check-valid-until; \
    apt-get update; \
    apt-get install -y --no-install-recommends --allow-downgrades \
      build-essential \
      ca-certificates \
      curl \
      libssl1.0-dev \
      libreadline-dev \
      zlib1g-dev \
      libyaml-dev \
      libffi-dev \
      libgdbm-dev \
      libncurses5-dev \
      bison; \
    rm -rf /var/lib/apt/lists/*

ENV RUBY_VERSION=2.0.0-p648
RUN set -eux; \
    curl -fL "https://cache.ruby-lang.org/pub/ruby/2.0/ruby-${RUBY_VERSION}.tar.gz" -o /tmp/ruby.tar.gz; \
    mkdir -p /tmp/ruby; \
    tar -xzf /tmp/ruby.tar.gz -C /tmp/ruby --strip-components=1; \
    cd /tmp/ruby; \
    # Ruby 2.0's config.guess predates aarch64; update it from upstream for multi-arch safety.
    curl -fL "https://git.savannah.gnu.org/cgit/config.git/plain/config.guess" -o tool/config.guess; \
    curl -fL "https://git.savannah.gnu.org/cgit/config.git/plain/config.sub" -o tool/config.sub; \
    chmod +x tool/config.guess tool/config.sub; \
    # stretch's OpenSSL 1.0.2 has SSLv3 disabled, but ossl_ssl.c references SSLv3_method.
    # Wrap the three SSLv3 entries with #if 0 .. #endif to skip them.
    sed -i 's|^    OSSL_SSL_METHOD_ENTRY(SSLv3),$|#if 0\n    OSSL_SSL_METHOD_ENTRY(SSLv3),|' ext/openssl/ossl_ssl.c; \
    sed -i 's|^    OSSL_SSL_METHOD_ENTRY(SSLv3_client),$|    OSSL_SSL_METHOD_ENTRY(SSLv3_client),\n#endif|' ext/openssl/ossl_ssl.c; \
    ./configure --disable-install-doc --enable-shared; \
    make -j"$(nproc)"; \
    make install; \
    rm -rf /tmp/ruby /tmp/ruby.tar.gz

# git is needed because rspec-undefined.gemspec uses `git ls-files`
RUN apt-get update && apt-get install -y --no-install-recommends git && rm -rf /var/lib/apt/lists/*

# Bundler 1.x is the last series supporting Ruby 2.0
RUN gem install bundler -v "1.17.3" --no-document

ENV LANG=C.UTF-8 LC_ALL=C.UTF-8
WORKDIR /gem
CMD ["ruby", "-v"]
