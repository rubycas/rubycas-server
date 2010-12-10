require 'bundler'
namespace :bundler do
  Bundler::GemHelper.install_tasks(:name => 'rubycas-server')
end
