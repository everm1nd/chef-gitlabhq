include_recipe "gitlabhq::default"

# Serve with apache passenger
include_recipe "passenger_apache2::mod_rails"

web_app "gitlabhq" do
  docroot "#{node[:gitlabhq][:path]}/current/public"
  server_name node[:fqdn]
  server_aliases [ node[:hostname] ]
  rails_env "production"
  cookbook "passenger_apache2"
end
