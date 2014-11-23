Vagrant.configure("2") do |config|
	
	# Specify the base box
	config.vm.box = "ubuntu/trusty64"
	
	# Setup Networking
	config.vm.network :"private_network", ip: "192.168.56.101"
	
	# Setup synced folder
	config.vm.synced_folder "./", "/var/www", create: true, group: "www-data", owner: "www-data"

	# VM specific configs
	config.vm.provider "virtualbox" do |v|
		v.memory = 1024
		v.cpus = 2
	end

	# Shell provisioning
	config.vm.provision "shell" do |s|
		s.path = "provision/setup.sh"
	end
end