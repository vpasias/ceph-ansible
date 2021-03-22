#! /bin/sh

export LC_ALL=C
export LC_CTYPE="UTF-8",
export LANG="en_US.UTF-8"

# ---- PART ONE ------
# Configure SSH connectivity from 'deployment' - server104 to Target Hosts 

echo 'run-conf.sh: Cleaning directory /home/vagrant/.ssh/'
rm -f /home/vagrant/.ssh/known_hosts
rm -f /home/vagrant/.ssh/id_rsa
rm -f /home/vagrant/.ssh/id_rsa.pub

echo 'run-conf.sh: Running ssh-keygen -t rsa'
ssh-keygen -q -t rsa -N "" -f /home/vagrant/.ssh/id_rsa

echo 'run-conf.sh: Install sshpass'
sudo apt -y install sshpass

echo 'run-conf.sh: Running ssh-copy-id for server701'
sshpass -p vagrant ssh-copy-id -o StrictHostKeyChecking=no vagrant@server701
echo 'run-conf.sh: Running ssh-copy-id for server702'
sshpass -p vagrant ssh-copy-id -o StrictHostKeyChecking=no vagrant@server702
echo 'run-conf.sh: Running ssh-copy-id for server703'
sshpass -p vagrant ssh-copy-id -o StrictHostKeyChecking=no vagrant@server703

echo 'run-conf.sh: Running scp node_setup.sh for server701'
scp -o StrictHostKeyChecking=no node_setup.sh vagrant@server701:/home/vagrant/node_setup.sh
echo 'run-conf.sh: Running scp node_setup.sh for server702'
scp -o StrictHostKeyChecking=no node_setup.sh vagrant@server702:/home/vagrant/node_setup.sh
echo 'run-conf.sh: Running scp node_setup.sh for server703'
scp -o StrictHostKeyChecking=no node_setup.sh vagrant@server703:/home/vagrant/node_setup.sh

echo 'run-conf.sh: Running ssh vagrant@server701 “sudo bash /home/vagrant/node_setup.sh”'
ssh -o StrictHostKeyChecking=no vagrant@server701 "sudo bash /home/vagrant/node_setup.sh"
echo 'run-conf.sh: Running ssh vagrant@server702 “sudo bash /home/vagrant/node_setup.sh”'
ssh -o StrictHostKeyChecking=no vagrant@server702 "sudo bash /home/vagrant/node_setup.sh"
echo 'run-conf.sh: Running ssh vagrant@server703 “sudo bash /home/vagrant/node_setup.sh”'
ssh -o StrictHostKeyChecking=no vagrant@server703 "sudo bash /home/vagrant/node_setup.sh"

sleep 30

ssh -o StrictHostKeyChecking=no vagrant@server701 "uname -a"
ssh -o StrictHostKeyChecking=no vagrant@server702 "uname -a"
ssh -o StrictHostKeyChecking=no vagrant@server703 "uname -a"

echo 'run-conf.sh: Configuration of Ansible'

DEBIAN_FRONTEND=noninteractive apt update
DEBIAN_FRONTEND=noninteractive apt install -y python3 python3-simplejson python3-jinja2 python3-dev python3-venv python3-pip libffi-dev gcc libssl-dev curl git vim
pip3 install -U pip

echo 'run-kolla.sh: Install Ansible'
sudo pip3 install --upgrade pip
sudo pip install -r requirements.txt

if [ $? -ne 0 ]; then
  echo "Cannot install Ansible"
  exit $?
fi

echo 'run-conf.sh: Configuration of Ceph-Ansible'

git clone https://github.com/ceph/ceph-ansible.git
cd ceph-ansible
git checkout stable-5.0

cat << EOF | tee group_vars/all.yml
generate_fsid: true
monitor_interface: bond0
journal_size: 5120
public_network: 172.16.3.0/24
cluster_network: 172.16.3.0/24
cluster_interface: bond0
ceph_docker_image: "ceph/daemon"
ceph_docker_image_tag: latest-octopus
containerized_deployment: true
osd_objectstore: bluestore
ceph_docker_registry: docker.io
radosgw_interface: bond0
dashboard_admin_password: admin
grafana_admin_password: password
EOF

cat << EOF | tee group_vars/osds.yml
osd_scenario: collocated
copy_admin_key: true
dmcrypt: false
devices:
  - /dev/sda
  - /dev/sdb
EOF

cat << EOF | tee group_vars/mgrs.yml
ceph_mgr_modules: [status]
EOF

cp site-container.yml.sample site-container.yml

cat << EOF | tee hosts
[mons]
server701 ansible_ssh_user=vagrant ansible_become=True ansible_private_key_file=/home/vagrant/.ssh/id_rsa
server702 ansible_ssh_user=vagrant ansible_become=True ansible_private_key_file=/home/vagrant/.ssh/id_rsa
server703 ansible_ssh_user=vagrant ansible_become=True ansible_private_key_file=/home/vagrant/.ssh/id_rsa

[osds]
server701 ansible_ssh_user=vagrant ansible_become=True ansible_private_key_file=/home/vagrant/.ssh/id_rsa
server702 ansible_ssh_user=vagrant ansible_become=True ansible_private_key_file=/home/vagrant/.ssh/id_rsa
server703 ansible_ssh_user=vagrant ansible_become=True ansible_private_key_file=/home/vagrant/.ssh/id_rsa

[grafana-server]
server703 ansible_ssh_user=vagrant ansible_become=True ansible_private_key_file=/home/vagrant/.ssh/id_rsa

[mgrs]
server701 ansible_ssh_user=vagrant ansible_become=True ansible_private_key_file=/home/vagrant/.ssh/id_rsa
server702 ansible_ssh_user=vagrant ansible_become=True ansible_private_key_file=/home/vagrant/.ssh/id_rsa
server703 ansible_ssh_user=vagrant ansible_become=True ansible_private_key_file=/home/vagrant/.ssh/id_rsa

[rgws]
server701 ansible_ssh_user=vagrant ansible_become=True ansible_private_key_file=/home/vagrant/.ssh/id_rsa
server702 ansible_ssh_user=vagrant ansible_become=True ansible_private_key_file=/home/vagrant/.ssh/id_rsa
server703 ansible_ssh_user=vagrant ansible_become=True ansible_private_key_file=/home/vagrant/.ssh/id_rsa
EOF

echo 'run-conf.sh: Check Node Connectivity'

ansible -m ping -i hosts

echo 'run-conf.sh: Run Ceph-Ansible'

ansible-playbook site-container.yml -i hosts

#docker exec -it ceph-mon-server701 ceph -s
# http://bwdt.breqwatr.com/
# https://docs.ceph.com/en/latest/rbd/rbd-openstack/
# https://docs.openstack.org/kolla-ansible/latest/reference/storage/external-ceph-guide.html
