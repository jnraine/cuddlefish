require "bundler/gem_tasks"
import "lib/tasks/db.rake"

task :default => :spec

task :spec do
  exec("rspec")
end

task :rerun do
  exec("rerun --ignore \"coverage/*\" rspec")
end
