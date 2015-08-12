FROM jpazdyga/centos7-base
MAINTAINER Jakub Pazdyga <jakub.pazdyga@ft.com>

RUN rpmdb --rebuilddb && \ 
    rpmdb --initdb && \
    yum clean all && \
    yum -y install openssh openssh-server PyYAML python-jinja2 python-httplib2 python-keyczar python-paramiko python-setuptools git python-pip

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
    su ansible -c "ssh-keygen -t rsa -N "" -f ~/.ssh/id_rsa" && \
    echo "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC9+WGFm05i9tWfwolxsQgfOpl3NOL86IiNiticynQyw4tvd7JVEFsA1uJ3THDn3COb7zpuf4OJAVSX9VYXMYRhyeHxt7w98XscfTiHlWbgKFXEyfY5Bwfw520paUYfAIAMX6VQ12hGigGICM6lSb4510+C6Hy0LBUNFJt9GnmrLboVuNag7D8m4Tr1AGxGi/Jhv1o2JSByKOZPXxuLr/ah7JNVAmmqBfRE2FR+6SHkcpboNf6dAKiwSGmSr2BwizSp/MfOZuYePLEzidKpOrV1ybFx9nvu9PyhlHaMniQlCzkX0gT06XN+IxrXrdz9iLchgsWnAP5IowJPtl212ckB" > /home/ansible/.ssh/authorized_keys
    
RUN sed -i \
	-e 's/^UsePAM yes/#UsePAM yes/g' \
	-e 's/^#UsePAM no/UsePAM no/g' \
	-e 's/^PasswordAuthentication yes/PasswordAuthentication no/g' \
	-e 's/^#PermitRootLogin yes/PermitRootLogin no/g' \
	-e 's/^#UseDNS yes/UseDNS no/g' \
	/etc/ssh/sshd_config
RUN sed -i 's/^# %wheel\tALL=(ALL)\tALL/%wheel\tALL=(ALL)\tALL/g' /etc/sudoers
COPY supervisord.conf /etc/supervisor.d/supervisord.conf
ENV container docker
ENV DATE_TIMEZONE UTC
VOLUME /var/log /etc
EXPOSE 22
USER root
CMD ["/usr/bin/supervisord", "-n", "-c/etc/supervisor.d/supervisord.conf"]
