notification :terminal_notifier

guard 'bundler' do
  watch('Gemfile')
  # Uncomment next line if Gemfile contain `gemspec' command
  # watch(/^.+\.gemspec/)
end

guard 'minitest' do
  # with Minitest::Spec
  watch(%r|^spec/spec\.rb|)           { "spec" }
  watch(%r|^spec/(.*)_spec\.rb|)
  watch(%r|^lib/(.*)([^/]+)\.rb|)     { |m| "spec/#{m[1]}#{m[2]}_spec.rb" }
  watch(%r|^spec/spec_helper\.rb|)    { "spec" }
  watch(%r|^qdbase\.rb|)              { "spec" }
end
