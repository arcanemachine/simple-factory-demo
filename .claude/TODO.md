# FactoryMan TODO

## Current Work

### Hook Super Call Feature
**Goal:** Allow factory-level hooks to call the base (module-level) hook before/after applying custom logic

**Current behavior:**
- Factory-level hooks completely override module-level hooks (line 241 in `lib/factory_man.ex`)
- `Keyword.merge(module_hooks, factory_hooks || [])` replaces, doesn't compose

**Desired API:**
```elixir
factory :user do
  build do
    %User{username: Map.get(params, :username, "default")}
  end

  hooks do
    [
      after_build: fn user, base_hook ->
        user = base_hook.(user)  # Call module-level hook first
        %{user | username: String.upcase(user.username)}  # Then custom logic
      end
    ]
  end
end
```

**Implementation plan:**

1. **Modify hook merge logic** (`lib/factory_man.ex:239-241`):
   - Instead of simple `Keyword.merge`, wrap factory hooks to receive base hook as second parameter
   - For each factory hook, look up corresponding module hook
   - Create a wrapper that calls factory hook with `fn value -> factory_hook.(value, module_hook) end`

2. **Update hook invocation** (`lib/factory_man.ex:250-252, 259-261`):
   - Hook handlers already retrieved via `get_hook_handler/2`
   - Wrapped hooks should accept 1 or 2 arguments (detect arity)
   - If arity 2, pass base hook; if arity 1, call as-is (backwards compatible)

3. **Test implementation** (`test/support/factories/users.ex:15-22`):
   - Update existing custom hook to use 2-arity form
   - Verify base hook (module-level `after_insert`) still executes

**Files to modify:**
- `lib/factory_man.ex:239-241` - Hook merge logic
- `lib/factory_man.ex:250-252, 259-261` - Hook invocation points
- `test/support/factories/users.ex:15-22` - Test case

## Backlog

- Uncomment other factories (authors, posts, tags) after super call feature complete
- Documentation for multi-block syntax and super call pattern
