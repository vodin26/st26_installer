#!/bin/bash

git submodule deinit -f node_modules/bats-mock
git rm --cached node_modules/bats-mock
rm -rf .git/modules/node_modules/bats-mock