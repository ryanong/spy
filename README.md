# Spy

[![Gem Version](https://badge.fury.io/rb/spy.png)](http://badge.fury.io/rb/spy)
[![Build Status](https://travis-ci.org/ryanong/spy.png?branch=master)](https://travis-ci.org/ryanong/spy)
[![Coverage Status](https://coveralls.io/repos/ryanong/spy/badge.png?branch=master)](https://coveralls.io/r/ryanong/spy)


[Docs](http://rdoc.info/gems/spy/frames)

Spy is a lightweight stubbing framework with support for method spies, constant stubs, and object mocks.

Spy supports ruby 2.1.0+.
For versions less than 2.1 use v0.4.5

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
* no argument matchers for `Spy::Subroutine#has_been_called_with`
* cannot watch all calls to an object to check order in which they are called
* cannot transfer nested constants when stubbing a constant
  * i don't think anybody uses this anyway
  * nobody on github does
* #with is not supported
  * you can usually just check the call logs.
  * if you do need to use this. It is probably a code smell. You either need to abstract your method more or add separate tests.
* you want to use dumb double, Spy has smart mocks, they are better
* you use `mock_model` and `stub_model` (I want to impliment this soon)

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
Spy::Subroutine.new(book, :flamethrower).hook(force:true).and_return("burnninante")
```

You can also stub instance methods of Classes and Modules. This is equivalent to
rspec-mock's `Module#any_instance`

```ruby
Spy.on_instance_method(Book, :title).and_return("Cannery Row")

Book.new(title: "Siddhartha").title   #=> "Cannery Row"
Book.new(title: "The Big Cheese").title   #=> "Cannery Row"
```

### Test Mocks

A test mock is an object that quacks like a given class but will raise an error
when the method is not stubbed. Spy will not let you stub a method that wasn't
on the mocked class. You can spy on the classes and call through to the original method.

```ruby
book = Spy.mock(Book) # Must be a class
Spy.on(book, first_name: "Neil", last_name: "Gaiman")
Spy.on(book, :author).and_call_through
book.author #=> "Neil Gaiman"

book.responds_to? :title #=> true
book.title #=> Spy::NeverHookedError: 'title' was never hooked on mock spy.
```

To stub methods during instantiation just add arguments.

```ruby
book = Spy.mock(Book, :first_name, author: "Neil Gaiman")
```

### Arbitrary Handling

If you need to have a custom method based in the method inputs just send a block to `#and_return`

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
validator = Spy.mock(Validator)
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
If you just want to make sure if a method is called and not override the output you can just use the `#and_call_through` method

```ruby
Spy.on(book, :read_page).and_call_through
```

By if the original method never existed it will call `#method_missing` on the spied object.

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

## Test Framework Integration

### MiniTest/TestUnit

in your `test_helper.rb` add this line after you include your framework

```ruby
require 'spy/integration'
```

In your test file

```ruby
  def test_title
    book = Book.new
    title_spy = Spy.on(book, :title)
    book.title
    book.title

    assert_received book, :title

    assert title_spy.has_been_called?
    assert_equal 2, title_spy.calls.count
  end
```

### Rspec

In `spec_helper.rb`

```ruby
require "rspec/autorun"
require "spy/integration"
RSpec.configure do |c|
  c.mock_with Spy::RspecAdapter
end
```

In your test

```ruby
describe Book do
  it "title can be called" do
    book = book.new
    page_spy = Spy.on(book, page)
    book.page(1)
    book.page(2)

    expect(book).to have_received(:page)
    expect(book).to have_received(:page).with(1)
    expect(book).to have_received(:page).with(2)

    expect(page_spy).to have_been_called
    expect(page_spy.calls.count).to eq(2)
  end
end
```

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
