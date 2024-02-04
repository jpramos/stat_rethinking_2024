FROM ubuntu:20.04

ENV DEBIAN_FRONTEND noninteractive

RUN set -e \
    && apt -y update -qq \
    && apt -y install --no-install-recommends software-properties-common dirmngr wget gpg-agent locales \
        curl gdebi libssl1.1 make curl psmisc libclang-dev sudo gcc g++ gfortran libblas-dev liblapack-dev \
        cmake pkg-config libcurl4-openssl-dev libz-dev libmagick++-dev \
	texlive-full \
    && wget -qO- https://cloud.r-project.org/bin/linux/ubuntu/marutter_pubkey.asc | tee -a /etc/apt/trusted.gpg.d/cran_ubuntu_key.asc \
    && add-apt-repository "deb https://cloud.r-project.org/bin/linux/ubuntu $(lsb_release -cs)-cran40/" \
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
        r-base r-base-dev \
      && apt-get -y autoremove \
      && apt-get clean \
      && rm -rf /var/lib/apt/lists/*

# Add Michael Rutter's c2d4u4.0 PPA (and rrutter4.0 for CRAN builds too)
RUN set -e \
    && apt -y update \
    && apt -y install --no-install-recommends --no-install-suggests \
        r-cran-rstan r-cran-tidyverse \
    && apt-get -y autoremove \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

RUN set -e \
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

RUN set -e \
    && R -e "install.packages('cmdstanr', repos = c('https://mc-stan.org/r-packages/', getOption('repos')))" \
    && R -e "cmdstanr::install_cmdstan()" \
    && R -e "options(mc.cores = parallel::detectCores())"

RUN set -e \
    && R -e "install.packages(c('coda','mvtnorm','devtools','loo','dagitty','shape', 'bayesplot', 'animation', 'ellipse', 'plotrix'))" \
    && R -e "devtools::install_github('rmcelreath/rethinking')"

EXPOSE 8787

COPY ./entrypoint.sh /home/rstudio/entrypoint.sh

# RUN mkdir /home/rstudio/homework && chown -R rstudio:rstudio-server /home/rstudio/homework
# RUN mkdir /home/rstudio/scripts && chown -R rstudio:rstudio-server /home/rstudio/scripts


ENTRYPOINT ["/bin/sh", "entrypoint.sh"]
# ENTRYPOINT ["/usr/lib/rstudio-server/bin/rserver"]
CMD ["/usr/lib/rstudio-server/bin/rserver", "--server-daemonize=0", "--server-app-armor-enabled=0"]
