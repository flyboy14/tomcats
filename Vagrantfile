# here you can specify number of tomcat VMs to be balanced by httpd VM
#
COUNT=2

Vagrant.configure("2") do |config|
#
# creating and configuring VM for httpd balancer
#
  config.vm.define "web" do |web|
    web.vm.box = "sbeliakou/centos"
    web.vm.hostname = "kazak-web"
    web.vm.network "private_network", ip: "192.168.56.2"
    web.vm.provider "virtualbox" do |vb|
      vb.memory = "1024"
    end
    web.vm.provision "shell", path: "provision_httpd.sh", :args => "#{COUNT}"
  end
#
# creating and configuring VMs for tomcat nodes
#
  (1..COUNT).each do |i|
    config.vm.define "java#{i}" do |java|
      java.vm.box = "sbeliakou/centos"
      java.vm.hostname = "kazak-tomcat#{i}"
      java.vm.network "private_network", ip: "192.168.56.#{i+2}"
      java.vm.provider "virtualbox" do |vb|
        vb.memory = "2048"
      end
      java.vm.provision "shell", path: "provision_tomcat.sh"
    end 
  end
  config.vm.define "web" do |web|
    web.vm.provision "shell", path: "provision_discover.sh"
  end
  (1..COUNT).each do |i|
    config.vm.define "java#{i}" do |java|
      java.vm.provision "shell", path: "provision_discover.sh"
    end
  end
end
