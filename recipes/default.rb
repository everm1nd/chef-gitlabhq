# Create the user
user node[:gitlabhq][:user] do
  comment "gitlabhq user"
  home "/home/#{node[:gitlabhq][:user]}"
  shell "/bin/bash"
  action :create
end
# its folder
directory "/home/#{node[:gitlabhq][:user]}" do
  owner node[:gitlabhq][:user]
  action :create
end
# and key
execute "generate ssh keys for #{node[:gitlabhq][:user]}." do
  user node[:gitlabhq][:user]
  creates "/home/#{node[:gitlabhq][:user]}/.ssh/id_rsa.pub"
  command "ssh-keygen -t rsa -q -f /home/#{node[:gitlabhq][:user]}/.ssh/id_rsa -P \"\""
end

# Create a gitolite instance managed by this user
gitolite_instance do
  user 'git'
  admin node[:gitlabhq][:user]
end

# Add to git group
group "git" do
  members ["git", node[:gitlab][:user]]
end

# Fix permissions
directory '/home/git/repositories' do
  owner 'git'
  group 'git'
  mode 770
end

# add localhost to known_host to automatically connect
execute "ssh-keyscan localhost > .ssh/known_hosts" do
  user node[:gitlabhq][:user]
  cwd "/home/#{node[:gitlabhq][:user]}"
  not_if "grep localhost .ssh/known_hosts" # FIX! This doesn't work
end

# Get additional packages
include_recipe "apt"
include_recipe "git"
include_recipe "build-essential"

packages = %w{wget curl gcc checkinstall libxml2-dev libxslt-dev sqlite3 libsqlite3-dev libcurl4-openssl-dev libc6-dev libssl-dev libmysql++-dev make zlib1g-dev libicu-dev redis-server sendmail python-dev}

packages.each do |pkg|
  package pkg
end

easy_install_package "pygments" do
  action :install
end

gem_package "bundler" do
  action :install
end

# Get gitlabhq
git node[:gitlabhq][:path] do
  repository "git://github.com/gitlabhq/gitlabhq.git"
  reference "stable"
  action :sync
  owner node[:gitlabhq][:user]
end



