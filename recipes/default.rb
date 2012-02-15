include_recipe 'gitolite::default'

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

gitolite_instance do
  admin_key IO.read("/home/#{node[:gitlabhq][:user]}/.ssh/id_rsa.pub")
  user 'git'
  admin 'gitlabhq'
end

# add localhost to known_host