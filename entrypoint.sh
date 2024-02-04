
chown -R rstudio:rstudio-server /home/rstudio/homework
chown -R rstudio:rstudio-server /home/rstudio/scripts
chown -R rstudio:rstudio-server /home/rstudio/book_scripts


exec "$@" #/usr/lib/rstudio-server/bin/rserver --server-daemonize=0 --server-app-armor-enabled=0
