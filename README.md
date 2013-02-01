# Insult

TODO: Write a gem description

## Installation

Add this line to your application's Gemfile:

    gem 'insult'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install insult

## Usage

```ruby
class Person
  def first_name
    "John"
  end

  def last_name
    "Smith"
  end

  def full_na)me
    "#{first_name} #{last_name}"
  end
end

person = Person.new
first_name_spy = Insult::Spy.on(person, :first_name)
person.first_name
first_name_spy.was_called? #=> true
```

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
