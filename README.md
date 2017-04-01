# Resque::Serializer

A Resque plugin which ensures for a given queue, that only one worker is executing a job at any given time.

Resque::Serializer differs from [Resque::LonelyJob](https://github.com/wallace/resque-lonely_job) in that additional jobs may be enqueued while the job is executing.


## Installation

Add this line to your application's Gemfile:

```ruby
gem 'resque-serializer'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install resque-serializer


## Usage

### Example #1 -- One job running per queue

```ruby
require 'resque-lonely_job'

class SerializedJob
  extend Resque::Plugins::Serializer

  @queue = :default

  def self.perform
    # only one at a time in this block, no parallelism allowed for this
    # particular queue
  end
end
```

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Added some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

