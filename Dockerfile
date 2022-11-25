FROM openjdk:11
ENV HOME /home/basex
WORKDIR /home/basex
RUN wget -O basex.zip https://files.basex.org/releases/10.3/BaseX103.zip
RUN unzip basex.zip -d .. && rm -f basex.zip
EXPOSE 1984 8080
CMD chmod -R 777 /home/basex; ./bin/basexhttp -h 8080