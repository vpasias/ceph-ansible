#! /bin/sh

export LC_ALL=C
export LC_CTYPE="UTF-8",
export LANG="en_US.UTF-8"

docker exec -it ceph-mon-server701 ceph -s
# http://bwdt.breqwatr.com/
# https://docs.ceph.com/en/latest/rbd/rbd-openstack/
# https://docs.openstack.org/kolla-ansible/latest/reference/storage/external-ceph-guide.html

# Execute on Ceph monitor node
docker exec -it ceph-mon-server701 ceph osd lspools

docker exec -it ceph-mon-server701 ceph osd pool create volumes 256
docker exec -it ceph-mon-server701 ceph osd pool create images 64

docker exec -it ceph-mon-server701 ceph osd pool set volumes size 3
docker exec -it ceph-mon-server701 ceph osd pool application enable volumes rbd

docker exec -it ceph-mon-server701 ceph osd pool set images size 3
docker exec -it ceph-mon-server701 ceph osd pool application enable images rbd

docker exec -it ceph-mon-server701 ceph osd pool create backups
docker exec -it ceph-mon-server701 ceph osd pool create vms

docker exec -it ceph-mon-server701 rbd pool init volumes
docker exec -it ceph-mon-server701 rbd pool init images
docker exec -it ceph-mon-server701 rbd pool init backups
docker exec -it ceph-mon-server701 rbd pool init vms

docker exec -it ceph-mon-server701 ceph auth ls

docker cp ceph-mon-server701:/etc/ceph/ceph.conf /root/main-ceph.conf

docker exec -it ceph-mon-server701 ceph auth get-or-create client.glance mon 'profile rbd' osd 'profile rbd pool=images' mgr 'profile rbd pool=images'
# key = AQBaKmBg58uZAxAAQ0KHN2oEduF6lD0EF9gUiA==
docker exec -it ceph-mon-server701 ceph auth get-or-create client.cinder mon 'profile rbd' osd 'profile rbd pool=volumes, profile rbd pool=vms, profile rbd-read-only pool=images' mgr 'profile rbd pool=volumes, profile rbd pool=vms'
# key = AQCYKmBgZfpTFxAAiAO9MJ8zwGJH2T9SLaJ1MQ==
docker exec -it ceph-mon-server701 ceph auth get-or-create client.cinder-backup mon 'profile rbd' osd 'profile rbd pool=backups' mgr 'profile rbd pool=backups'
# key = AQClKmBgj8Y6GxAAe1VDD3cpFgT9Evk/piaDmA==

#docker exec -it ceph-mon-server701 ceph auth get-or-create client.glance

docker exec -it ceph-mon-server701 ceph auth get-or-create client.glance | sshpass -p vagrant ssh vagrant@server104 'sudo tee /etc/kolla/config/glance/ceph.client.glance.keyring'

docker exec -it ceph-mon-server701 ceph auth get-or-create client.cinder | sshpass -p vagrant ssh vagrant@server104 'sudo tee /etc/kolla/config/cinder/ceph.client.cinder.keyring'

docker exec -it ceph-mon-server701 ceph auth get-or-create client.cinder | sshpass -p vagrant ssh vagrant@server104 'sudo tee /etc/kolla/config/cinder/cinder-volume/ceph.client.cinder.keyring'

docker exec -it ceph-mon-server701 ceph auth get-or-create client.cinder | sshpass -p vagrant ssh vagrant@server104 'sudo tee /etc/kolla/config/cinder/cinder-backup/ceph.client.cinder.keyring'

docker exec -it ceph-mon-server701 ceph auth get-or-create client.cinder-backup | sshpass -p vagrant ssh vagrant@server104 'sudo tee /etc/kolla/config/cinder/cinder-backup/ceph/ceph.client.cinder-backup.keyring'

docker exec -it ceph-mon-server701 ceph auth get-or-create client.cinder | sshpass -p vagrant ssh vagrant@server104 'sudo tee /etc/kolla/config/nova/ceph.client.cinder.keyring'

docker exec -it ceph-mon-server701 cat /etc/ceph/ceph.conf | grep -e fsid -e "mon initial members" -e "mon host"
