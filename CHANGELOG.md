### 0.1.5 (2012-11-01)
#### Fixes
* Add attr_accessible for Auditable::Audit model [#13]

### 0.1.4 (2012-11-01)
#### Improvement
* Add class_name option for method audit. This allows you to have a custom audit class that inherits from Auditable::Audit [#12]

### 0.1.3 (2012-05-24)
#### Fixes
* Fix a silly bug not loading the audits under the same `auditable_id`
* Get the latest audit via `id DESC` instead of `created_at DESC`

### 0.1.2 (2012-05-24)
#### Fixes
* Fix bug creating duplicate audits despite no change in a record's subsequent saves, due to using `.build`. See this comment on [issue #7](https://github.com/harleyttd/auditable/issues/7#issuecomment-5520894)
* Fix bug not finding the right audit in rare cases when there are many audits with the same `created_at` timestamp

### 0.1.1 (2012-04-11)
#### Fixes
* Fix bug/inconsistency between `user` and `changed_by`, now with `alias_attribute :changed_by, :user`

### 0.1.0 (2012-04-11)
#### Changes
* previously, `audit_tag_with` updates the latest audit if no changes are detected in a record's audited changes. now it creates a new audit row instead because this works better and prevent losing history if we call `audit_tag_with` multiple times. new audits are only created if the combo of 4 attributes is different: `modifications`, `tag`, `user`, `action`.
* bump minor version because it is more ready for production use at this point

### 0.0.9 (2012-04-10)
#### Improvement
* Add `last_change_of(attribute)` to show the last change that happened to an attribute. Thanks to @zuf

### 0.0.8 (2012-03-24)
#### Fixes
* Fix 'Could not find generator auditable:migration' bug due to a refactoring that moved `generators` out of the `/lib` folder. Moved it back

### 0.0.7 (2012-03-13)
#### Improvement
* Only create a new audit if `modifications` differ from last audit

### 0.0.6 (2012-03-12)
#### Fixes
* Fix error when calling `audit_tag_with` on a record without audits and without `audit_tag` virtual attribute defined.

#### Changes
* `.changed_by`, `.audit_tag`, `.audit_action` virtual attributes are now added to the auditable model by default. The extra check `respond_to?` on these guys is just cumbersome to carry along.

### 0.0.5 (2012-03-12)
#### Changes
Easier to explain with code

    # Given
    >> s = Survey.create :title => "something"
    >> s.audits.delete_all

    # Before 0.0.5
    >> s.audit_tag_with("some tag") # do nothing when no audits exist
    >> s.audits.empty? # => true

    # From 0.0.5 onwards
    >> s.audit_tag_with("some tag") # create an audit with tag if no audits exist
    >> s.audits.first.tag == "some tag"

