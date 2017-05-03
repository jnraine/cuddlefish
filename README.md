# Cuddlefish

This is a gem for managing multiple database shards in a Rails application. Think [Octopus](https://github.com/thiagopradi/octopus), but simpler, and with support for using different databases for different ActiveRecord models.

Let's say that your app has two databases — we'll call them `foo` and `bar` — sharded across two hosts. You'd have a `shards.yml` file like this (simplified for explanatory purposes):

```
shards:
  - database: foo_production
    tags:
      - host_1
      - foo
  - database: bar_production
    tags:
      - host_1
      - bar
  - database: foo_production
    tags:
      - host_2
      - foo
  - database: bar_production
    tags:
      - host_2
      - bar
```

Then you can do something like this in your app:

```ruby
Cuddlefish.with_shard_tags(:host_1) do
  # your code here
end
```

...and all the code in that block will use the `foo` and `bar` databases on host 1. If you're using ActiveRecord's `establish_connection` to point particular models to a particular database, you can replace it with something like this in your model:

```ruby
include Cuddlefish::ActiveRecord
set_shard_tags :bar
```

Then all that model's queries will be restricted to shards with the `bar` tag. Cuddlefish picks the connection to use by combining all the tags from block methods like `with_shard_tags` with the tags from the ActiveRecord model that's making the query. (If you give it a contradictory set of tags and there are no connections which match all those tags, it throws an exception. Similarly, if a query matches multiple possible connections, it throws an exception.)

The code is fairly small and straightforward, so you can see how it works without too much brain-bending.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'cuddlefish'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install cuddlefish

## Configuration

FIXME: Configuration instructions

## Usage

```ruby
Cuddlefish.load_config_file("shards.yml")

# Restricts all ActiveRecord queries inside the block to shards with both
# the `global` and `shard1` tags.
Cuddlefish.with_shard_tags(:global, :shard1) do
  MyRecord.find(...)
end

# Restricts all ActiveRecord queries inside the block to shards with the
# `global` tag, ignoring any tag restrictions set outside the block by
# other Cuddlefish methods.
Cuddlefish.with_exact_shard_tags(:global) do
  MyRecord.find(...)
end

# Executes the block repeatedly, once for each tag you give it. Each time
# it's wrapped in a `with_shard_tags` call for that individual tag.
# Useful for performing a task on multiple connections at once.
Cuddlefish.each_tag(:shard_1, :shard_2) do
  # do things
end

# Executes the block repeatedly, once for each shard defined in your
# shards.yml. Each time, all queries within the block will be directed to a
# particular database shard.
Cuddlefish.each_shard do
  # do things
end
```

## FAQ

#### Shouldn't it be "cuttlefish"?

No. It's a very physically affectionate fish.

## Development

This is currently a pre-pre-pre-alpha version that hasn't seen production yet. You might want to let us use this in production for a while before risking it yourself.

### TODO:

* Rename lots of things. The names are pretty bad.
* Remove unnecessary code left in from early development.
* Do a much better job of commenting the code.
* Support for migrations!
* Improve the performance of looking up connections by tags, with an eye to generating minimal garbage.

After checking out the repo, run `bin/setup` to install dependencies. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/fimmtiu/cuddlefish.

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
