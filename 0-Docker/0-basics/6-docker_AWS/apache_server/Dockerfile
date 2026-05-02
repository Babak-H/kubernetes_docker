# Use Ubuntu as the base image.
FROM ubuntu:12.04

# Add metadata to the image.
# Labels are key-value pairs stored in the image metadata.
LABEL version="1.1.0" \
      app_name="Training registration application" \
      release_date="9-Sep-2018"

# Install Apache and remove apt package lists from the final image layer.
RUN apt-get update \
    && apt-get install -y apache2 \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Set Apache runtime environment variables.
ENV APACHE_RUN_USER=www-data
ENV APACHE_RUN_GROUP=www-data
ENV APACHE_LOG_DIR=/var/log/apache2

# Document that the container listens on port 80.
EXPOSE 80

# Copy the web page into Apache's document root.
COPY index.html /var/www/html

# Start Apache in the foreground.
CMD ["/usr/sbin/apache2", "-D", "FOREGROUND"]
