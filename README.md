# Spy

Spy is a lightweight stubbing framework that won't let your code mock your intelligence.

Spy was designed for 1.9.3+ so there is no legacy tech debt.

Spy features that were completed were tested against the rspec-mocks tests so it covers all cases that rspec-mocks does.

Inspired by the spy api of the jasmine javascript testing framework.

## Why use this instead of rspec-mocks, mocha, or etc

* Spy will raise error when you try to stub/spy a method that doesn't exist
  * when you change your method name your unit tests will break
  * no more fantasy tests
* Spy arity matches original method
  * Your tests will raise an error if you use the wrong arity
* Spy visibility matches original method
  * Your tests will raise an error if you try to call the method incorrectly
* Simple call log api
  * easier to read tests
  * use ruby to test ruby instead of a dsl
* no expectations
  * really who thought that was a good idea?
* absolutely no polution of global object space
* no polution of instance variables for stubbed objects

Fail faster, code faster.

## Why not to use this

* Api is not stable
* missing these features
  * Spy::Method#and\_raise
  * Spy::Method#with
    * this kind of mocking seems like a smell
  * Spy::Constants
  * Spy.on\_any\_instance\_of
    * this kind of mocking seems like a smell
  * argument matchers for Spy::Method#has\_been\_called\_with
  * watch all calls to an object to check order in which they are called?
    * is this useful?
  * fail lazily on method call not on hook to allow for dynamic method creation?
    * do more than 0.5% of develoeprs use this?

## Installation

Add this line to your application's Gemfile:

    gem 'spy'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install spy

## Usage

```ruby
class Person
  def first_name
    "John"
  end

  def last_name
    "Smith"
  end

  def full_name
    "#{first_name} #{last_name}"
  end

  def say(words)
    puts words
  end
end
```

### Standalone

```ruby
person = Person.new

first_name_spy = Spy.on(person, :first_name)
person.first_name            #=> nil
first_name_spy.has_been_called?       #=> true

Spy.get(person, :first_name) #=> first_name_spy

Spy.off(person, :first_name)
person.first_name          #=> "John"

first_name_spy.hook        #=> first_name_spy
first_name_spy.and_return("Bob")
person.first_name          #=> "Bob"

Spy.teardown
person.first_name #=> "John"

say_spy = Spy.on(person, :say)
person.say("hello") {
  "everything accepts a block in ruby"
}
say_spy.say("world")

say_spy.has_been_called? #=> true
say_spy.has_been_called_with?("hello") #=> true
say_spy.calls.count               #=> 1
say_spy.calls.first.args          #=> ["hello"]
say_spy.calls.last.args           #=> ["world"]

call_log = say_spy.calls.first
call_log.object     #=> #<Person:0x00000000b2b858>
call_log.args       #=> ["hello"]
call_log.block      #=> #<Proc:0x00000000b1a9e0>
call_log.block.call #=> "everything accepts a block in ruby"
```

### MiniTest

```ruby
require "spy"
MiniTest::TestCase.add_teardown_hook { Spy.teardown }
```

### Rspec

In spec\_helper.rb

```ruby
require "rspec/autorun"
require "spy"
RSpec.configure do |c|
  c.before { Spy.teardown  }
end
```

### Test::Unit

```ruby
require "spy"
class Test::Unit::TestCase
  def setup
    Spy.teardown
  end
end
```

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
