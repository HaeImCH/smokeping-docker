FROM debian:bullseye-slim

# Set mirror.twds.com.tw as package source
RUN echo "deb http://mirror.twds.com.tw/debian/ bullseye main contrib non-free" > /etc/apt/sources.list && \
    echo "deb http://mirror.twds.com.tw/debian/ bullseye-updates main contrib non-free" >> /etc/apt/sources.list && \
    echo "deb http://mirror.twds.com.tw/debian-security bullseye-security main contrib non-free" >> /etc/apt/sources.list

# Install prerequisites
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    gnupg2 \
    ca-certificates \
    lsb-release \
    debian-archive-keyring \
    build-essential \
    libwww-perl \
    libcgi-fast-perl \
    libio-socket-ssl-perl \
    rrdtool \
    librrd-dev \
    libpango1.0-dev \
    fping \
    procps \
    fcgiwrap \
    supervisor \
    wget \
    perl \
    make \
    gcc \
    libauthen-radius-perl \
    libnet-ldap-perl \
    libnet-dns-perl \
    libnet-snmp-perl \
    libdbi-perl \
    librrds-perl \
    tar \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Add official nginx repository
RUN curl https://nginx.org/keys/nginx_signing.key | gpg --dearmor \
    | tee /usr/share/keyrings/nginx-archive-keyring.gpg >/dev/null \
    && echo "deb [signed-by=/usr/share/keyrings/nginx-archive-keyring.gpg] \
    http://nginx.org/packages/debian `lsb_release -cs` nginx" \
    | tee /etc/apt/sources.list.d/nginx.list

# Install nginx from official repository
RUN apt-get update && apt-get install -y nginx \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Install Smokeping from source
WORKDIR /tmp
RUN wget https://oss.oetiker.ch/smokeping/pub/smokeping-2.9.0.tar.gz \
    && tar zxf smokeping-2.9.0.tar.gz \
    && cd smokeping-2.9.0 \
    && ./configure --prefix=/opt/smokeping \
    && make install \
    && ln -s /opt/smokeping/bin/smokeping /usr/bin/smokeping \
    && mkdir -p /opt/smokeping/var \
    && mkdir -p /opt/smokeping/htdocs \
    && cp -R /tmp/smokeping-2.9.0/htdocs/* /opt/smokeping/htdocs/ \
    && rm -rf /tmp/smokeping-2.9.0*

# Configure nginx
COPY nginx-config/smokeping.conf /etc/nginx/conf.d/
RUN rm -f /etc/nginx/conf.d/default.conf

# Configure smokeping
RUN mkdir -p /var/run/smokeping
RUN mkdir -p /opt/smokeping/var/cache
RUN mkdir -p /opt/smokeping/var/images
RUN mkdir -p /opt/smokeping/etc
COPY smokeping-config/config /opt/smokeping/etc/
COPY smokeping-config/targets /opt/smokeping/etc/
RUN chown -R www-data:www-data /opt/smokeping/var
RUN chown -R www-data:www-data /var/run/smokeping

# Copy supervisor config
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# Copy entrypoint script
COPY docker-entrypoint.sh /
RUN chmod +x /docker-entrypoint.sh

# Expose port 80
EXPOSE 80

ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]
