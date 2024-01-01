FROM ubuntu:latest

ENV DEBIAN_FRONTEND noninteractive

RUN set -e \
    && apt -y update -qq \
    && apt -y install --no-install-recommends software-properties-common dirmngr wget \
    && wget -qO- https://cloud.r-project.org/bin/linux/ubuntu/marutter_pubkey.asc | tee -a /etc/apt/trusted.gpg.d/cran_ubuntu_key.asc \
    && add-apt-repository "deb https://cloud.r-project.org/bin/linux/ubuntu $(lsb_release -cs)-cran40/"

RUN set -e \
      && apt-get -y update \
      && apt-get -y dist-upgrade \
      && apt-get -y install --no-install-recommends --no-install-suggests \
        apt-transport-https apt-utils ca-certificates cmake curl g++ gcc \
        gfortran git make libblas-dev libcurl4-gnutls-dev libfontconfig1-dev \
        libfreetype6-dev libfribidi-dev libgit2-dev libharfbuzz-dev \
        libiodbc2-dev libjpeg-dev liblapack-dev libmariadb-dev libpng-dev \
        libpq-dev libsqlite3-dev libssh-dev libssl-dev libtiff5-dev \
        libxml2-dev locales pandoc pkg-config gpg-agent sudo \
        gdebi-core libapparmor1 libclang-dev lsb-release psmisc \
      && apt-get -y autoremove \
      && apt-get clean \
      && rm -rf /var/lib/apt/lists/*

RUN set -e \
    && add-apt-repository ppa:marutter/rrutter4.0 \
    && add-apt-repository ppa:c2d4u.team/c2d4u4.0+

RUN set -e \
      && locale-gen en_US.UTF-8 \
      && update-locale

ENV CRAN_URL https://cloud.r-project.org/

RUN set -e \
      && apt-get -y update \
      && apt-get -y install --no-install-recommends --no-install-suggests \
        r-base \
      && apt-get -y autoremove \
      && apt-get clean \
      && rm -rf /var/lib/apt/lists/*


RUN set -e \
    && R -e "install.packages(c('tidyverse', 'rmarkdown', 'ggpubr', 'foreach', 'doParallel', 'dbplyr'))" 

RUN set -eo pipefail \
      && curl -SL https://s3.amazonaws.com/rstudio-server/current.ver \
        | sed -e 's/+/-/; s/\.[a-z]\+[0-9]\+$//;' \
        | xargs -I{} curl -SL -o /tmp/rstudio-server.deb \
          https://download2.rstudio.org/server/focal/amd64/rstudio-server-{}-amd64.deb \
      && gdebi --non-interactive /tmp/rstudio-server.deb \
      && rm -rf /tmp/rstudio-server.deb

RUN set -e \
      && ln -s /dev/stdout /var/log/syslog \
      && echo "r-cran-repos=${CRAN_URL}" >> /etc/rstudio/rsession.conf \
      && useradd -m -d /home/rstudio -g rstudio-server rstudio \
      && echo rstudio:rstudio | chpasswd

# Add Michael Rutter's c2d4u4.0 PPA (and rrutter4.0 for CRAN builds too)
RUN set -e \
    && apt -y update \
    && apt -y install --no-install-recommends --no-install-suggests \
        r-cran-rstan r-cran-tidyverse \
    && apt-get -y autoremove \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*


RUN set -e \
    && R -e "install.packages('rstan', repos = c('https://mc-stan.org/r-packages/', getOption('repos')))" \
    && R -e "options(mc.cores = parallel::detectCores())"

RUN set -e \
    && R -e "install.packages(c('coda','mvtnorm','devtools','loo','dagitty','shape'))" \
    && R -e "devtools::install_github('rmcelreath/rethinking')"

EXPOSE 8787

ENTRYPOINT ["/usr/lib/rstudio-server/bin/rserver"]
CMD ["--server-daemonize=0", "--server-app-armor-enabled=0"]
