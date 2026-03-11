# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Tech Stack

- **Ruby 3.3.5** / **Rails 8.1.2**
- **PostgreSQL** via `pg` gem
- **Devise** for authentication
- **simple_form** + **simple_form-tailwind** for forms
- **Tailwind CSS** (via `tailwindcss-rails`) + **DaisyUI** for styling
- **Hotwire** (Turbo + Stimulus) for interactivity
- **Propshaft** for assets
- **Solid Cache / Queue / Cable** (DB-backed, no Redis needed)
- **Kamal** for deployment

## Development Commands

```bash
bin/dev          # Start server + Tailwind watcher (uses Procfile.dev)
bin/rails server # Server only

bin/rails db:create db:migrate
bin/rails db:seed  # Seeds with Faker data (destroys existing records first)

bin/rails test                    # Run all tests
bin/rails test test/models/user_test.rb  # Run a single test file
bin/rails db:test:prepare test   # Prepare test DB and run tests
bin/rails test:system            # System tests (Capybara + Selenium)

bin/rubocop      # Lint (rubocop-rails-omakase style)
bin/brakeman --no-pager  # Security scan
bin/bundler-audit        # Gem vulnerability scan
bin/importmap audit      # JS dependency audit
```

## Architecture

### Domain Model

This is a basketball team management app. Core models:

- **User** — Devise auth; has profile picture (Active Storage); belongs to Teams via `UserTeam` join; has many `victories` and `programs`
- **Team** — Groups of users; has many `programs` and `matches` (as `blue_team` or `red_team`)
- **Match** — A game between `blue_team` and `red_team` (both `Team` records); created by a `User`; has one `Meet` (polymorphic)
- **Program** — A training program created by a `User` for a `Team`; levels: Debutant/Intermediate/Confirmed/Expert; has many `meets` (polymorphic)
- **Meet** — Polymorphic scheduled session (`meetable` is either a `Match` or `Program`); belongs to a `Court`; durations: 15/30/45/60/90/120 min
- **Court** — Physical basketball court with name, address, lat/long coordinates; has many `meets` and `victories`
- **Victory** — Join between `User` and `Court`
- **UserTeam** — Join table between `User` and `Team`

### Key Associations

`Meet` is polymorphic — it belongs to either a `Program` or a `Match` via `meetable_type` / `meetable_id`. When querying meets through a user, there are two paths: `user.program_meets` (via programs) and `user.match_meets` (via matches).

### Frontend

- Stimulus controllers in `app/javascript/controllers/` (auto-loaded via `index.js`)
- Tailwind + DaisyUI with a custom dark theme defined in `app/assets/tailwind/application.css`
- Flash messages handled by `flashes_controller.js` and `app/views/shared/_flashes.html.erb`

### Routing

Only `devise_for :users` and `root to: "pages#home"` are currently defined. All feature routes still need to be added.

## Validations & Constants

- `User::GENDERS` = `["Homme", "Femme", "Non-binaire"]`
- `Program::LEVELS` = `["Debutant", "Intermediate", "Confirmed", "Expert"]`
- `Meet::DURATIONS` = `[15, 30, 45, 60, 90, 120]` (minutes)

## CI Pipeline

GitHub Actions runs on PRs and pushes to `master`: Ruby security scan (brakeman), gem audit (bundler-audit), JS audit (importmap), RuboCop lint, unit tests, and system tests.
