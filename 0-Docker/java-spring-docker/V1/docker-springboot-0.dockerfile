# Build a layered Spring Boot image from an already-built jar in target/.
# This Dockerfile expects the application jar to exist before the Docker build starts.

ARG JAVA_VERSION=17
ARG APP_NAME=my-app

# The builder stage extracts Spring Boot layers from the executable jar.
FROM eclipse-temurin:${JAVA_VERSION}-jdk-jammy AS builder

ARG APP_NAME

WORKDIR /workspace

# Copy the packaged Spring Boot jar.
COPY target/*.jar ${APP_NAME}.jar

# Spring Boot layertools splits the jar into cache-friendly image layers.
# -Djarmode — JVM System Property for JAR Mode, -D is the standard JVM flag for setting a system property. So -Djarmode=layertools sets the system property jarmode to the value layertools
# When a Spring Boot fat JAR is launched with jarmode=layertools, Spring Boot intercepts the startup before your application runs and instead activates a built-in tool that lets you inspect and extract the JAR's layers.
RUN java -Djarmode=layertools -jar ${APP_NAME}.jar extract


# Use a JRE runtime image because the final container only runs the app (smaller and more secure)
FROM eclipse-temurin:${JAVA_VERSION}-jre-jammy AS runtime

LABEL maintainer="MAINTAINER_NAME" \
      org.opencontainers.image.title="APPLICATION_NAME" \
      org.opencontainers.image.description="Spring Boot application" \
      org.opencontainers.image.version="1.0.0"

ARG APP_USER=spring
ARG APP_UID=1000
ARG APP_GID=3000

ENV APP_HOME=/app \
    JAVA_OPTS=""

# Run as a non-root user (this is a Must for production systems, Never run apps as root unless required)
# user, group = spring  but home address is /app
RUN addgroup --gid ${APP_GID} --system ${APP_USER} \
    && adduser --uid ${APP_UID} --system --ingroup ${APP_USER} --home ${APP_HOME} ${APP_USER}

# go to /app
WORKDIR ${APP_HOME}   

# Copy Spring Boot layers in dependency-to-application order for better build caching.
COPY --chown=${APP_USER}:${APP_USER} --from=builder /workspace/dependencies/ ./
COPY --chown=${APP_USER}:${APP_USER} --from=builder /workspace/spring-boot-loader/ ./
COPY --chown=${APP_USER}:${APP_USER} --from=builder /workspace/snapshot-dependencies/ ./
COPY --chown=${APP_USER}:${APP_USER} --from=builder /workspace/application/ ./

USER ${APP_USER}

# Spring Boot defaults to port 8080 unless the app config changes it.
EXPOSE 8080


# ENTRYPOINT : Defines the command that runs when the container starts. Using the ENTRYPOINT instruction (vs CMD) means this command is the main process — it's not easily overridden by arguments passed to docker run
# ["sh", "-c", "..."] : Runs the command through a shell (sh -c). This is the key design decision here — instead of using the exec form directly like ["java", "-jar", "/app/app.jar"]
# "java $JAVA_OPTS -jar /app/app.jar" : Tells the JVM to run the specified jar file. Spring Boot packages everything — dependencies, embedded Tomcat, your code — into this single executable jar, so this one flag is all you need to boot the whole application.

# the $JAVA_OPTS is not defined here but JAVA_OPTS can be supplied at runtime
# docker run -e JAVA_OPTS="-Xms256m -Xmx512m" image-name
ENTRYPOINT ["sh", "-c", "exec java $JAVA_OPTS org.springframework.boot.loader.JarLauncher"]
