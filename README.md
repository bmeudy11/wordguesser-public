Part 1    [Part 2](part2.md)    [Part 3](part3.md)

Wordguesser
=============================================================

(v1.1, September 2015.  Written by Armando Fox and Nick Herson)
(some edits by mverdicchio 21 September 2015)
(refinements by Armando Fox September 2017)
(other updates from Michael Ball and others)

This codebase originated as an assignment for a software engineering course wherein students would incrementally develop a ruby version of Wordguesser (Hangman) using BDD and TDD, then wrap it in a Sinatra web server.

In this DevOps course, we will use the completed solution to this assignment as a starting point in an exercise to containerize the app and add it to a CI/CD pipeline.

## 0) Fork & Clone

In your browser, fork the repo from:  
[https://github.com/citadelcs/wordguesser](https://github.com/citadelcs/wordguesser)

Then clone your fork locally:

    git clone git@github.com:<your-username>/wordguesser.git
    cd wordguesser

If the repo is private, make sure you have access and your SSH key is added to GitHub.

## 1) Install Prerequisites

### Ubuntu (22.04/24.04)

    sudo apt update
    sudo apt install -y git build-essential libssl-dev zlib1g-dev libreadline-dev \
        libyaml-dev libffi-dev libgdbm-dev libncurses5-dev libdb-dev uuid-dev \
        ca-certificates curl


### macOS (Intel or Apple Silicon)

1. Install Homebrew if you don’t have it:

       /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

2. Then install basic tools:

       brew install git openssl@3

## 2) Install `rbenv` and Ruby 3.3.9

### Ubuntu

    # install rbenv
    git clone https://github.com/rbenv/rbenv.git ~/.rbenv
    echo 'export PATH="$HOME/.rbenv/bin:$PATH"' >> ~/.bashrc
    echo 'eval "$(rbenv init - bash)"' >> ~/.bashrc
    exec $SHELL -l
    

    # install ruby-build plugin
    git clone https://github.com/rbenv/ruby-build.git ~/.rbenv/plugins/ruby-build

    # install Ruby 3.3.9
    rbenv install 3.3.9
    rbenv local 3.3.9
    ruby -v

### macOS

    brew install rbenv ruby-build
    echo 'eval "$(rbenv init - zsh)"' >> ~/.zshrc
    exec $SHELL -l

    rbenv install 3.3.9
    rbenv local 3.3.9
    ruby -v

If you get OpenSSL errors on macOS:

    brew install openssl@3
    RUBY_CONFIGURE_OPTS="--with-openssl-dir=$(brew --prefix openssl@3)" rbenv install 3.3.9

## 3) Install Bundler & Gems

From the project root:

    gem install bundler
    bundle config set path 'vendor/bundle'
    bundle install

If you get errors during installation, check that you’re using Ruby 3.3.9:

    ruby -v

## 4) Run Tests

Run the RSpec test suite:

    bundle exec rspec

Run the Cucumber tests:

    bundle exec cucumber

✅ You should see passing (or at least runnable) tests.  
If not, check the error messages carefully — they usually point to missing dependencies or setup steps.

## 5) Run the App

Start the app:

    bundle exec rackup

By default it runs on [http://localhost:9292](http://localhost:9292)

To use a different port:

    bundle exec rackup -p 3000

Stop the server with `Ctrl+C`.

## 6) Common Issues

| Problem | Fix |
|----------|-----|
| `rbenv: version '3.3.9' not installed` | Run `rbenv install 3.3.9` and reopen your shell (`exec $SHELL -l`). |
| `bundle: command not found` | Run `gem install bundler`. |
| `openssl` build errors on macOS | Run `brew install openssl@3` and reinstall Ruby with:<br>`RUBY_CONFIGURE_OPTS="--with-openssl-dir=$(brew --prefix openssl@3)" rbenv install 3.3.9` |
| `rspec` or `cucumber` not found | Always prefix commands with `bundle exec`, e.g. `bundle exec rspec`. |
| Permissions or file-mode issues | Run `git config core.fileMode false` if needed. |

If you continue to have issues, confirm your environment:

    ruby -v
    which ruby
    which bundle

Both `ruby` and `bundle` should come from your rbenv installation (usually under `~/.rbenv/shims`).

## 7) What to Submit for Part 1

Submit the following evidence to your instructor:

- A screenshot or short note showing:
    - Ruby `3.3.9` active (`ruby -v`)
    - Successful `bundle install`
    - Output from `bundle exec rspec` and `bundle exec cucumber`
    - The app running locally in your browser at `http://localhost:3000`

---

## 🔜 Next Steps (Preview)

In **[Part 2](part2.md)**, you will:

- Containerize this Ruby app using **Docker**
- Write a **GitHub Actions** workflow to build and test the app automatically
- (Optional) Push the image to a container registry

Before moving on, make sure all tests pass and the app runs cleanly on your local system.


**[Part 3!!!](part3.md)** completed with new CI/CD workflow!
