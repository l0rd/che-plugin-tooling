FROM centos

# Add yarn repo
RUN curl -sL https://dl.yarnpkg.com/rpm/yarn.repo | tee /etc/yum.repos.d/yarn.repo
# Install nodejs/npm/yarn
RUN curl --silent --location https://rpm.nodesource.com/setup_8.x | bash -

RUN yum -y update && yum -y install skopeo nodejs yarn patch git sudo

RUN curl -sSL -o /usr/local/bin/umoci https://github.com/openSUSE/umoci/releases/download/v0.4.2/umoci.amd64 && chmod +x /usr/local/bin/umoci

ENV NODEJS_VERSION=6 \
    NPM_RUN=start \
    NPM_CONFIG_PREFIX=$HOME/.npm-global

COPY ["docker_build.sh","/usr/local/bin/docker_build.sh"]

WORKDIR /projects

# The following instructions set the right
# permissions and scripts to allow the container
# to be run by an arbitrary user (i.e. a user
# that doesn't already exist in /etc/passwd)
# Adding user to the 'root' is a workaround for https://issues.jboss.org/browse/CDK-305
RUN echo "%wheel ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers && \
    useradd -u 1000 -G users,wheel,root -d /home/user --shell /bin/bash -m user && \
    usermod -p "*" user

USER user

ENV HOME /home/user
RUN for f in "/home/user" "/etc/passwd" "/etc/group" "/projects"; do\
           sudo chgrp -R 0 ${f} && \
           sudo chmod -R g+rwX ${f}; \
        done && \
        # Generate passwd.template \
        cat /etc/passwd | \
        sed s#user:x.*#user:x:\${USER_ID}:\${GROUP_ID}::\${HOME}:/bin/bash#g \
        > /home/user/passwd.template && \
        # Generate group.template \
        cat /etc/group | \
        sed s#root:x:0:#root:x:0:0,\${USER_ID}:#g \
        > /home/user/group.template

COPY ["entrypoint.sh","/home/user/entrypoint.sh"]
ENTRYPOINT ["/home/user/entrypoint.sh"]
CMD tail -f /dev/null