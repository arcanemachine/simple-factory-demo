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

**IMPORTANT:** Research `defoverridable` and `super` - these are Elixir's native mechanisms for this pattern:
- `defoverridable` makes functions overridable in child modules
- `super` calls the overridden version from parent
- This is the idiomatic Elixir way to do inheritance/extension

**Approach 1: Using defoverridable (preferred if possible):**
1. Have module-level hooks define overridable functions in the module
2. Factory-level hooks override those functions and can call `super`
3. Investigate if this works with the current macro-generated functions

**Approach 2: Manual composition (fallback):**
1. **Modify hook merge logic** (`lib/factory_man.ex:239-241`):
   - Wrap factory hooks to receive base hook as parameter
2. **Update hook invocation** (`lib/factory_man.ex:250-252, 259-261`):
   - Detect arity (1 vs 2 args) for backwards compatibility
3. **Test implementation** (`test/support/factories/users.ex:15-22`):
   - Update to use 2-arity form if needed

**Research needed:**
- Can hooks be defined as module functions instead of lambdas?
- Would `defoverridable` work with the current `use FactoryMan` pattern?
- What's the most idiomatic Elixir way to compose hooks?

**Files to modify:**
- `lib/factory_man.ex:239-241` - Hook merge logic
- `lib/factory_man.ex:250-252, 259-261` - Hook invocation points
- `test/support/factories/users.ex:15-22` - Test case

## Backlog

- Uncomment other factories (authors, posts, tags) after super call feature complete
- Documentation for multi-block syntax and super call pattern
