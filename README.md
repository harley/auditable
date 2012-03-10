# Auditable

There are a lot of gems under https://www.ruby-toolbox.com/categories/Active_Record_Versioning and https://www.ruby-toolbox.com/categories/Active_Record_User_Stamping but there are various issues with them (as of this writing):

* Almost all of them are outdated and not working with Rails 3.2.2. Some of the popular ones such as `papertrail` and `vestal_versions` have many issues and pull requests but haven't been addressed or merged. Based on the large number of forks of thee popular gems, people seem to be OK with their own gem tweaks. Some tweaks are good, but some are too hackish. I couldn't figure out whose fork should be the most reliable to use.
* Many of these gems have evolved overtime and become rather cumbersome. Heck, even to support both Rails 2 and Rails 3 makes it some quite bloated.
* Most or all of them don't seem to support beyond the database columns, i.e. not working (or working well) with virtual methods or associations. `papertrail` supports `has_one` but that seems to be it.
* I need something simple and lightweight.

A lot of the gems in the above category are great and I draw inspirations from them. I'm just attempting to create a dead simple gem that lets you easily diff the changes on a model's attributes or methods. Yes, methods. Here's the FIRST difference in my approach:

Rule #1: If you want to track changes to complicated stuff such as associated records, just define a method that returns some representation of the associated records and let `auditable` keeps track of the changes in those values over time. See examples under Usage section.

## Installation

Add this line to your application's Gemfile:

    gem 'auditable'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install auditable

## Usage

Provide a list of methods you'd like to audit to the `audit` method in your model.

```ruby
class Survey
  has_many :questions

  audit :page_count, :question_ids
end
```

Now in a Rails console (I'm actually almost making the following up, because I haven't even written the gem code yet at this point -- to be updated later)

```
>> s = Survey.create! :title => "test"
=> #<Survey id: 1, title: "test", ...>
>> s.audits
=> [#<Auditable::Audit id: 1, auditable_id: 1, auditable_type: "Survey", user_id: nil, user_type: nil, modifications: {"page_count"=>1, "question_ids"=>[]}, action: "create", created_at: ...]
>> s.questions.create! :title => "q1"
>> s.audits
=> [#<Auditable::Audit id: 2, auditable_id: 1, auditable_type: "Survey", user_id: nil, user_type: nil, modifications: {"page_count"=>1, "question_ids"=>[1]}, action: "create", created_at: ...]
>> s.questions.create! :title => "q2"
>> s.audits
=> [#<Auditable::Audit id: 3, auditable_id: 1, auditable_type: "Survey", user_id: nil, user_type: nil, modifications: {"page_count"=>1, "question_ids"=>[1, 2]}, action: "create", created_at: ...]
>> s.update_attribute :page_count, 2
>> s.audits.last.diff(s.audits.first)
=> {"page_count" => [1, 2], "question_ids" => [[], [1,2]]}
```

### Audit Model

As seen above, I intend to have a migration file like this for the Audit model:

```ruby
class CreateAudits < ActiveRecord::Migration
  def change
    create_table :audits do |t|
      t.belongs_to :auditable, :polymorphic => true
      t.belongs_to :user, :polymorphic => true
      t.text :modifications
      t.string :action
      t.timestamps
    end
  end
end
```

It guessable from the above that `audits.modifications` will just be a serialized representation of keys and values of the audited attributes. How do I store stuff to `audits.user` and `audits.action`?

Rule #2: If you want to store the user who made the changed to the record, just assigned it to the record's `changed_by` attribute, like so:

```ruby
# note you have to define `attr_accessor :changed_by` yourself
>> @survey.changed_by = current_user
>> @survey.questions << Question.create :title => "How are you?"
# then @surveys.audits.last.user will be set to current_user
```

`action` will just be `create` or `update` depending on the operation on the record, but you can also override it with another virtual attribute, call it `change_action`

```ruby
>> @survey.changed_action = "add page"
>> @survey.update_attribute :page_count, 2
```

Rule #3: Don't store a new row in `audits` table if the `modifications` column is the same as the one immediately before it. This is to make you review the changes more easily

That's all I can do for this README Driven approach. Back soon.

## TODO

* code it
* test it
* update readme
* come up with a better syntax

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Added some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
