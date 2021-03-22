#! /bin/sh

export LC_ALL=C
export LC_CTYPE="UTF-8",
export LANG="en_US.UTF-8"

#docker exec -it ceph-mon-server701 ceph -s
# http://bwdt.breqwatr.com/
# https://docs.ceph.com/en/latest/rbd/rbd-openstack/
# https://docs.openstack.org/kolla-ansible/latest/reference/storage/external-ceph-guide.html

ceph osd lspools

ceph osd pool create volumes 2048
ceph osd pool create images 256

ceph osd pool set volumes size 3
ceph osd pool application enable volumes rbd

ceph osd pool set images size 3
ceph osd pool application enable images rbd

ceph osd pool create backups
ceph osd pool create vms

rbd pool init volumes
rbd pool init images
rbd pool init backups
rbd pool init vms

ceph auth ls

ceph auth get-or-create client.glance mon 'profile rbd' osd 'profile rbd pool=images' mgr 'profile rbd pool=images'
ceph auth get-or-create client.cinder mon 'profile rbd' osd 'profile rbd pool=volumes, profile rbd pool=vms, profile rbd-read-only pool=images' mgr 'profile rbd pool=volumes, profile rbd pool=vms'
ceph auth get-or-create client.nova mon 'profile rbd' osd 'profile rbd pool=volumes, profile rbd pool=vms, profile rbd-read-only pool=images' mgr 'profile rbd pool=volumes, profile rbd pool=vms'
ceph auth get-or-create client.cinder-backup mon 'profile rbd' osd 'profile rbd pool=backups' mgr 'profile rbd pool=backups'

ceph auth get-or-create client.glance | ssh server104 'sudo tee /etc/ceph/ceph.client.glance.keyring'
ssh server104 'sudo chown glance:glance /etc/ceph/ceph.client.glance.keyring'
ceph auth get-or-create client.cinder | ssh server104 'sudo tee /etc/ceph/ceph.client.cinder.keyring'
ssh server104 'sudo chown cinder:cinder /etc/ceph/ceph.client.cinder.keyring'
ceph auth get-or-create client.cinder-backup | ssh server104 'sudo tee /etc/ceph/ceph.client.cinder-backup.keyring'
ssh server104 'sudo chown cinder:cinder /etc/ceph/ceph.client.cinder-backup.keyring'

ceph auth get client.cinder > ceph.client.cinder.keyring
