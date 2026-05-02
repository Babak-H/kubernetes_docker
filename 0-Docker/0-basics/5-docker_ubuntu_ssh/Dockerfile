FROM ubuntu:16.04

RUN apt-get update \
    && apt-get install -y --no-install-recommends openssh-server \
    && rm -rf /var/lib/apt/lists/*

RUN mkdir /var/run/sshd

# chpasswd is a Linux command used to change user passwords in bulk (batch mode)
# This sets the root's password during the image build — a common pattern when you need a non-interactive way to set passwords without being prompted.
RUN echo 'root:Passw0rd' | chpasswd

RUN sed -i 's/PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config

# SSH login fix. Without this, the user can be disconnected after login.
# This replaces "session required pam_loginuid.so" with "session optional pam_loginuid.so".
# The @ character is used as the sed delimiter to avoid escaping slashes.
RUN sed 's@session\s*required\s*pam_loginuid.so@session optional pam_loginuid.so@g' -i /etc/pam.d/sshd

# Can also be written as ENV NOTVISIBLE="in users profile".
ENV NOTVISIBLE="in users profile"

RUN echo "export VISIBLE=now" >> /etc/profile

# EXPOSE documents the port. It does not publish the port on the host by itself.
EXPOSE 22

CMD ["/usr/sbin/sshd", "-D"]
