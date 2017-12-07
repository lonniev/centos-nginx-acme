name             'centos-nginx-acme'
maintainer       'Lonnie VanZandt'
maintainer_email 'lonniev@gmail.com'
license          'Apache 2.0'
description      'Installs Nginx and a LetsEncrypt SSL cert for an HTTPS server'
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          '0.1.0'

%w( centos redhat fedora ).each do |os|
  supports os
end

depends 'chef_nginx'
depends 'acme'
