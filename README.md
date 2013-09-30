faas-lib-ruby
=============

Faas ruby gem: Simplified access to cloud services

## Usage

In your `Gemfile`, add the following:
```ruby
gem 'faas'
```

Then configure your app like so:
```ruby
Faas.config do |config|
  config.api_key = ENV['FAAS_API_KEY']
  config.api_secret = ENV['FAAS_API_SECRET']
end
```

If you're using Rails, this probably goes most naturally in a file `config/initializers/faas.rb`,
with the appropriate environment settings
(take a look at [foreman](https://github.com/ddollar/foreman) for help with this).

