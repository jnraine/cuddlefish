require "bundler/gem_tasks"
task :default => :spec

task :spec do
  exec("rspec")
end

task :rerun do
  exec("rerun --ignore \"coverage/*\" rspec")
end
