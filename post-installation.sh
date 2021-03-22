#! /bin/sh

export LC_ALL=C
export LC_CTYPE="UTF-8",
export LANG="en_US.UTF-8"

#docker exec -it ceph-mon-server701 ceph -s
# http://bwdt.breqwatr.com/
# https://docs.ceph.com/en/latest/rbd/rbd-openstack/
# https://docs.openstack.org/kolla-ansible/latest/reference/storage/external-ceph-guide.html

# Execute on Ceph monitor node

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
ceph auth get-or-create client.cinder-backup mon 'profile rbd' osd 'profile rbd pool=backups' mgr 'profile rbd pool=backups'

cat /etc/ceph/ceph.conf | grep -e fsid -e "mon initial members" -e "mon host"

cat << EOF | tee ceph.conf
[global]
# to be derived from /etc/ceph/ceph.conf
fsid = 1d89fec3-325a-4963-a950-c4afedd37fe3
# to be derived from /etc/ceph/ceph.conf
mon_initial_members = ceph-0
# to be derived from /etc/ceph/ceph.conf
mon_host = 192.168.0.56
auth_cluster_required = cephx
auth_service_required = cephx
auth_client_required = cephx
EOF

ceph auth get-or-create client.glance | ssh vagrant@server104 'sudo tee /etc/kolla/config/glance/ceph.client.glance.keyring'
ssh vagrant@server104 'sudo chown glance:glance /etc/kolla/config/glance/ceph.client.glance.keyring'

ceph auth get-or-create client.cinder | ssh vagrant@server104 'sudo tee /etc/kolla/config/cinder/ceph.client.cinder.keyring'
ssh vagrant@server104 'sudo chown cinder:cinder /etc/kolla/config/cinder/ceph.client.cinder.keyring'
ceph auth get-or-create client.cinder | ssh vagrant@server104 'sudo tee /etc/kolla/config/cinder/cinder-volume/ceph.client.cinder.keyring'
ssh vagrant@server104 'sudo chown cinder:cinder /etc/kolla/config/cinder/cinder-volume/ceph.client.cinder.keyring'
ceph auth get-or-create client.cinder | ssh vagrant@server104 'sudo tee /etc/kolla/config/cinder/cinder-backup/ceph.client.cinder.keyring'
ssh vagrant@server104 'sudo chown cinder:cinder /etc/kolla/config/cinder/cinder-backup/ceph.client.cinder.keyring'

ceph auth get-or-create client.cinder-backup | ssh vagrant@server104 'sudo tee /etc/kolla/config/cinder/cinder-backup/ceph/ceph.client.cinder-backup.keyring'
ssh vagrant@server104 'sudo chown cinder:cinder /etc/kolla/config/cinder/cinder-backup/ceph/ceph.client.cinder-backup.keyring'

ceph auth get-or-create client.cinder | ssh vagrant@server104 'sudo tee /etc/kolla/config/nova/ceph.client.cinder.keyring'
ssh vagrant@server104 'sudo chown nova:nova /etc/kolla/config/nova/ceph.client.cinder.keyring'

scp -o StrictHostKeyChecking=no ceph.conf vagrant@server104:/home/vagrant/ceph.conf
ssh vagrant@server104 "sudo cp /home/vagrant/ceph.conf /etc/kolla/config/glance/ceph.conf && sudo cp /home/vagrant/ceph.conf /etc/kolla/config/cinder/ceph.conf"
ssh vagrant@server104 "sudo cp /home/vagrant/ceph.conf /etc/kolla/config/cinder/cinder-backup/ceph.conf && sudo cp /home/vagrant/ceph.conf /etc/kolla/config/cinder/cinder-volume/ceph.conf"
ssh vagrant@server104 "sudo cp /home/vagrant/ceph.conf /etc/kolla/config/nova/ceph.conf"
