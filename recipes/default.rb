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
  user 'git'
  admin node[:gitlabhq][:user]
end

# add localhost to known_host
execute "ssh-keyscan localhost > .ssh/known_hosts" do
  user node[:gitlabhq][:user]
  cwd "/home/#{node[:gitlabhq][:user]}"
  not_if "grep localhost .ssh/known_hosts" # FIX! This doesn't work
end
