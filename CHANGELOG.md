# 0.0.5 (2012-03-12)

## Changes

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

