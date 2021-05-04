A reflex to construct a form that wraps a `has_many` relationship with nested attributes on the fly.

**How?**
- New children are instantiated by calling `.build` on the `has_many` association
- `fields_for` expands to all children if a `child_attributes=` setter is present (which is the case if `accepts_nested_attributes_for` is set) - see [API docs](https://api.rubyonrails.org/classes/ActionView/Helpers/FormBuilder.html#method-i-fields_for)

**Caveat**

Clean up your session (or other persistent store) after form submission.