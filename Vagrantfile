Vagrant.configure(2) do |config|
  config.vm.box = "ubuntu/trusty64"

  config.vm.hostname = 'myUbuntu'
  config.vm.synced_folder "workdata/", "/workdata"




  config.vm.provider 'virtualbox' do |virtualbox|
    virtualbox.linked_clone = true
    virtualbox.name = 'myUbubtu'
    virtualbox.gui = true
    virtualbox.memory =  3*1024
    virtualbox.cpus = 2
    virtualbox.customize ['modifyvm', :id, '--vram', 64]
    virtualbox.customize ['modifyvm', :id, '--clipboard', 'bidirectional']
  end

  config.vm.network "forwarded_port", guest: 8080, host: 8080, protocol: "tcp"
  config.vm.network "forwarded_port", guest: 9090, host: 9090, protocol: "tcp"
  config.vm.network "forwarded_port", guest: 3000, host: 3000, protocol: "tcp"
  config.vm.network "forwarded_port", guest: 9100, host: 9100, protocol: "tcp"
  config.vm.network "forwarded_port", guest: 9201, host: 9201, protocol: "tcp"
  config.vm.network "forwarded_port", guest: 80, host: 80, protocol: "tcp"

  config.vm.provision 'shell' do |initscript|
    initscript.path="user-data.sh"
  end
end