match="overcloud-controller"
if echo $(hostname) | grep -q ^$match; then 
  echo "$(hostname) macthes $match so installing lbaasv2" > /tmp/lbaasv2.out
else 
  echo "hostname $(hostname) does not match $match so exiting" > /tmp/lbaasv2.out
  exit 0
fi

#where neutron-server is running
yum install openstack-neutron-lbaas

crudini --set /etc/neutron/neutron_lbaas.conf service_providers service_provider LOADBALANCERV2:Haproxy:neutron_lbaas.drivers.haproxy.plugin_driver.HaproxyOnHostPluginDriver:default

plugins=$(crudini --get /etc/neutron/neutron.conf DEFAULT service_plugins)
if ! echo $plugins | grep --quiet lbaasv2; then 
  crudini --set /etc/neutron/neutron.conf DEFAULT service_plugins $plugins,lbaasv2
fi

neutron-db-manage --subproject neutron-lbaas upgrade head
systemctl restart neutron-server.service

#where lbaas agent is running 
crudini --set /etc/neutron/lbaas_agent.ini DEFAULT device_driver
crudini --set /etc/neutron/lbaas_agent.ini DEFAULT user_group haproxy
crudini --set /etc/neutron/lbaas_agent.ini DEFAULT interface_driver neutron.agent.linux.interface.OVSInterfaceDriver
crudini --set /etc/neutron/lbaas_agent.ini DEFAULT device_driver neutron_lbaas.drivers.haproxy.namespace_driver.HaproxyNSDriver
systemctl restart neutron-lbaasv2-agent.service
systemctl enable neutron-lbaasv2-agent.service

echo "---Results---" >> /tmp/lbaasv2.out
#where neutron-server is running
echo "neutron_lbaas.conf service_provider=$(crudini --get /etc/neutron/neutron_lbaas.conf service_providers service_provider)" >> /tmp/lbaasv2.out
plugins=$(crudini --get /etc/neutron/neutron.conf DEFAULT service_plugins)
echo "neutron.conf service_plugins=$(crudini --get /etc/neutron/neutron.conf DEFAULT service_plugins)" >> /tmp/lbaasv2.out

#where lbaas agent is running 
echo "lbaas_agent.ini device_driver=$(crudini --get /etc/neutron/lbaas_agent.ini DEFAULT device_driver)" >> /tmp/lbaasv2.out
echo "lbaas_agent.ini user_group=$(crudini --get /etc/neutron/lbaas_agent.ini DEFAULT user_group )" >> /tmp/lbaasv2.out
echo "lbaas_agent.ini interface_driver=$(crudini --get /etc/neutron/lbaas_agent.ini DEFAULT interface_driver)" >> /tmp/lbaasv2.out
echo "lbaas_agent.ini device_driver=$(crudini --get /etc/neutron/lbaas_agent.ini DEFAULT device_driver)" >> /tmp/lbaasv2.out

echo "neutron-server $(systemctl is-active neutron-server)" >> /tmp/lbaasv2.out
echo "neutron-lbaasv2-agent $(systemctl is-active neutron-lbaasv2-agent)" >> /tmp/lbaasv2.out
cat /tmp/lbaasv2.out



