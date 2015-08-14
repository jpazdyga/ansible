FROM jpazdyga/centos7-base
MAINTAINER Jakub Pazdyga <jakub.pazdyga@ft.com>

RUN rpmdb --rebuilddb && \ 
    rpmdb --initdb && \
    yum clean all && \
    yum -y update && \
    yum -y install openssh \
                   openssl \ 
                   openssl-libs \
                   psmisc \
                   openssh-server \
                   PyYAML \
                   python-jinja2 \
                   python-httplib2 \
                   python-keyczar \
                   python-paramiko \
                   python-setuptools \
                   git \
                   python-pip

RUN useradd -d /etc/ansible -G wheel -m -s /bin/bash ansible && \
    su ansible -c "ssh-keygen -t rsa -N '' -f ~/.ssh/id_rsa" && \
    ssh-keygen -A && \
    echo "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC2t1lWVnWi2wjm8HIjBX+Oetps2nmgCp3jw/CwnXhBZCib35o2nyrZI9JkM5phoZb9XA0M9ZDyrx3bqwjgfrTiF+gFJNd3aeTUGuZUV6T7mALZ9dICy5XYbPRQR3BgLVAfDMMthbWaGiwfeVjxidcLJpDc6wXAj4YiT+80/B2s2TTJM6BIr8n8JoCNsFlheEu7wmAxNj0IpXlt72xTpGuh4LB8ZwiuZzrY5gOYpsfENioHTklHMXr2ucMxbP+mf5Qagtv2R7YrUNSWPRekNbEfYWiqVMTVWxKbRtEIQ7RnoJr2Talum6k5EIJYCrpWKf+2EgykTUyCNymzYaAPLDvT" > /etc/ansible/.ssh/authorized_keys
RUN sed -i \
	-e 's/^PasswordAuthentication yes/PasswordAuthentication no/g' \
	-e 's/^#PermitRootLogin yes/PermitRootLogin yes/g' \
	-e 's/^#UseDNS yes/UseDNS no/g' \
	/etc/ssh/sshd_config
RUN sed -i \
        -e 's/^%wheel\tALL=(ALL)\tALL/#%wheel\tALL=(ALL)\tALL/g' \
        /etc/sudoers && \
        echo -e "%wheel\tALL=(ALL)\tNOPASSWD:\tALL" >> /etc/sudoers
RUN yum -y install ansible \
                   ansible-lint
RUN mkdir -p /etc/ansible/ && \
    mkdir -p /etc/ansible/tmp
RUN echo -e "[local]\nlocalhost\n" > /etc/ansible/hosts && \
    chown ansible:users /etc/ansible -R
COPY supervisord.conf /etc/supervisor.d/supervisord.conf
COPY add_new_coreos_host.sh /usr/local/bin/add_new_coreos_host.sh
RUN chmod 755 /usr/local/bin/add_new_coreos_host.sh
COPY coreos-bootstrap.yml /etc/ansible/coreos-bootstrap.yml
COPY coreos-fsdeploy.yml /etc/ansible/coreos-fsdeploy.yml
RUN su ansible -c "ansible-galaxy install defunctzombie.coreos-bootstrap"
ENV container docker
ENV DATE_TIMEZONE UTC
VOLUME /var/log /etc
EXPOSE 22
USER root
CMD ["/usr/bin/supervisord", "-n", "-c/etc/supervisor.d/supervisord.conf"]
