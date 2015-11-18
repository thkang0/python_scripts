#!/usr/bin/env python

from keystoneclient.auth.identity import v2
from keystoneclient import session
from glanceclient import Client as glanceClient
from neutronclient.v2_0 import client as neutronClient
from novaclient import client as nova_client
from glanceclient import client as glance_client
import argparse
import yaml
import os


class DeploymentTest(object):
    def __init__(self, config):
        self.config = config
	self.auth = None
	self.session = None
        #self.username = username
        #self.password = password
        #self.tenant_name = tenant_name

    def get_auth(self):
        config = self.config.get('environment')
        openstack_config = config.get('openstack')
        self.auth = v2.Password(auth_url=openstack_config['auth_url'], username=openstack_config['username'], password=openstack_config['password'], tenant_name=openstack_config['tenant_name'])
        self.session = session.Session(auth=self.auth)

    def create_image(self):
        config = self.config.get('environment')
        glance_config = config.get('glance')
	self.get_auth()
	token = self.auth.get_token(self.session)
	glance = glanceClient('1', endpoint=glance_config['endpoint'], token=token)
	#images = glance.images.list()
	for image in glance_config['images']:
	    image_url = glance_config['images'][image].split('/')
	    image_name = image_url[len(image_url) - 1].split('.img')
	    glance.images.create(name=image, disk_format="qcow2", container_format="bare", location=glance_config['images'][image])
	    #filename= "cirros-0.3.4-x86_64-disk.img"
	    #with open(filename, 'r') as fimage:
	    #    glance.images.create(name="test_cirros", disk_format="qcow2", container_format="bare", data=fimage) 
	    
    def create_internal_network(self):
	config = self.config.get('environment')
	openstack_config = config.get('openstack')
        internal_networks = config.get('internal')	

	neutron = neutronClient.Client(username=openstack_config['username'], password=openstack_config['password'], tenant_name=openstack_config['tenant_name'], auth_url=openstack_config['auth_url'])
	for network in internal_networks:
	    created_network = neutron.create_network({'network':{'name':network}})
	    for internal in internal_networks[network]:
		#create a subnet
		if internal == 'subnet':
		    subnet = neutron.create_subnet({'subnet':{'name':internal_networks[network][internal]['name'], 'network_id':created_network['network']['id'], 'ip_version':4, 'cidr':internal_networks[network][internal]['cidr'], 'gateway_ip':internal_networks[network][internal]['gateway']}}) 
		elif internal == 'router':
		    router = neutron.create_router({'router':{'name':internal_networks[network][internal]['name']}})
		    neutron.add_interface_router(router['router']['id'], {'subnet_id':subnet['subnet']['id']})

		    #neutron.create_subnet({'subnet':{'name':internal_networks[network][internal]['name'], 'network_id':created_network['network']['id'], 'ip_version':4, 'cidr':internal_networks[network][internal]['cidr'], 'gateway_ip':internal_networks[network][internal]['gateway'], 'list':True, 'dns_nameservers':internal_networks[network][internal]['dns']}}) 
	#print neutron.list_networks()

    def get_credential(self, filename):
	config = self.config.get('environment')
	openstack_config = config.get('openstack')
	with open(filename, 'w') as credential:
	    credential.write("export OS_AUTH_URL=%s\n"%openstack_config['auth_url'])
	    credential.write("export OS_TENANT_NAME=%s\n"%openstack_config['tenant_name'])
	    credential.write("export OS_USERNAME=%s\n"%openstack_config['username'])
	    credential.write("export OS_PASSWORD=%s\n"%openstack_config['password'])


parser = argparse.ArgumentParser(description="create an initial Openstack environment")

#parser.add_argument('-a', '--auth_url', type=str, default='http://localhost:5000/v2.0', required=False, help='keystone endpoint URL like http://192.168.0.100:5000/v2.0')
parser.add_argument('-c', '--config', type=str, default='initial.yaml', required=False)
args = parser.parse_args()

if not os.path.exists(args.config):
    print("Unable to find config file %s" % args.config)
    sys.exit(1)

config = yaml.safe_load(file(args.config))
target = None

test = DeploymentTest(config)
#test.create_image()
#test.create_internal_network()
test.get_credential("python.rc")

#print args.auth_url
#test = DeploymentTest("http://10.5.2.63:5000/v2.0")

#nova = nova_client.Client("2", session=test.access())

#print nova.flavors.list()
