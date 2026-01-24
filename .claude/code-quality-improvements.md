# FactoryMan Code Quality & Idiomatic Improvements

This document provides analysis and recommendations for improving the FactoryMan codebase to make it more idiomatic, maintainable, and robust. Each issue is explained with sufficient context to understand both the problem and the reasoning behind the suggested solution.

---

## Understanding the Core Implementation

### How the Factory Macro Pipeline Works

The heart of FactoryMan is a macro that takes a quoted function definition and wraps it with lifecycle hooks. When a user writes `build: quote do def build_user(params), do: %User{...} end`, FactoryMan performs several transformations at compile time. First, it extracts the function name, arguments, and body from the AST using pattern matching (line 248). Then it creates a private version of the function with a name like `_build_user_without_hooks` that contains the original logic (line 254). Finally, it generates a public wrapper function that calls the before_build hook, invokes the private function, then calls the after_build hook (lines 260-265). If a repo is configured, it also generates an `insert_user!/1` function that chains build, before_insert hook, repo.insert!, and after_insert hook (lines 271-277).

This design allows users to define custom build logic while FactoryMan automatically weaves in extension points for testing needs like creating related records or setting up test state. The hooks system supports four lifecycle events: before_build, after_build, before_insert, and after_insert, giving users fine-grained control over the factory process.

### The Alternative Implementation

The codebase contains a second, simpler implementation in `lib/factory_man/factories.ex` that takes a completely different approach. Instead of requiring users to provide quoted function definitions, it automatically generates build functions that just call `struct(schema, params)` (line 28). This implementation is only 47 lines compared to the main implementation's 307 lines. It uses `defoverridable` to allow users to replace the generated functions with custom logic if needed (line 44), which is a more traditional Elixir pattern for providing default implementations.

The existence of two distinct implementations raises an important question about the library's architecture: are they meant to serve different use cases, or is one deprecated in favor of the other? This ambiguity could confuse users who need to choose between them.

---

## High Priority Issues

### 1. Unnecessary Code.eval_quoted Call (lib/factory_man.ex:257)

**Location:** `lib/factory_man.ex:257`

The line `Code.eval_quoted(private_build_function_ast, [], __ENV__)` appears to serve no purpose in the current implementation. When you evaluate AST with `Code.eval_quoted`, it executes the code and returns a tuple of `{result, binding}`. However, this line discards both the result and the binding, so any side effects from evaluation are the only thing that could matter. The actual function definition doesn't happen here—it happens three lines later when `def unquote(public_build_function_name)(...)` is expanded, which includes `unquote(private_build_function_name)()` in its body. At that point, the private function needs to exist, but it's defined by the `unquote(private_build_function_ast)` that would happen implicitly when the quote block is expanded.

This line likely existed in an earlier version of the code where the implementation strategy was different, and removing it now would have zero impact on functionality. It creates confusion for anyone reading the code because it looks like it should be doing something important, causing developers to waste time understanding why it's there.

**Recommendation:** Remove line 257 entirely.

---

### 2. Fragile Pattern Matching on opts[:build] (lib/factory_man.ex:248)

**Location:** `lib/factory_man.ex:248`

The current implementation uses direct pattern matching: `{:def, meta, [{public_build_function_name, context, args}, [do: body]]} = opts[:build]`. While this is concise and idiomatic when you know the value will match, it becomes problematic when dealing with user input. If a user forgets to provide the `:build` option, they get a MatchError that says `no match of right hand side value: nil`, which doesn't explain what they did wrong or how to fix it. If they provide a `:build` option but structure it incorrectly (perhaps writing `build: def build_user(params), do: ...` without the `quote do`), they get an equally cryptic error about the AST structure not matching.

These errors force users to either understand the internals of how FactoryMan processes AST (which should be an implementation detail) or engage in trial-and-error until they get the syntax right. Since the factory macro is meant to be a user-facing API, providing clear error messages with examples dramatically improves the developer experience.

**Recommendation:** Use a `case` statement to validate the structure before pattern matching, and provide helpful error messages that include the correct usage pattern. The error should show an example of the expected syntax: `build: quote do def build_user(params \\ %{}) do ... end end`. This way, when users make mistakes, they get actionable guidance instead of having to read the library source code.

**Example implementation:**
```elixir
build_ast = case opts[:build] do
  {:def, _, [{_, _, _}, [do: _]]} = ast ->
    ast
  nil ->
    raise ArgumentError, """
    Factory must include a :build option with a function definition.

    Example:
      factory name: :user,
              build: quote do
                def build_user(params \\ %{}) do
                  %User{name: params[:name] || "default"}
                end
              end
    """
  other ->
    raise ArgumentError, """
    Factory :build must be a function definition AST (quote do def ... end).
    Got: #{inspect(other)}
    """
end

{:def, meta, [{public_build_function_name, context, args}, [do: body]]} = build_ast
```

---

### 3. Documentation Mismatch in Hook Handler (lib/factory_man.ex:294)

**Location:** `lib/factory_man.ex:294-306`

The docstring for `get_hook_handler/2` contains an error that could mislead developers trying to understand the code. Line 294 says the function returns `&FactoryMan.fallback_hook_handler/0` when no handler is found, but the implementation on line 306 actually returns `&FactoryMan.fallback_hook_handler/1`. The difference between arity-0 and arity-1 is critical in Elixir because function references must exactly match the arity—you cannot call a function captured as `/1` with zero arguments or vice versa.

This documentation bug could cause developers to write incorrect code if they rely on the docstring. For example, if someone reads the docs and tries to manually call the fallback handler as `handler.()` (zero arguments), they'll get a FunctionClauseError at runtime. While the example on line 301 does show the correct arity-1 reference, having contradictory information in the same docstring defeats the purpose of documentation.

**Recommendation:** Change line 294 to say `&FactoryMan.fallback_hook_handler/1` to match the actual implementation. This is a one-character fix that ensures the documentation accurately describes the code.

---

### 4. Non-Idiomatic Hook Lookup Pattern (lib/factory_man.ex:306)

**Location:** `lib/factory_man.ex:306`

The current implementation uses `hooks[hook] || (&FactoryMan.fallback_hook_handler/1)` to look up hook handlers. While the `[]` operator works for both Keyword lists and maps in Elixir, it's not the idiomatic way to work with Keyword lists, which are the standard data structure for options in Elixir libraries. The Keyword module provides `Keyword.get/3` specifically for this use case, with an explicit default value parameter.

Using `hooks[hook]` is slightly ambiguous because it doesn't communicate whether `hooks` is expected to be a Keyword list, a map, or either. Additionally, the `||` operator doesn't distinguish between a key that's missing and a key that's present with a `nil` value—though in this particular case, that distinction doesn't matter since a `nil` hook handler would be invalid anyway. However, using the standard library function makes the code's intent clearer and follows Elixir community conventions.

**Recommendation:** Replace `hooks[hook] || (&FactoryMan.fallback_hook_handler/1)` with `Keyword.get(hooks, hook, &fallback_hook_handler/1)`. This makes it explicit that hooks should be a Keyword list and uses the pattern Elixir developers expect when reading library code. The shorter `fallback_hook_handler/1` reference (without the module prefix) works because the function is being defined in the same module.

---

### 5. Missing Validation for extends Module (lib/factory_man.ex:195-205)

**Location:** `lib/factory_man.ex:195-205`

The factory inheritance feature allows users to specify `extends: ParentFactory` to inherit options like repo and hooks from a parent factory module. The implementation retrieves the parent's options by calling `extends.__info__(:attributes)[:factory_opts]`, which reads a module attribute that FactoryMan persists at compile time (line 208). However, if the `extends` value points to a module that doesn't exist, the code will fail with an `UndefinedFunctionError` saying the module's `__info__/1` function is undefined. This error message doesn't explain the actual problem: the user referenced a module that hasn't been compiled or doesn't exist.

Even worse, if the extends value points to a valid module that just isn't a FactoryMan factory (like accidentally writing `extends: MyApp.User` instead of `extends: MyApp.Factory`), the code will silently fall back to an empty options list (line 202's `|| []`). This means the inheritance feature appears to work but doesn't actually inherit anything, which is a confusing silent failure.

**Recommendation:** Add validation that checks two things: first, whether the module exists using `Code.ensure_loaded?/1`, and second, whether it actually has the `:factory_opts` attribute that indicates it's a FactoryMan module. If either check fails, raise an ArgumentError with a clear message explaining what went wrong. This helps users catch mistakes at compile time with actionable error messages.

**Example implementation:**
```elixir
extends = unquote(opts)[:extends]

parent_opts =
  if extends do
    unless Code.ensure_loaded?(extends) do
      raise ArgumentError, """
      Factory extends module #{inspect(extends)} does not exist.
      Make sure the module is defined before extending it.
      """
    end

    unless extends.__info__(:attributes)[:factory_opts] do
      raise ArgumentError, """
      Module #{inspect(extends)} is not a FactoryMan factory.
      Only modules defined with `use FactoryMan` can be extended.
      """
    end

    extends.__info__(:attributes)[:factory_opts]
  else
    []
  end
```

---

## Medium Priority Improvements

### 6. Compile-Time Hook Validation

**Context:** The hooks system currently accepts any atom as a hook name without validation. If a user makes a typo like `before_bild` instead of `before_build`, their hook handler will simply never be called, and they won't receive any error or warning.

The four valid hooks are: `:before_build`, `:after_build`, `:before_insert`, and `:after_insert`. These are fundamental to FactoryMan's design and are unlikely to change. By validating hook names at compile time, FactoryMan can catch typos and incorrect hook names before code even runs, saving developers from debugging why their hooks aren't being invoked.

**Recommendation:** Define a module attribute listing valid hooks (`@valid_hooks [:before_build, :after_build, :before_insert, :after_insert]`), then add validation in the factory macro that checks whether all provided hook keys are in this list. If any invalid hooks are found, raise an ArgumentError at compile time listing both the invalid hooks and the valid options. This follows the Elixir principle of failing fast with helpful error messages.

The validation would look like: `invalid_hooks = Keyword.keys(hooks) -- @valid_hooks`, and if `invalid_hooks` is not empty, raise an error. This provides immediate feedback when users make mistakes.

---

### 7. Optimize Hook Resolution to Compile Time

**Context:** Every time a build or insert function is called, the current implementation performs a runtime lookup: `FactoryMan.get_hook_handler(unquote(hooks), :before_build)`. This calls a function that does a keyword list search, returning either the user's handler or the fallback handler. While this lookup is fast (keyword lists are small), it's completely unnecessary because the hooks are known at compile time.

When the factory macro runs, it already has access to the hooks keyword list. It could extract each specific hook handler at compile time and embed the direct function reference into the generated code. This eliminates the runtime overhead of looking up hooks and makes the generated code simpler and more direct.

**Recommendation:** In the macro, before generating the functions, extract each hook handler: `before_build = hooks[:before_build]`, `after_build = hooks[:after_build]`, etc. Then in the generated function, use a conditional: `if unquote(before_build), do: unquote(before_build).(params), else: params`. This inlines the decision of whether a hook exists directly into the generated code, removing the need for the `get_hook_handler/2` function entirely (or at least removing it from the critical path).

This is a classic compile-time optimization that makes the generated code more efficient and easier to understand when inspecting the compiled module with tools like `Code.get_docs/2`.

---

### 8. Clarify the Purpose of Two Implementations

**Context:** The codebase contains both `FactoryMan` (the full-featured implementation with hooks and custom build functions) and `FactoryMan.Factories` (the simpler implementation using `struct/2` and `defoverridable`). Currently, there's no documentation explaining when to use which, or whether one is deprecated.

From the code structure, it appears they serve different use cases: `FactoryMan.Factories` is for simple cases where you just need to create structs with default values and occasionally override the build logic, while `FactoryMan` is for complex scenarios requiring lifecycle hooks, inheritance, and sophisticated build logic. However, this distinction isn't documented anywhere, leaving users to discover it through trial and error or by reading the source code.

**Recommendation:** Document the intended use case for each implementation in their respective moduledocs. If they're truly meant for different scenarios, explain what those scenarios are with concrete examples. If one is deprecated or experimental, clearly mark it as such. If they're redundant, consider removing one to reduce maintenance burden and decision paralysis for users.

An alternative approach would be to merge them by making hooks optional in the main implementation—when no hooks are provided and the build function just creates a struct, the generated code would be nearly identical to the simpler implementation.

---

### 9. Simplify User-Facing Syntax

**Context:** Currently, users must write `build: quote do def build_user(params \\ %{}) do ... end end`, which requires understanding Elixir's quote mechanism. This exposes an implementation detail (that FactoryMan manipulates AST) to the user API, making the library harder to learn.

The reason for requiring quoted code is that FactoryMan's `factory` macro uses `quote bind_quoted: [opts: opts]`, which evaluates the options once to prevent accidental multiple evaluation. However, this means the opts are evaluated outside the calling context, so any function definitions in opts need to be pre-quoted by the user.

**Trade-off Analysis:** The current syntax is explicit and gives users full control over the function definition, including adding docstrings (as shown in the example on line 50-56). However, it's also verbose and unusual. A more natural Elixir pattern would be `factory :user do def build(params) do ... end end`, where the factory macro takes a do-block and extracts function definitions from it.

Changing to this simpler syntax would require rewriting the factory macro to use `factory(name, do: block)` instead of `factory(opts)`, then parsing the block to extract function definitions. This is more complex macro code but provides a better user experience.

**Recommendation:** Consider whether the simpler syntax is worth the additional macro complexity. If the current syntax hasn't been a pain point for users, it may not be worth changing. However, if users frequently struggle with the quote requirement, simplifying the API could significantly improve adoption.

---

## Low Priority Polish

### 10. Handle Commented Debug Functions

**Context:** Lines 211-212 and 239-241 contain commented-out debug functions that would expose factory options for inspection in IEx. The documentation (lines 159-182) even references these functions and provides examples of using them, but the functions themselves are disabled.

These debug functions could be genuinely useful for understanding what options were merged from parent factories and what configuration is active for a given factory. However, leaving them commented out creates confusion—are they meant to be uncommented by users, or are they deprecated, or are they waiting for some other change?

**Recommendation:** Make a decision about these functions. If they're useful for debugging, uncomment them and make them part of the public API (or at least the documented debugging API). If they're not needed, remove both the comments and the documentation that references them. As a middle ground, you could add a compile-time flag like `if Application.get_env(:factory_man, :debug, false)` that conditionally generates these functions only when debug mode is enabled.

---

### 11. Complete FIXME Documentation

**Context:** The moduledoc contains five FIXME placeholders at lines 11, 14, 20, 88, and 186 where documentation should explain installation instructions, hook examples, and common recipes. While the rest of the documentation is reasonably comprehensive, these gaps leave users without guidance on important topics.

The installation instructions (lines 11 and 14) are particularly important because they're at the top of the getting started guide. Users who are new to the library need to know how to add it as a dependency and configure it for different environments. The hook examples (line 88) are important because hooks are a core feature but aren't illustrated with concrete use cases. The common recipes section (line 186) could provide valuable guidance on patterns like creating associated records or handling polymorphic associations.

**Recommendation:** Fill in all FIXME sections with concrete examples. For installation, show the Mix dependency and explain whether to add the library to `:only :test` or to all environments. For hooks, provide realistic examples like "creating a user's profile after the user is inserted" or "sending a welcome email in tests that verify email content." For common recipes, document patterns that users are likely to need when building test suites, possibly drawing from real usage if FactoryMan is being used in production codebases.

---

### 12. Add Typespec for Factory Options

**Context:** The `factory/1` macro currently has no typespec defining what the valid options are. Typespecs serve as both documentation and enable tools like Dialyzer to catch type errors at compile time. They also improve IDE autocomplete and hover documentation.

Defining a clear type for factory options would document the contract: what keys are expected, what their value types are, and which are required vs optional. Currently, users have to piece this together from examples and error messages.

**Recommendation:** Define a type like `@type factory_opts :: [name: atom(), build: Macro.t(), hooks: keyword(), extends: module(), insert: boolean()]` above the factory macro definition. Then add `@spec factory(factory_opts()) :: Macro.t()` to the macro. This makes the expected structure explicit and enables better tooling support.

Note that typespecs on macros are primarily for documentation since macros are expanded at compile time, but they still provide value by clarifying the expected input structure.

---

## Summary

The FactoryMan codebase is fundamentally well-designed, with a clever approach to factory inheritance and a flexible hook system. The high-priority issues are mostly about improving error messages and removing unnecessary code—changes that make the library more user-friendly without altering its core behavior. The medium-priority improvements are about following Elixir idioms more closely and optimizing performance, which would benefit the codebase in the long term but aren't critical for functionality. The low-priority items are polish that would improve the overall quality and documentation of the library.

The most impactful changes would be improving error messages (issues 2 and 5) and completing the documentation (issues 3 and 11), as these directly affect the user experience. The code cleanup items (issues 1 and 4) are trivial to implement and remove confusion. The architectural questions (issues 6, 7, 8, and 9) require more thought about the library's direction but could significantly improve its design if addressed thoughtfully.
