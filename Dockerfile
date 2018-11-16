FROM centos:7.0.1406
MAINTAINER MariaLikesFish <chrisredphild@foxmail.com>

RUN groupadd -r www-data && useradd -r --create-home -g www-data www-data
ENV HTTPD_PREFIX /usr/local/apache2
ENV PATH $HTTPD_PREFIX/bin:$PATH
RUN mkdir -p "$HTTPD_PREFIX" \
    && chown www-data:www-data "$HTTPD_PREFIX"
WORKDIR $HTTPD_PREFIX

# install httpd runtime dependencies
RUN yum -y remove fakesystemd \
    && yum -y update \
    && yum -y install \
        wget \
	bzip2 \
	make \
	gcc \
	gcc-c++ \
	perl \
	libxml2-devel \
	libpng \
	libpng-devel \

# install apr-1.4.8.
    && wget -O apr.tar.bz2 https://archive.apache.org/dist/apr/apr-1.4.8.tar.bz2 \
    && mkdir apr \
    && tar -xf apr.tar.bz2 -C apr --strip-components=1 \
    && cd apr \
    && ./configure --prefix=/usr/local/apr \
    && make && make install \
    && cd ../ \

# install apr-util-1.5.2.
    && wget -O apr-util.tar.bz2 https://archive.apache.org/dist/apr/apr-util-1.5.2.tar.bz2 \
    && mkdir apr-util \
    && tar -xf apr-util.tar.bz2 -C apr-util --strip-components=1 \
    && cd apr-util \
    && ./configure --prefix=/usr/local/apr-util --with-apr=/usr/local/apr \
    && make && make install \
    && cd ../ \

# install pcre-8.32.
    && wget -O pcre.tar.bz2 https://ftp.pcre.org/pub/pcre/pcre-8.32.tar.bz2 \
    && mkdir pcre \
    && tar -xf pcre.tar.bz2 -C pcre --strip-components=1 \
    && cd pcre \
    && ./configure --prefix=/usr/local/pcre \
    && make && make install \
    && cd ../ \

# install httpd-2.4.6.
    && wget -O httpd.tar.bz2 https://archive.apache.org/dist/httpd/httpd-2.4.6.tar.bz2 \
    && mkdir httpd \
    && tar -xf httpd.tar.bz2 -C httpd --strip-components=1 \
    && cd httpd \
    && ./configure --prefix=/usr/local/apache2 --sysconfdir=/etc/httpd --enable-so --enable-rewrite --with-apr=/usr/local/apr --with-apr-util=/usr/local/apr-util --with-pcre=/usr/local/pcre \
    && make && make install \
    && cd ../ \

# install php-5.6.36
    && wget -O php.tar.bz2 http://hk1.php.net/get/php-5.6.36.tar.bz2/from/this/mirror \
    && mkdir php \
    && tar -xf php.tar.bz2 -C php --strip-components=1 \
    && cd php \
    && mkdir -p /replace/with/path/to/perl/ \
    && ln -s /usr/bin/perl /replace/with/path/to/perl/interpreter \
    && ./configure --with-apxs2=/usr/local/apache2/bin/apxs --with-mysqli --with-gd --with-pear \
    && make && make install \
    && cd ../ \

# configure auto-start.
    && echo /usr/local/apache2/bin/apachectl start >> /etc/rc.d/rc.local \

# auto clean up.
    && rm -rf apr.tar.bz2 apr-util.tar.bz2 pcre.tar.bz2 httpd.tar.bz2 php.tar.bz2 \
    && rm -rf apr apr-util pcre httpd php \
    && yum -y remove wget bzip2 make gcc gcc-c++ # perl libxml2-devel libpng libpng-devel \
    && yum clean all \
    && rm -rf /var/cache/yum \

# smoke test.
    && /usr/local/apache2/bin/httpd -v \
    && php --version;

EXPOSE 80 443
VOLUME ["/usr/local/apache2/htdocs", "/etc/httpd"]

USER www-data:www-data
CMD ["/usr/local/apache2/apachectl", "start"]