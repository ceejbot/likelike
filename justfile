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
  echo "Checking for sqlite3..."
  if [ ! $(which sqlite3) ]; then
    if [[ $(uname -o) = "GNU/Linux" ]]; then
      sudo apt install sqlite3
    else
      brew install sqlite3
    fi
  fi

summarize: build
  cargo build --release
  target/release/likelike import fixtures/links-1.md
  target/release/likelike show --mode text ascii
