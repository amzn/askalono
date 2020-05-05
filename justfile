build: init
    cargo build

init:
    [ -f datasets/spdx-json/MIT.json ] || git submodule update --init

# run a Cargo command across all packages
all +cmds: init
    cargo {{cmds}}
    cd cli && cargo {{cmds}}
    cd extras/lambda && cargo {{cmds}}
    cd extras/wasm/pkg && cargo {{cmds}}

lint:
    just all clippy
    just all fmt

# run the CLI in release mode
cli +args="": init
    cd cli && cargo build --release
    ./target/release/askalono {{args}}

diag +args="": init
    cd cli && cargo build --release --features diagnostics
    ./target/release/askalono id --diff {{args}}

# update the gh-pages branch with generated documentation
update-docs:
    #!/bin/bash

    rev=$(git rev-parse --short HEAD)
    cargo doc --no-deps
    git clone . -b gh-pages gh-pages
    cp -rv target/doc/. gh-pages/doc
    cd gh-pages
    git add doc
    git commit -m "Documentation update from master commit $rev"
    git push

# update the wasm-demo stuff
update-wasm-demo:
    #!/bin/bash

    rev=$(git rev-parse --short HEAD)
    pushd extras/wasm
    wasm-pack build --out-name askalono
    pushd demo
    rm -rf dist
    npm run build
    popd
    popd
    git clone . -b gh-pages gh-pages
    rm -rf gh-pages/wasm-demo
    cp -rv extras/wasm/demo/dist/. gh-pages/wasm-demo
    cd gh-pages
    git add wasm-demo
    git commit -m "wasm-demo update from master commit $rev"
    git push