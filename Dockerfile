FROM jpazdyga/centos7-base
MAINTAINER Jakub Pazdyga <jakub.pazdyga@ft.com>

RUN rpmdb --rebuilddb && \ 
    rpmdb --initdb && \
    yum clean all && \
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

RUN mkdir /etc/ansible/
RUN echo '[local]\nlocalhost\n' > /etc/ansible/hosts
RUN mkdir /opt/ansible/
RUN git clone http://github.com/ansible/ansible.git /opt/ansible/ansible
WORKDIR /opt/ansible/ansible
RUN git submodule update --init
ENV PATH /opt/ansible/ansible/bin:/bin:/usr/bin:/sbin:/usr/sbin
ENV PYTHONPATH /opt/ansible/ansible/lib
ENV ANSIBLE_LIBRARY /opt/ansible/ansible/library
RUN useradd -d /home/ansible -G wheel -m -s /bin/bash ansible && \
    su ansible -c "ssh-keygen -t rsa -N '' -f ~/.ssh/id_rsa" && \
    echo "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC2t1lWVnWi2wjm8HIjBX+Oetps2nmgCp3jw/CwnXhBZCib35o2nyrZI9JkM5phoZb9XA0M9ZDyrx3bqwjgfrTiF+gFJNd3aeTUGuZUV6T7mALZ9dICy5XYbPRQR3BgLVAfDMMthbWaGiwfeVjxidcLJpDc6wXAj4YiT+80/B2s2TTJM6BIr8n8JoCNsFlheEu7wmAxNj0IpXlt72xTpGuh4LB8ZwiuZzrY5gOYpsfENioHTklHMXr2ucMxbP+mf5Qagtv2R7YrUNSWPRekNbEfYWiqVMTVWxKbRtEIQ7RnoJr2Talum6k5EIJYCrpWKf+2EgykTUyCNymzYaAPLDvT" > /home/ansible/.ssh/authorized_keys
    
RUN sed -i \
	-e 's/^PasswordAuthentication yes/PasswordAuthentication no/g' \
	-e 's/^#PermitRootLogin yes/PermitRootLogin no/g' \
	-e 's/^#UseDNS yes/UseDNS no/g' \
	/etc/ssh/sshd_config
RUN sed -i 's/^# %wheel\tALL=(ALL)\tALL/%wheel\tALL=(ALL)\tALL\tNOPASSWD:\tALL/g' /etc/sudoers
RUN ssh-keygen -A
COPY supervisord.conf /etc/supervisor.d/supervisord.conf
ENV container docker
ENV DATE_TIMEZONE UTC
VOLUME /var/log /etc
EXPOSE 22
USER root
CMD ["/usr/bin/supervisord", "-n", "-c/etc/supervisor.d/supervisord.conf"]
