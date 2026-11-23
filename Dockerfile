ARG BASE_IMAGE=keking/kkfileview-base:5.0.0
FROM ${BASE_IMAGE}
ADD server/target/kkFileView-*.tar.gz /opt/
ENV KKFILEVIEW_BIN_FOLDER=/opt/kkFileView-5.0.3/bin
ENTRYPOINT ["java","-Dfile.encoding=UTF-8","-Dspring.config.location=/opt/kkFileView-5.0.3/config/application.properties","-jar","/opt/kkFileView-5.0.3/bin/kkFileView-5.0.3.jar"]
