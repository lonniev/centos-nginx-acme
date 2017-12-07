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

# Include the recipe to install the gems
include_recipe 'acme'

# Set up contact information. Note the mailto: notation
node.set['acme']['contact'] = ['mailto:me@example.com']
# Real certificates please...
node.set['acme']['endpoint'] = 'https://acme-v01.api.letsencrypt.org'

site = "example.com"
sans = ["www.#{site}"]

# Generate a self-signed if we don't have a cert to prevent bootstrap problems
acme_selfsigned "#{site}" do
  crt     "/etc/ssl/#{site}.crt"
  key     "/etc/ssl/#{site}.key"
  chain    "/etc/ssl/private/#{site}.pem"
  owner   "nginx"
  group   "nginx"
  notifies :restart, "service[nginx]", :immediate
end

# Set up your webserver here...
include_recipe 'nginx'

# Get and auto-renew the certificate from Let's Encrypt
acme_ssl_certificate "/etc/ssl/#{site}.crt" do
  cn                site
  alt_names         sans
  output            :crt # or :fullchain
  key               "/etc/ssl/private/#{site}.pem"
  min_validity      30 #Renew certificate if expiry is closed than this many days

  webserver         :nginx
end
