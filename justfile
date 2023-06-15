build: generate_sql_data
  #!/bin/bash
  cargo build

test: generate_sql_data
  #!/bin/bash
  set -eou pipefail
  cargo nextest run --success-output=final

migrate db:
  #!/bin/bash
  for migration in $(find migrations -name '*.sql' | sort -nk1); do
    sqlite3 {{ db }} < "$migration"
  done

generate_sql_data:
  #!/bin/bash
  if [ ! -e db.sqlite3 ]; then
    just migrate db.sqlite3
  fi

  cargo sqlx prepare --database-url sqlite://db.sqlite3 --check &>/dev/null ||
  cargo sqlx prepare --database-url sqlite://db.sqlite3

install_tools:
  #!/bin/bash
  set -e
  echo "Checking for sqlx..."
  if [ ! $(which sqlx) ]; then
    cargo install sqlx-cli
  fi
  if [ ! $(which cargo-nextest) ]; then
    cargo install cargo-nextest
  fi
  echo "Checking for sqlite3..."
  if [ ! $(which sqlite3) ]; then
    if [[ $(uname -o) = "GNU/Linux" ]]; then
      sudo apt install sqlite3
    else
      brew install sqlite3
    fi
  fi

setup_summarize:
  #!/bin/bash
  echo "Building for release with llm feature..."
  cargo build --quiet --release --features=llm
  echo "Importing interesting link data..."
  target/release/likelike import -d db.sqlite3 fixtures/*.md

summarize:
  cargo build --quiet --release --features=llm
  target/release/likelike show -d db.sqlite3 "*sunnyday*" 
  #target/release/likelike show -d db.sqlite3 --mode summary "*sunnyday*" 
  target/release/likelike show -d db.sqlite3 "*gutenberg*" 
  #target/release/likelike show -d db.sqlite3 --mode summary "*gutenberg*" 
