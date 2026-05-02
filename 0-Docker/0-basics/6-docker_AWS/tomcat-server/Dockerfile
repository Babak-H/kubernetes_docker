FROM centos:7

RUN yum install -y java-1.8.0-openjdk-devel \
    && yum clean all \
    && rm -rf /var/cache/yum

RUN mkdir -p /opt/tomcat

# Any command after this runs relative to this path inside the container.
WORKDIR /opt/tomcat

# ADD can download a remote file into the image.
# The Apache archive URL is stable for this older Tomcat version.
ADD https://archive.apache.org/dist/tomcat/tomcat-9/v9.0.54/bin/apache-tomcat-9.0.54.tar.gz /opt/tomcat/

RUN tar xzf apache-tomcat-9.0.54.tar.gz \
    && mv apache-tomcat-9.0.54/* /opt/tomcat \
    && rm -rf apache-tomcat-9.0.54 apache-tomcat-9.0.54.tar.gz

# Document that Tomcat listens on port 8080.
EXPOSE 8080

CMD ["/opt/tomcat/bin/catalina.sh", "run"]

# ADD vs COPY:
# ADD can download URLs and automatically extract local compressed archives.
# COPY is preferred when you only need to copy local files into the image.
