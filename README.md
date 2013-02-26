# Spy [![Build Status](https://travis-ci.org/ryanong/spy.png?branch=master)](https://travis-ci.org/ryanong/spy) [![Gem Version](https://badge.fury.io/rb/spy.png)](http://badge.fury.io/rb/spy)

Spy is a lightweight stubbing framework with support for method spies, constant stubs, and object doubles.

Spy was designed for 1.9.3+.

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

* mocking null objects is not supported(yet)
* no argument matchers for Spy::Method#has\_been\_called\_with
* cannot watch all calls to an object to check order in which they are called
* cannot transfer nested constants when stubbing a constant
  * i don't think anybody uses this anyway
  * nobody on github does
* #with is not supported
  * you can usually just check the call logs.
  * if you do need to use this. It is probably a code smell. You either need to abstract your method more or add separate tests.

## Installation

Add this line to your application's Gemfile:

    gem 'spy'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install spy

## Usage

### Method Stubs

A method stub overrides a pre-existing method and records all calls to specified method. You can set the spy to return either the original method or your own custom implementation.

Spy support 2 different ways of spying an existing method on an object.

```ruby
Spy.on(book, title: "East of Eden")
Spy.on(book, :title).and_return("East of Eden")
Spy.on(book, :title).and_return { "East of Eden" }

book.title  #=> "East of Eden"
```

Spy will raise an error if you try to stub on a method that doesn't exist.
You can force the creation of a stub on method that didn't exist but it really isn't suggested.

```ruby
Spy.new(book, :flamethrower).hook(force:true).and_return("burnninante")
```

You can also stub instance methods of Classes and Modules

```ruby
Spy.on_instance_method(Book, :title).and_return("Cannery Row")

Book.new(title: "Siddhartha").title   #=> "Cannery Row"
Book.new(title: "The Big Cheese").title   #=> "Cannery Row"
```

### Test Doubles

A test double is an object that stands in for a real object.

```ruby
Spy.double("book")
```

Spy will let you stub on any method even if it doesn't exist if the object is a double.

Spy comes with a shortcut to define an object with methods.

```ruby
Spy.double("book", title: "Grapes of Wrath", author: "John Steinbeck")
```

### Arbitrary Handling

If you need to have a custom method based in the method inputs just send a block to #and\_return

```ruby
Spy.on(book, :read_page).and_return do |page, &block|
  block.call
  "awesome " * page
end
```

An error will raise if the arity of the block is larger than the arity of the original method. However this can be overidden with the force argument.

```ruby
Spy.on(book, :read_page).and_return(force: true) do |a, b, c, d|
end
```

### Method Spies

When you stub a method it returns a spy. A spy records what calls have been made to a given method.

```ruby
validator = Spy.double("validator")
validate_spy = Spy.on(validator, :validate)
validate_spy.has_been_called? #=> false

validator.validate("01234")   #=> nil
validate_spy.has_been_called? #=> true
validate_spy.has_been_called_with?("01234") #=> true
```

You can also retrieve a method spy on demand

```ruby
Spy.get(validator, :validate)
```

### Calling through
If you just want to make sure if a method is called and not override the output you can just use the and\_call\_through method

```ruby
Spy.on(book, :read_page).and_call_through
```

By if the original method never existed it will call #method\_missing on the spied object.

### Call Logs

When a spy is called on it records a call log. A call log contains the object it was called on, the arguments and block that were sent to method and what it returned.

```ruby
read_page_spy = Spy.on(book, read_page: "hello world")
book.read_page(5) { "this is a block" }
book.read_page(3)
book.read_page(7)
read_page_spy.calls.size #=> 3
first_call = read_page_spy.calls.first
first_call.object #=> book
first_call.args   #=> [5]
first_call.block  #=> Proc.new { "this is a block" }
first_call.result #=> "hello world"
first_call.called_from #=> "file_name.rb:line_number"
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
  c.after { Spy.teardown  }
  c.mock_with :absolutely_nothing
end
```

### Test::Unit

```ruby
require "spy"
class Test::Unit::TestCase
  def teardown
    # if you don't add super to every teardown then you will have to add this
    # line to every file.
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
