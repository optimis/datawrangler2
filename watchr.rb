puts "\n### Watching specs ... ###\n"
 
def cmd() 'bundle exec rspec '; end
 
def run_all_specs
  system(cmd + 'spec/')
end
 
def run_spec(spec)
  puts "Running #{spec}"
  system(cmd + spec)
  puts
end

watch('^spec\/.*_spec\.rb') {|md| run_spec(md[0]) }
watch('spec/spec_helper.rb') {|md| run_all_specs }
watch('^lib/(.*)\.rb') {|md| run_spec("spec/lib/#{md[1]}_spec.rb")}
watch('^(\w*)\.rb') {|md| run_spec("spec/#{md[1]}_spec.rb")}

# Ctrl-\
Signal.trap('QUIT') do
 puts "\n### Running all specs and features ###\n"
 run_all_specs
 run_all_features
 puts
end
       
# Ctrl-C
Signal.trap('INT') { abort("\n") }
