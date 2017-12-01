# Cuddlefish

This is a gem for managing multiple database shards in a Rails application. Think [Octopus](https://github.com/thiagopradi/octopus), but simpler, and with support for using separate databases for different ActiveRecord models.

Let's say that your app has two databases — we'll call them `foo` and `bar` — sharded across two hosts. You'd have a `shards.yml` file like this (simplified for explanatory purposes):

```
development:
  - database: foo_production
    host: db1.example.com
    tags:
      - host_1
      - foo
  - database: bar_production
    host: db1.example.com
    tags:
      - host_1
      - bar
  - database: foo_production
    host: db2.example.com
    tags:
      - host_2
      - foo
  - database: bar_production
    host: db2.example.com
    tags:
      - host_2
      - bar
```

Then you can do something like this in your app:

```ruby
Cuddlefish.use_shard_tags(:host_1) do
  # your code here
end
```

...and all the code in that block will use the `foo` and `bar` databases on host 1. If you're using ActiveRecord's `establish_connection` to point particular models to a particular database, you can replace it with something like this in your model:

```ruby
class MyModel < ActiveRecord::Base
  set_shard_tags :bar
end
```

Then all that model's queries will be restricted to shards with the `bar` tag. Cuddlefish picks the connection to use by combining all the tags from block methods like `use_shard_tags` with the tags from the ActiveRecord model that's making the query. (If you give it a contradictory set of tags and there are no connections which match all those tags, it throws an exception. Similarly, if a query matches multiple possible connections, it throws an exception.)

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

Check out the example `shards.yml` file in this repository to see how to set up your shards. Then, in a file called `config/cuddlefish.rb`, call this to load all the shard data and hook Cuddlefish into ActiveRecord:
```ruby
Cuddlefish.start("shards.yml")
```
cuddlefish will load your `config/cuddlefish.rb` file at startup; you don't have to explicitly require it yourself.

## Usage

### Block-based methods

These are the easiest way to work with Cuddlefish. You pass these methods a block; which shard the queries inside the block use varies based on the arguments.

```ruby
# Restricts all ActiveRecord queries inside the block to shards with both
# the `global` and `shard1` tags.
Cuddlefish.use_shard_tags(:global, :shard1) do
  MyRecord.find(...)
end

# Restricts all ActiveRecord queries inside the block to shards with the
# `global` tag, ignoring any tag restrictions set outside the block by
# other Cuddlefish methods but honouring tags set on specific models by
# `set_shard_tags`.
Cuddlefish.replace_shard_tags(:global) do
  MyRecord.find(...)
end

# Restricts all ActiveRecord queries inside the block to shards with the
# `global` tag, ignoring any tag restrictions set outside the block by
# other Cuddlefish methods or by `set_shard_tags`.
Cuddlefish.force_shard_tags(:global) do
  MyRecord.find(...)
end

# Executes the block repeatedly, once for each tag you give it. Each time
# it's wrapped in a `use_shard_tags` call for that individual tag.
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

# Same as each_shard, but returns an array of every iteration's results.
Cuddlefish.map_shards do
  # do things
end
```

### Other methods

```ruby
# After this, all subsequent queries will be restricted by the :foo and :bar tags.
# Use with care.
Cuddlefish.add_shard_tags(:foo, :bar)

# Undoes the effect of a previous add_shard_tags. Use with care.
Cuddlefish.remove_shard_tags(:foo, :bar)

# Use this shard for all database queries that don't have a shard specified.
ActiveRecord::Base.default_shard_tags = [:my_default_shard]
```

### Migrations

Migrations are more complicated with sharding than they are with standard ActiveRecord because you have to decide which migrations will run on which shards. Cuddlefish lets you provide a `tags_for_migration` lambda which, when given an ActiveRecord::MigrationProxy, should return an array of tags indicating which shards that migration should happen on. For instance, given the sample `shards.yml` setup above, you might set up your `db/migrate` directory to look like this:

```
$ ls db/migrate
foo/    bar/
```

...where the `foo` subdirectory contains all the migrations which should be run on the `foo_production` databases, and the `bar` subdirectory contains all the migrations which should be run on the `bar_production` databases. You could set up `tags_for_migration` like this in your Rails app's initializers:

```ruby
Cuddlefish.tags_for_migration = lambda do |migration|
  if migration.filename !~ /\/(\w+)\/\w+\.rb$/
    raise "Badly-named or misplaced migration: #{migration.filename}"
  end
  [$1.to_sym]
end
```

Now your migrations in `foo/` will be run with the `[:foo]` tags, and likewise for `bar/`, so the migrations should happen on the correct servers.

## FAQ

#### Shouldn't it be "cuttlefish"?

No. It's a very physically affectionate fish.

## Development

This is currently a pre-pre-pre-alpha version that hasn't seen production yet. You might want to let us use this in production for a while before risking it yourself.

### TODO:

* Rename lots of things. The names are pretty bad.
* Improve the performance of looking up connections by tags, with an eye to generating minimal garbage. At present, it's about 12% slower at a simple "create a bunch of records on different shards" benchmarks compared to straight ActiveRecord; I bet we can get that under 10% without too much difficulty.

After checking out the repo, run `bin/setup` to install dependencies. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/fimmtiu/cuddlefish.

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
