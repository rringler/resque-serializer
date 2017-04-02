# Resque::Serializer

A Resque plugin which ensures for a given queue, that only one worker is executing a job at any given time.

It is slightly more flexible than [Resque::LonelyJob](https://github.com/wallace/resque-lonely_job).

This gem may be helpful to avoid database lock contention.


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

### TLDR
```
|  Lock Lifetime | :queue | :job  | :both  | :combined |
| -------------: | :----: | :---: | :----: | :-------: |
| before_enqueue |    ✓   |       |  ✓     |     ✓     |
|        enqueue |    |   |       |  |     |     |     |
|  after_enqueue |    |   |       |  |     |     |     |
| before_dequeue |    |   |   ✓   |  |  ✓  |     |     |
|        dequeue |    |   |   |   |  |  |  |     |     |
|  after_dequeue |    ✗   |   |   |  ✗  |  |     |     |
| before_perform |        |   |   |     |  |     |     |
|        perform |        |   |   |     |  |     |     |
|  after_perform |        |   ✗   |     ✗  |     ✗     |
```

### Example #1 -- Serializing the queue

```ruby
require 'resque-serializer'

class SerializedJob
  extend Resque::Plugins::Serializer

  @queue = :default

  serialize :queue

  def self.perform
    # work
  end
end
```

Only one of job with identical arguments will be allowed to be queued at a time. As soon as the job is dequeued to begin executing, an identical job may be queued (and may begin executing.)


### Example #2 -- Serializing the job

```ruby
require 'resque-serializer'

class SerializedJob
  extend Resque::Plugins::Serializer

  @queue = :default

  serialize :job

  def self.perform
    # work
  end
end
```

Any number of these jobs may be queued, but only one job with identical arguments will be executed at a time. As soon as the executing job is completed, another queued job may be dequeued to execute.


### Example #3 -- Serializing both the queue & job (independently)

```ruby
require 'resque-serializer'

class SerializedJob
  extend Resque::Plugins::Serializer

  @queue = :default

  serialize :both

  def self.perform
    # work
  end
end
```

A combination of the first two examples; both the queue and the execution of identical jobs is serialized (independently.) An additional job may be queued if no identical job exists in the queue. Similarly, an additional job may begin executing if no identical job is currently executing.


### Example #4 -- Serializing both the queue & job (combined)

```ruby
require 'resque-serializer'

class SerializedJob
  extend Resque::Plugins::Serializer

  @queue = :default

  serialize :combined

  def self.perform
    # work
  end
end
```

Also a combination of the first two examples; both the queue and execution of identical jobs is serialized (together.) An additional job may not be queued if an identical job exists in the queue or execution.


## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Added some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

