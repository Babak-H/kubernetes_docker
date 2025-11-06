FROM ubuntu:16.04

RUN apt-get update && apt-get install -y openssh-server
RUN mkdir /var/run/sshd
RUN echo 'root:Passw0rd' | chpasswd
RUN sed -i 's/PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config

# SSH login fix. Otherwise user is kicked off after login
# 's@...@...@g' using @ instead of /
# @ → is the delimiter (can also be /, but @ is used here to avoid escaping slashes)
# session\s*required\s*pam_loginuid.so => session optional pam_loginuid.so
# session    required    pam_loginuid.so  =>  session    optional    pam_loginuid.so
# This is often used in Docker containers or non-login environments because pam_loginuid.so can cause SSH sessions to fail when no login UID is available
RUN sed 's@session\s*required\s*pam_loginuid.so@session optional pam_loginuid.so@g' -i /etc/pam.d/sshd

# can also be written as ENV NOTVISIBLE="in users profile"
ENV NOTVISIBLE "in users profile"
RUN echo "export VISIBLE=now" >> /etc/profile

# EXPOSE does not actually open or publish a port to the outside world — it’s purely informational metadata inside the image.
EXPOSE 22

CMD ["/usr/sbin/sshd", "-D"]