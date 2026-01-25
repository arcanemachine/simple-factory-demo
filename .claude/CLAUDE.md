# FactoryMan - Instructions for Claude

## Project Purpose

This is the **FactoryMan repository**, an Elixir testing factory library.

**FactoryMan is the product.** The blog schemas (Users, Authors, Posts, Tags) are just showcase examples.

## What is FactoryMan?

A macro-based testing factory library located in `/workspace/local/projects/factory_man/lib/factory_man.ex` that:
- Generates `build_<name>/1` functions to create test data structs in memory
- Generates `insert_<name>!/1` functions to build and insert into database (when repo configured)
- Supports lifecycle hooks: `:before_build`, `:after_build`, `:before_insert`, `:after_insert`
- Allows factory inheritance via `:extends` option
- Integrates with Ecto repositories

## Project Structure

```
lib/
  factory_man.ex              # THE MAIN LIBRARY - core macro system
  factory_man/factories.ex    # Alternative DSL for factories
  factory_man_demo/           # Example schemas (demo content, not the product)
    users/user.ex
    authors/author.ex
    posts/post.ex
    tags/tag.ex
    posts_tags/post_tag.ex

test/support/
  factory.ex                  # Base factory with hooks
  factories/users.ex          # Example User/Author factories
```

## Example Domain (Demo Content)

The blog system demonstrates FactoryMan with realistic relationships:

- **User** (username) → has_one **Author**
- **Author** (name) → has_many **Posts**
- **Post** (title, content) ↔ **Tag** (many-to-many via posts_tags)

These schemas exist to showcase how FactoryMan handles:
- Simple attributes
- One-to-one and one-to-many associations
- Many-to-many relationships with join tables
- Complex nested data building

## Key Demonstrations

1. **Base Factory Pattern** (`test/support/factory.ex`):
   - Configures repo integration
   - Sets up `after_insert_handler` that resets associations to `NotLoaded` (mimics raw DB queries)

2. **Factory Inheritance** (`test/support/factories/users.ex`):
   - Author factory extends base factory
   - Demonstrates defaults and custom parameter overrides

3. **Hook System**:
   - `before_build_handler` - modifies data before struct creation
   - `after_insert_handler` - processes data after database insertion

## Database Connection Setup

### Prerequisites

Before running any Elixir/IEx commands, ensure the Elixir environment is set up:

1. **Check if ready:** `test -f ~/.asdf_elixir_ready`
2. **If check fails:** Run `/workspace/local/scripts/setup.sh` from the workspace root
3. **Always use:** `bash -l -c 'your command'` wrapper for all Elixir commands

(See `/workspace/.claude/CLAUDE.md` for complete Elixir environment setup details)

### Environment Configuration

The project uses an environment variable `POSTGRES_HOST` to configure the database hostname, with a fallback to `localhost`:

```elixir
# config/config.exs
hostname: System.get_env("POSTGRES_HOST", "localhost")
```

### Connecting to Postgres from Docker Container

When running Claude Code in a Docker container with Postgres in a separate container:

#### Step 1: Get the Current Postgres Container IP

**Try the hardcoded value first:** `172.16.0.6`

**If that doesn't work or you suspect it's stale:**

1. Check if `/workspace/local/tmp/postgres-inspect.txt` exists and read it:
   ```bash
   cat /workspace/local/tmp/postgres-inspect.txt | grep -A 10 '"Networks"'
   ```
   Look for the `"IPAddress"` field under the `"bridge"` network section.

2. If that file doesn't exist, ask the user to provide the output of:
   ```bash
   docker inspect postgres
   ```
   You cannot run this command yourself (no Docker access from within the container), but the user can run it on their host and provide the output.

#### Step 2: Start IEx with the Correct IP

**For persistent tmux sessions (ALWAYS use this approach):**
```bash
/workspace/local/bin/tmux new-session -d -s iex_session \
  "bash -l -c 'export POSTGRES_HOST=<postgres_container_ip> && export MIX_ENV=test && cd /workspace/local/projects/factory_man && iex -S mix'"
```

Replace `<postgres_container_ip>` with the IP from Step 1.

**IMPORTANT:** Always set `MIX_ENV=test` when working with factories, as they are defined in the test support files.

#### Step 3: Verify Connection

Wait 5-8 seconds for IEx to start, then check for connection errors:
```bash
/workspace/local/bin/tmux capture-pane -t iex_session -p | tail -n 20
```

If you see `connection refused` or `host unreachable` errors, the IP is wrong. Go back to Step 1.

If you see a clean `iex(1)>` prompt with no Postgres errors, you're connected!

### Current Configuration (as of 2026-01-24)

- **Postgres Container IP**: `172.16.0.6` (on Docker bridge network) - **MAY BE STALE**
- **Database**: `factory_man_demo`
- **Username**: `postgres`
- **Password**: `your_postgres_password`

**Note**: If the Postgres container is recreated, the IP address WILL change. Always verify the IP when starting a new session.

## Working with Persistent IEx Sessions

### Using tmux for Interactive Sessions

The workspace includes tmux at `/workspace/local/bin/tmux`. **Always use tmux for persistent IEx sessions** - don't try to run IEx commands directly with bash piping.

**Start a session (use the correct Postgres IP from Database Connection Setup above):**
```bash
/workspace/local/bin/tmux new-session -d -s iex_session \
  "bash -l -c 'export POSTGRES_HOST=<postgres_ip> && export MIX_ENV=test && cd /workspace/local/projects/factory_man && iex -S mix'"
```

**Send commands:**
```bash
/workspace/local/bin/tmux send-keys -t iex_session 'Your.Elixir.Code' C-m
```

**IMPORTANT - Handling special characters:** When sending commands with `!` or other special characters, use double quotes on the outside and escape inner quotes:
```bash
# Good - works correctly
/workspace/local/bin/tmux send-keys -t iex_session "Users.insert_user!(%{username: \"alice\"})" C-m

# Bad - will add backslash before !
/workspace/local/bin/tmux send-keys -t iex_session 'Users.insert_user!(%{username: "alice"})' C-m
```

**View output:**
```bash
/workspace/local/bin/tmux capture-pane -t iex_session -p | tail -n 20
# Or capture more history:
/workspace/local/bin/tmux capture-pane -t iex_session -p -S -50 | tail -n 50
```

**List sessions:**
```bash
/workspace/local/bin/tmux list-sessions
```

**Kill session (rarely needed):**
```bash
/workspace/local/bin/tmux kill-session -t iex_session
```

**IMPORTANT:** You don't need to kill and restart the tmux IEx session between operations. Keep the same session running - the user can monitor it and track what you're doing. Only restart if there's a specific problem (crashed session, need to change environment variables, etc.).

## Important Notes for Claude

- This is NOT a blog application - it's a factory library demonstration
- Don't "improve" the demo schemas unless specifically asked - they're examples
- The interesting code is in `lib/factory_man.ex` and `test/support/`
- If asked to work on "the project", clarify whether they mean FactoryMan library or the demo schemas
- Always use tmux for interactive IEx sessions
- **ALWAYS use `MIX_ENV=test` for factory work** - factories are in `test/support/`
- See `.claude/code-quality-improvements.md` for detailed analysis from previous sessions
