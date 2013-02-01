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
person_spy = Spy(person)
first_name_spy = person_spy.on(:first_name).and_callthrough
person.full_name
person_spy.must have_received(:first_name).with()
first_name_spy.must have_been_called



```

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
