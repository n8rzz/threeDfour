## Bundler configuration
guard :bundler do
  require 'guard/bundler'
  require 'guard/bundler/verify'
  helper = Guard::Bundler::Verify.new

  files = [ 'Gemfile' ]
  files += Dir['*.gemspec'] if files.any? { |f| File.exist?(f) }

  # Assume files are symlinked from somewhere
  files.each { |file| watch(helper.real_path(file)) }
end

## RSpec configuration
guard :rspec, cmd: 'bundle exec rspec' do
  # RSpec files
  watch('spec/spec_helper.rb')  { 'spec' }
  watch('spec/rails_helper.rb') { 'spec' }
  watch(%r{^spec/.+_spec.rb$})

  # Ruby files
  watch(%r{^app/(.+).rb$}) { |m| "spec/#{m[1]}_spec.rb" }
  watch(%r{^lib/(.+).rb$}) { |m| "spec/lib/#{m[1]}_spec.rb" }

  # Rails files
  watch(%r{^app/controllers/(.+)_controller.rb$}) do |m|
    [
      "spec/routing/#{m[1]}_routing_spec.rb",
      "spec/controllers/#{m[1]}_controller_spec.rb",
      "spec/system/#{m[1]}_spec.rb"
    ]
  end

  # Models
  watch(%r{^app/models/(.+).rb$}) do |m|
    [
      "spec/models/#{m[1]}_spec.rb",
      "spec/system"
    ]
  end

  # Views - handle both nested and non-nested views
  watch(%r{^app/views/(.+)/(.+).html.erb$}) do |m|
    [
      "spec/system/#{m[1]}_spec.rb",
      "spec/system/#{m[2]}_spec.rb",
      "spec/views/#{m[1]}/#{m[2]}_spec.rb"
    ]
  end

  # Devise views specifically
  watch(%r{^app/views/devise/(.+)/(.+).html.erb$}) do |m|
    [
      "spec/system/authentication_spec.rb",
      "spec/system/#{m[1]}_spec.rb"
    ]
  end

  # Layouts
  watch(%r{^app/views/layouts/.*.html.erb$}) { "spec/system" }

  # Partials - handle both nested and non-nested partials
  watch(%r{^app/views/(.+)/_[^/]+.html.erb$}) do |m|
    [
      "spec/system/#{m[1]}_spec.rb",
      "spec/views/#{m[1]}_spec.rb"
    ]
  end

  # Shared partials
  watch(%r{^app/views/shared/_.*.html.erb$}) { "spec/system" }

  # Rails config changes
  watch('config/routes.rb')          { "spec/routing" }
  watch('app/controllers/application_controller.rb') { "spec/controllers" }
end
