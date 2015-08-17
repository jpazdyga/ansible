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
    echo "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC2t1lWVnWi2wjm8HIjBX+Oetps2nmgCp3jw/CwnXhBZCib35o2nyrZI9JkM5phoZb9XA0M9ZDyrx3bqwjgfrTiF+gFJNd3aeTUGuZUV6T7mALZ9dICy5XYbPRQR3BgLVAfDMMthbWaGiwfeVjxidcLJpDc6wXAj4YiT+80/B2s2TTJM6BIr8n8JoCNsFlheEu7wmAxNj0IpXlt72xTpGuh4LB8ZwiuZzrY5gOYpsfENioHTklHMXr2ucMxbP+mf5Qagtv2R7YrUNSWPRekNbEfYWiqVMTVWxKbRtEIQ7RnoJr2Talum6k5EIJYCrpWKf+2EgykTUyCNymzYaAPLDvT" > /etc/ansible/.ssh/authorized_keys && \
    echo "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDG3FgQxvXcxTpA+D1oN1FeDp+gy3Dgi5VW/DQhyW+HubmIAs3sbNf65mJv2w/KgzFsfU0P0yvch2VohCY2vYWIMtp+fvUhqTg22uUCfNFoZUkolpWzhqXIVSL8wrsBCtJdyyzoIMSdeA9RYGgPOIjOoO91Nookro+CDp7YUe8zBrlCzBNBBjmxJCIv7vDlMkC35xZBqzeIhmIctD0bzGvOe3n4+vGYT4x0loeXu2OmK25SKaYGK4eLkRP0+OSi+1i0L8pLOC9mf46c5gOxe8IcmSGK4vEm7RLB0icp6UfJMHXAkCb0aeAlzdofRR2W5RApOsPVatAemWj7L04qchU9" > /etc/ansible/.ssh/coreos-appdeploy.pub
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
                   ansible-lint && \
    mkdir -p /etc/ansible/ && \
    mkdir -p /etc/ansible/tmp && \
    echo -e "[local]\nlocalhost\n\n[newcoreoshosts]\n\n[newcoreoshosts:vars]\nansible_python_interpreter=\"PATH=/home/ansible/bin:$PATH python\"" > /etc/ansible/hosts && \
    chown ansible:users /etc/ansible -R
COPY supervisord.conf /etc/supervisor.d/supervisord.conf
COPY add_new_coreos_host.sh /usr/local/bin/add_new_coreos_host.sh
RUN chmod 755 /usr/local/bin/add_new_coreos_host.sh
COPY coreos-bootstrap.yml /etc/ansible/coreos-bootstrap.yml
COPY coreos-fsdeploy.yml /etc/ansible/coreos-fsdeploy.yml
RUN sed -i \
        -e 's/^#host_key_checking = False/host_key_checking = False/g' \
        /etc/ansible/ansible.cfg
RUN su ansible -c "ansible-galaxy install defunctzombie.coreos-bootstrap"
ENV container docker
ENV DATE_TIMEZONE UTC
VOLUME /var/log /etc
EXPOSE 22
USER root
CMD ["/usr/bin/supervisord", "-n", "-c/etc/supervisor.d/supervisord.conf"]
