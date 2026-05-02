# Build stage: extract the Spring Boot jar into layers for better Docker caching.
FROM eclipse-temurin:17-jdk-jammy AS builder

ARG APP_NAME=transporter-download

WORKDIR /build

# Copy the packaged application jar produced by the build pipeline.
COPY ./target/*.jar ${APP_NAME}.jar

# Extract Spring Boot layers: dependencies, snapshot-dependencies, loader, and application.
RUN set -eux; \
    java -Djarmode=layertools -jar ${APP_NAME}.jar extract


# Runtime stage: use a smaller JRE image because the application does not compile code here.
FROM eclipse-temurin:17-jre-jammy

LABEL maintainer="Babak-H" \
      project-name.label="RIM" \
      app-name.label="Transporter Download"

ARG USER=spring
ARG HOME=/home/${USER}
ARG VOLUME_PLUGIN_DIR=/usr/libexec/kubernetes/kubelet-plugins/volume/exec

# Install only runtime OS tools required for SMB/CIFS access and plugin setup.
RUN set -eux; \
    apt-get update; \
    apt-get install -y --no-install-recommends \
        ca-certificates \
        cifs-utils \
        curl \
        smbclient; \
    rm -rf /var/lib/apt/lists/*

# Create the non-root application user and required runtime directories.
RUN set -eux; \
    addgroup --gid 3000 --system "${USER}"; \
    adduser --uid 1000 --system --ingroup "${USER}" --home "${HOME}" "${USER}"; \
    mkdir -p "${HOME}/logs" "${VOLUME_PLUGIN_DIR}/fstab~cifs"; \
    chown -R "${USER}:${USER}" "${HOME}"

# Install the CIFS volume plugin into the Kubernetes kubelet plugin directory.
RUN set -eux; \
    curl -fsSL https://raw.githubusercontent.com/fstab/cifs/master/cifs \
        -o "${VOLUME_PLUGIN_DIR}/fstab~cifs/cifs"; \
    chmod 755 "${VOLUME_PLUGIN_DIR}/fstab~cifs/cifs"

USER ${USER}
WORKDIR ${HOME}

# Copy Spring Boot layers in cache-friendly order.
COPY --from=builder /build/dependencies/ ./
COPY --from=builder /build/snapshot-dependencies/ ./
COPY --from=builder /build/spring-boot-loader/ ./
COPY --from=builder /build/application/ ./

# with this env variable, Java automatically reads JAVA_TOOL_OPTIONS, and you can keep exec-form JSON without sh -c
ENV JAVA_TOOL_OPTIONS=""
ENTRYPOINT ["java", "org.springframework.boot.loader.JarLauncher"]
