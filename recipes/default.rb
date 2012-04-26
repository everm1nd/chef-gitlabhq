# Create the user
user node[:gitlabhq][:user] do
  comment "gitlabhq user"
  home "/home/#{node[:gitlabhq][:user]}"
  shell "/bin/zsh"
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

include_recipe "gitolite::default"

# Create a gitolite instance managed by this user
gitolite "create-instance" do
  user 'git'
  admin node[:gitlabhq][:user]
  key_path "/home/#{node[:gitlabhq][:user]}/.ssh/id_rsa.pub"
  action :create
end

# Add to git group
group "git" do
  members node[:gitlabhq][:user]
  append true
end

# Fix permissions
directory '/home/git/repositories' do
  owner 'git'
  group 'git'
  mode 0770
  recursive true
end

# add localhost to known_host to automatically connect
execute "ssh-keyscan `uname -n` > .ssh/known_hosts" do
  user node[:gitlabhq][:user]
  cwd "/home/#{node[:gitlabhq][:user]}"
  not_if "grep localhost .ssh/known_hosts" # FIX! This doesn't work
end

# Get additional packages
include_recipe "apt"
include_recipe "git"
include_recipe "build-essential"

packages = %w{wget curl checkinstall libxml2-dev libxslt1-dev libcurl4-openssl-dev libc6-dev libssl-dev libmysql++-dev zlib1g-dev libicu-dev redis-server sendmail python-dev python-setuptools}

packages.each do |pkg|
  package pkg
end

easy_install_package "pygments" do
  action :install
end

%w{bundler foreman}.each do |name|
  rbenv_gem name do
    action :install
  end
end

# Prepare folders
directory node[:gitlabhq][:path] do
  owner node[:gitlabhq][:user]
  group node[:gitlabhq][:user]
  mode '0755'
  recursive true
end

directory "#{node[:gitlabhq][:path]}/shared" do
  owner node[:gitlabhq][:user]
  group node[:gitlabhq][:user]
  mode '0755'
  recursive true
end

%w{ log pids system vendor_bundle }.each do |dir|
  directory "#{node[:gitlabhq][:path]}/shared/#{dir}" do
    owner node[:gitlabhq][:user]
    group node[:gitlabhq][:user]
    mode '0755'
    recursive true
  end
end

# Configuration files
%w{gitlab database}.each do |cf|
  template "#{node[:gitlabhq][:path]}/shared/#{cf}.yml" do
    source "#{cf}.yml.erb"
    owner node[:gitlabhq][:user]
    group node[:gitlabhq][:user]
    mode "644"
  end
end

# Deploy gitlabhq
deploy_revision "gitlabhq" do
  repository "git://github.com/gitlabhq/gitlabhq.git"
  branch "stable"
  user node[:gitlabhq][:user]
  deploy_to node[:gitlabhq][:path]
  environment 'production'
  action :deploy
  before_migrate do
    link "#{release_path}/vendor/bundle" do
      to "#{node[:gitlabhq][:path]}/shared/vendor_bundle"
    end
    execute "bundle install --deployment --without test development" do
      # ignore_failure true
      cwd release_path
    end
    execute "rake assets:precompile" do
      cwd release_path
    end
  end

  symlink_before_migrate({
    "gitlab.yml" => "config/gitlab.yml",
    "database.yml" => "config/database.yml"
  })

  migrate true
  migration_command "bundle exec rake db:setup; bundle exec rake db:seed_fu"
end
