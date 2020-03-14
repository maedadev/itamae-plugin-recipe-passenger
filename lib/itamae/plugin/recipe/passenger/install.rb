passenger_version = ENV['PASSENGER_VERSION'] || Itamae::Plugin::Recipe::Passenger::PASSENGER_VERSION

execute "download passenger-#{passenger_version}" do
  cwd '/tmp'
  command <<-EOF
    rm -f passenger-release-#{passenger_version}.tar.gz
    wget https://github.com/phusion/passenger/archive/release-#{passenger_version}.tar.gz -O passenger-release-#{passenger_version}.tar.gz
  EOF
  not_if "test -e /opt/passenger/#{passenger_version}/INSTALLED || echo #{::File.read(::File.join(::File.dirname(__FILE__), "passenger-6.0.4_sha256.txt")).strip} | sha256sum -c"
end

directory '/opt/passenger' do
  user 'root'
  owner 'root'
  group 'root'
  mode '755'
end

execute "install passenger-#{passenger_version}" do
  cwd '/tmp'
  command <<-EOF
    rm -Rf passenger-release-#{passenger_version}/
    tar zxf passenger-release-#{passenger_version}.tar.gz
    sudo rm -Rf /opt/passenger/#{passenger_version}
    sudo mv passenger-release-#{passenger_version} /opt/passenger/#{passenger_version}
    sudo touch /opt/passenger/#{passenger_version}/INSTALLED
    sudo chown -R root:root /opt/passenger/#{passenger_version}/
    sudo chmod 755 /opt/passenger/#{passenger_version}
  EOF
  not_if "test -e /opt/passenger/#{passenger_version}/INSTALLED"
end

link '/opt/passenger/current' do
  to "/opt/passenger/#{passenger_version}"
  user 'root'
  force true
end

directory '/var/run/passenger-instreg' do
  user 'root'
  owner 'root'
  group 'root'
  mode '755'
end

case "#{node.platform_family}-#{node.platform_version}"
when /rhel-7\.(.*?)/
  template '/etc/tmpfiles.d/passenger.conf' do
    user 'root'
    owner 'root'
    group 'root'
    mode '644'
    variables path: '/var/run/passenger-instreg',
        owner: 'root',
        group: 'root',
        mode: '0755'
  end
end
