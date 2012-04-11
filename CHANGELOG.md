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

