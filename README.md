# Auditable

[![Build Status](https://secure.travis-ci.org/harleyttd/auditable.png?branch=master)](http://travis-ci.org/harleyttd/auditable)

There are a lot of gems under https://www.ruby-toolbox.com/categories/Active_Record_Versioning and https://www.ruby-toolbox.com/categories/Active_Record_User_Stamping but there are various issues with them (as of this writing):

* Almost all of them are outdated and not working with Rails 3.2.2. Some of the popular ones such as `papertrail` and `vestal_versions` have many issues and pull requests but haven't been addressed or merged. Based on the large number of forks of these popular gems, people seem to be OK with their own gem tweaks. Some tweaks are good, but some are too hackish (to deal with recent Rails changes) based on the commits that I have read. I have tried some of the more popular ones but they don't work reliably for something simple I'm trying to achieve.
* Many of these gems have evolved overtime and become rather (very) cumbersome.
* Most or all of them don't seem to support beyond the database columns, i.e. not working (or working well) with virtual methods or associations. `papertrail` supports `has_one` but the author said it's not easy to go further than that.
* I need something simple and lightweight.

A lot of the gems in the above category are great. I'm just aiming to create a dead simple gem that lets you easily diff the changes on a model's attributes or methods. Yes, methods, not just attributes. Here's the key difference in my approach:

If you want to track changes to complicated stuff such as associated records, just define a method that returns some representation of the associated records and let `auditable` keeps track of the changes in those values over time.

Basically:

* I don't want the default to track all my columns. Only the attributes or methods I specify please.
* I don't want to deal with association mess. Use methods instead.
* I care about tracking the values of certain virtual attributes or methods, not just database columns
* I want something simple, similar to [ActiveRecord::Dirty#changes](http://ar.rubyonrails.org/classes/ActiveRecord/Dirty.html#M000291) but persistent across saves. See the usage of {Auditable::Auditing#audited_changes} below.

See examples under {file:README.md#Usage Usage} section. Please check the {file:CHANGELOG.md} as well.

## Installation

Add this line to your application's Gemfile:

    gem 'auditable'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install auditable

## Usage

First, add the necessary `audits` table to your database with:

    rails generate auditable:migration
    rake db:migrate

Then, provide a list of methods you'd like to audit to the `audit` method in your model.

    class Survey
      has_many :questions
      attr_accessor :current_page

      audit :title, :current_page, :question_ids
    end

## Demo

I'm going to demo with the test models from the test suite. You probably want to use 'rails console' and test with the model that you want to audit.

For more details, I suggest you check out the test examples in the `spec` folder itself.

    $ bundle console
    >> require(File.expand_path "../spec/spec_helper", __FILE__)
    => true

    >> s = Survey.create :title => "demo"
    => #<Survey id: 1, title: "demo">

    >> Survey.audited_attributes
    => [:title, :current_page]

    >> s.audited_changes
    => {"title"=>[nil, "demo"]}

    >> s.update_attributes(:title => "new title", :current_page => 2)
    => true

    >> s.audited_changes
    => {"title"=>["demo", "new title"], "current_page"=>[nil, 2]}

    >> s.update_attributes(:current_page => 3, :action => "modified", :changed_by => User.create(:name => "someone"))
    => true

    >> s.audited_changes
    => {"current_page"=>[2, 3]}

    >> s.audits.last
    => #<Auditable::Audit id: 3, auditable_id: 1, auditable_type: "Survey", user_id: 1, user_type: "User", modifications: {"title"=>"new title", "current_page"=>3}, action: "modified", created_at: ...>

    >> s.audit_tag_with("something memorable")
       # we just tagged the latest audit, now then do make changes with s
       # ...
       # assuming you've made some changes to s

    >> s.audited_changes(:tag => "something memorable")
       # return the changes against the tagged version above
       # note s.audited_changes still diff against the second latest audit
       # you can also pass in other filters, such as s.audited_changes(:changed_by => some_user, :audit_action => "modified")
       # note that it always uses the latest audit to diff against an earlier audit matching the arguments to audited_changes

## How it works
### Audit Model

As seen above, I intend to have a migration file like this for the Audit model:

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

It guessable from the above that `audits.modifications` will just be a serialized representation of keys and values of the audited attributes.

### Who changed it and what was that action?

If you want to store the user who made the changed to the record, just assigned it to the record's `changed_by` attribute, like so:

    # note `attr_accessor :changed_by` is defined in your Survey class by the gem
    >> @survey.update_attributes(:changed_by => current_user, # and other attributes you want to set)
    # then @surveys.audits.last.user will be set to current_user
    # also works when you set changed_by and call save later, of course

`action` will just be `create` or `update` depending on the operation on the record, but you can also override it with another virtual attribute, call it `change_action`

    >> @survey.changed_action = "add page"
    >> @survey.update_attribute :page_count, 2

That's all I can do for this README Driven approach. Back soon.

## TODO

* **Don't store a new row in the `audits` table if the `modifications` column is the same as the one immediately before it. This makes it easier to review change**
* improve api (still clumsy) -- come up with better syntax
* get some suggestions and feedback
* update README

e.g. right now, changes are serialized into `audits.modifications` column, but what if we what to do multiple sets of audits at each save. I'm thinking of supporting syntax like this:

    # store snapshots of certain methods to audits.trivial_changes column (that you can easily add yourself)
    audit :modifications => [:method_1, :method_2], :trivial_changes => [:method_3, :method_4, :method_5]

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Added some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

## CHANGELOG

{include:file:CHANGELOG.md}
