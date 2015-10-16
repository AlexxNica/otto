# Generated by Otto, do not edit!
#
# This is the Vagrantfile generated by Otto for the development of
# this application/service. It should not be hand-edited. To modify the
# Vagrantfile, use the Appfile.

Vagrant.configure("2") do |config|
  config.vm.box = "hashicorp/precise64"

  # Host only network
  config.vm.network "private_network", ip: "{{ dev_ip_address }}"

  # Setup a synced folder from our working directory to /vagrant
  config.vm.synced_folder '{{ path.working }}', "/vagrant",
    owner: "vagrant", group: "vagrant"

  # Enable SSH agent forwarding so getting private dependencies works
  config.ssh.forward_agent = true

  # Foundation configuration (if any)
  {% for dir in foundation_dirs.dev %}
  dir = "/otto/foundation-{{ forloop.Counter }}"
  config.vm.synced_folder '{{ dir }}', dir
  config.vm.provision "shell", inline: "cd #{dir} && bash #{dir}/main.sh"
  {% endfor %}

  # Load all our fragments here for any dependencies.
  {% for fragment in dev_fragments %}
  {{ fragment|read }}
  {% endfor %}

  # Install build environment
  config.vm.provision "shell", inline: $script_app

  config.vm.provider :parallels do |p, o|
    o.vm.box = "parallels/ubuntu-12.04"
  end
end

$script_app = <<SCRIPT
set -e

# otto-exec: execute command with output logged but not displayed
oe() { $@ 2>&1 | logger -t otto > /dev/null; }

# otto-log: output a prefixed message
ol() { echo "[otto] $@"; }

# Make it so that `vagrant ssh` goes directly to the correct dir
echo "cd /vagrant" >> /home/vagrant/.bashrc

# Configuring SSH for faster login
if ! grep "UseDNS no" /etc/ssh/sshd_config >/dev/null; then
  echo "UseDNS no" | sudo tee -a /etc/ssh/sshd_config >/dev/null
  oe sudo service ssh restart
fi

export DEBIAN_FRONTEND=noninteractive
ol "Upgrading Outdated Apt Packages..."
oe sudo aptitude update -y
oe sudo aptitude upgrade -y

ol "Downloading Java 8..."
oe sudo aptitude install software-properties-common python-software-properties -y
oe sudo aptitude update -y
oe sudo add-apt-repository ppa:webupd8team/java -y
oe sudo aptitude update -y
oe sudo apt-get install -y --force-yes oracle-java8-installer oracle-java8-set-default

ol "Downloading Gradle {{ gradle_version }}..."
oe sudo add-apt-repository ppa:cwchien/gradle -y
oe sudo aptitude update -y
oe sudo apt-cache search gradle
oe sudo aptitude install gradle-{{ gradle_version }} -y

ol "Installing Git..."
oe sudo add-apt-repository ppa:git-core/ppa -y
oe sudo aptitude update -y
oe sudo aptitude install git -y

SCRIPT
