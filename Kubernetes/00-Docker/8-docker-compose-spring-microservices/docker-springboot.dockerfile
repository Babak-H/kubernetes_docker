# docker layer 1
FROM eclipse-temurin:17-jdk-jammy as builder
ARG APP_NAME=transporter-download
COPY ./target/*.jar ${APP_NAME}.jar
RUN java -Djarmode=layertools -jar ${APP_NAME}.jar extract


# docker layer 2
FROM eclipse-temurin:17-jdk-jammy

LABEL maintainer="***"
LABEL project-name.label="RIM"
LABEL app-name.label="Transporter Download"

RUN apt-get update && apt-get install -y smbclient
RUN apt-get update && apt-get install -y cifs-utils

ARG USER=spring
ARG HOME=/home/$USER
RUN addgroup --gid 3000 --system "$USER" \
 && adduser  --uid 1000 --system --ingroup "$USER" --home "$HOME" "$USER"
RUN chown $USER:$USER $HOME

ARG VOLUME_PLUGIN_DIR="/usr/libexec/kubernetes/kubelet-plugins/volume/exec"
RUN mkdir -p "$VOLUME_PLUGIN_DIR/fstab~cifs"
RUN cd "$VOLUME_PLUGIN_DIR/fstab~cifs"
RUN curl -L -O https://raw.githubusercontent.com/fstab/cifs/master/cifs
RUN chmod 755 cifs

RUN mkdir $HOME/logs

USER $USER
WORKDIR $HOME

COPY --from=builder dependencies/ ./
COPY --from=builder snapshot-dependencies/ ./
COPY --from=builder application/ ./
COPY --from=builder spring-boot-loader/ ./

ENTRYPOINT ["java", "org.springframework.boot.loader.JarLauncher"]



