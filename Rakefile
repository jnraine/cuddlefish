require "bundler/gem_tasks"
import "lib/tasks/db.rake"

task :default => :rerun

task :rerun do
  # Use consistent seed each rerun to avoid transient failures
  exec("rerun -x --ignore \"coverage/*\" \"rspec --seed #{rand(10000)}\"")
end
