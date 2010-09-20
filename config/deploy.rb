set :application, "tacc_auth"
set :repository,  "git@github.com:geminisbs/rubycas-server.git"
set :user, "deploy"
set :use_sudo, false

set :scm, :git
set :git_enable_submodules, 1

set :deploy_to, "/var/www/vhosts/auth.tadnet.org/#{application}"

set :scm, :git

role :web, "taccweb1.geminisbs.net"                          # Your HTTP server, Apache/etc
role :app, "taccweb1.geminisbs.net"                          # This may be the same as your `Web` server
role :db, "taccweb1.geminisbs.net"

after "deploy:update_code", "rubycas:symlink_config"

# Passenger deployment restart

namespace :deploy do
  task :start do; end
  task :stop do; end
  task :restart, :roles => :app, :except => { :no_release => true } do
    run "#{try_sudo} touch #{File.join(current_path,'tmp','restart.txt')}"
  end
end


# No migrations

namespace :deploy do
  task :migrate do; end
end


namespace :rubycas do
  desc "Make symlink for config.yml"
  task :symlink_config, :roles => [:app] do
    run "ln -nfs #{shared_path}/config/config.yml #{release_path}/config.yml"
  end
end
