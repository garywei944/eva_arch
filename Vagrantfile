Vagrant.configure("2") do |config|
  config.vm.box = "ubuntu/focal64"

  config.vm.provider "virtualbox" do |vb|
    vb.gui = false
  end
  config.vm.network "forwarded_port", id: "ssh", host: 2222, guest: 22
  config.vm.synced_folder '.', '/vagrant', disabled: true
  config.vm.synced_folder "./sandbox", "/home/vagrant/sandbox"
end
