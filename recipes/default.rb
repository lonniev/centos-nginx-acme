#
# Cookbook Name:: centos-nginx-acme
# Recipe:: default
#
# Author:: Lonnie VanZandt <lonniev@gmail.com>
# Copyright 2017
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

# add the nginx user
user 'nginx' do
  comment 'the nginx System user'
  manage_home true
  shell '/bin/bash'
  password '$1$NY9X5EGS$z06n0rlxUEy3q.Iw4oHMf1'
end

# add the nginx groups
%w( nginx )
.each do |grp|
  group grp.to_s do
    action :create
    members 'nginx'
  end
end

%w( /etc /etc/ssl /etc/ssl/private )
.each do |dir|
  directory dir.to_s do
    action :create
  end
end

# Include the recipe to install the gems
include_recipe 'acme'

contact_email = node['centos-nginx-acme']["contact_email"]

# Set up contact information. Note the mailto: notation
node.set['acme']['contact'] = ["mailto:#{contact_email}"]
# Real certificates please...
node.set['acme']['endpoint'] = 'https://acme-v01.api.letsencrypt.org'

site = node['centos-nginx-acme']["site"]
sans = ["www.#{site}"]

# Generate a self-signed if we don't have a cert to prevent bootstrap problems
acme_selfsigned "#{site}" do
  crt     "/etc/ssl/#{site}.crt"
  key     "/etc/ssl/#{site}.key"
  chain   "/etc/ssl/private/#{site}.pem"
  owner   "nginx"
  group   "nginx"
  cn      site
end

# Set up your webserver here...
http_port = node['centos-nginx-acme']['http_port']
https_port = node['centos-nginx-acme']['https_port']
node.set['nginx']['port'] = http_port
node.set['nginx']['ssl_port'] = https_port

# inform SELinux to allow nginx to use the requested http supports
[ http_port https_port ].each { |port|
  execute "Allow port #{port} binding" do
    command "semanage port -a -t http_port_t -p tcp #{port}"
    not_if "semanage port -l|grep http_port_t|grep #{port}"
  end
}

# Install an nginx webserver
include_recipe 'chef_nginx'

nginx_site site do
  template 'ssl-site.erb'

  notifies :reload, "service[nginx]", :immediately
end

directory node['nginx']['default_root'] do
  owner 'root'
  group 'root'
  recursive true
end

cookbook_file "#{node['nginx']['default_root']}/index.html" do
  source 'index.html'
end

# Get and auto-renew the certificate from Let's Encrypt
acme_ssl_certificate "/etc/ssl/#{site}.crt" do
  cn                site
  alt_names         sans
  output            :fullchain
  key               "/etc/ssl/#{site}.key"
  min_validity      30 #Renew certificate if expiry is closed than this many days

  webserver         :nginx

  notifies  :reload, 'service[nginx]'

  owner 'nginx'
end
