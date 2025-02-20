# Dockerfile for Java application
FROM eclipse-temurin:17-jdk-jammy as builder
ARG APP_NAME="My_APP"
COPY ./target/*.jar ${APP_NAME}.jar
RUN java -Djarmode=layertools -jar ${APP_NAME}.jar extract


FROM eclipse-temurin:17-jdk-jammy

LABEL maintainer="MAINTAINER_NAME"
LABEL project-name.label="PROJECT_NAME"
LABEL app-name.label="APPLICATION_NAME"

ARG USER=spring
ARG HOME=/home/$USER
RUN addgroup --gid 3000 --system "$USER" \
 && adduser  --uid 1000 --system --ingroup "$USER" --home "$HOME" "$USER"
RUN chown -R $USER:$USER $HOME/
USER $USER
WORKDIR $HOME

COPY --chown=$USER:$USER --from=builder dependencies/ ./
COPY --chown=$USER:$USER --from=builder snapshot-dependencies/ ./
COPY --chown=$USER:$USER --from=builder application/ ./
COPY --chown=$USER:$USER --from=builder spring-boot-loader/ ./

RUN chmod 755 $HOME/BOOT-INF/lib/*.jar

ENTRYPOINT ["java", "org.springframework.boot.loader.JarLauncher"]