# START STAGE 1
FROM openjdk:8

USER root

ENV ANT_VERSION 1.10.6
ENV ANT_HOME /etc/ant-${ANT_VERSION}

WORKDIR /tmp

RUN wget http://www-us.apache.org/dist/ant/binaries/apache-ant-${ANT_VERSION}-bin.tar.gz \
    && mkdir ant-${ANT_VERSION} \
    && tar -zxvf apache-ant-${ANT_VERSION}-bin.tar.gz \
    && mv apache-ant-${ANT_VERSION} ${ANT_HOME} \
    && rm apache-ant-${ANT_VERSION}-bin.tar.gz \
    && rm -rf ant-${ANT_VERSION} \
    && rm -rf ${ANT_HOME}/manual \
    && unset ANT_VERSION

ENV PATH ${PATH}:${ANT_HOME}/bin

WORKDIR /home/build-app
COPY . .
RUN ant


# START STAGE 2
FROM existdb/existdb:release

COPY --from=0 /home/build-app/build/*.xar /exist/autodeploy

EXPOSE 8080 8443

CMD [ "java", "-jar", "start.jar", "jetty" ]
