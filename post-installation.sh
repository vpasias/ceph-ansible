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

ceph auth ls
rbd pool init backups
rbd pool init vms
