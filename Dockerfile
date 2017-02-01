FROM centos:latest
ARG COUCHDB_ADMIN_LOGIN=admin
ARG COUCHDB_ADMIN_PWD=admin
ARG UOC2_HOME=/opt/uoc2
ENV COUCHDB_ADMIN_LOGIN=${COUCHDB_ADMIN_LOGIN:-admin}  COUCHDB_ADMIN_PWD=${COUCHDB_ADMIN_PWD:-admin} UOC2_HOME=${UOC2_HOME:-/opt/uoc2}
EXPOSE 3000
RUN yum -y update && yum -y install sudo perl freetype fontconfig && \
 groupadd uoc && useradd uoc -m -g uoc && \
 rpm -ivh https://rpm.nodesource.com/pub_4.x/el/7/x86_64/nodejs-4.6.0-1nodesource.el7.centos.x86_64.rpm && \
 npm install -g npm@latest
RUN echo '%wheel ALL=(ALL) NOPASSWD: ALL' >> /etc/sudoers && \
 sed -i 's/.*requiretty$/Defaults !requiretty/' /etc/sudoers && \
 usermod -a -G wheel uoc
COPY UOCV2.3.0-MR.tar  /tmp
COPY uoc-addon-ossa-1.1.4-MP.x86_64.rpm /tmp
WORKDIR /tmp
RUN tar xvf /tmp/UOCV2.3.0-MR.tar
WORKDIR /tmp/uoc2_kit
RUN ./install.sh -s  && cat /var/opt/uoc2/.environment.sh >> /home/uoc/.bash_profile && \
rpm -ivh /tmp/uoc-addon-ossa-1.1.4-MP.x86_64.rpm  && su - uoc && source /home/uoc/.bash_profile
COPY view_designer_permissions.json /opt/uoc2/data/permissions
COPY view_designer_roles.json /opt/uoc2/data/roles
COPY view_designer_users.json /opt/uoc2/data/users
USER uoc
WORKDIR $UOC2_HOME
RUN sleep 30
RUN  sed -i -e  's/"host": "127.0.0.1"/"host": "couchdb"/g' /var/opt/uoc2/server/public/conf/config.json && \
 sed -i -e  "s/\"username\": \"user\"/\"username\": \"$COUCHDB_ADMIN_LOGIN\"/g" /var/opt/uoc2/server/public/conf/config.json && \
 sed -i -e  "s/\"password\": \"user\"/\"password\": \"$COUCHDB_ADMIN_PWD\"/g" /var/opt/uoc2/server/public/conf/config.json
RUN echo "#!/bin/bash" > $UOC2_HOME/launch.sh &&\
 echo "if [[ \$BUILD_COUCHDB == "TRUE" ]]; then source /home/uoc/.bash_profile;cd $UOC2_HOME;node install/database/dbinit.js $COUCHDB_ADMIN_LOGIN $COUCHDB_ADMIN_PWD; fi; \
$UOC2_HOME/bin/uoc2 start;bash" >> $UOC2_HOME/launch.sh  && \
 chmod u+x $UOC2_HOME/launch.sh
ENTRYPOINT ["./launch.sh"]
