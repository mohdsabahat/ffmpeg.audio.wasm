#!/bin/bash

cmds=()

# Detect what dependencies are missing.
for cmd in autoconf autogen automake libtool pkg-config ragel
do
  if ! command -v $cmd &> /dev/null
  then
    cmds+=("$cmd")
  fi
done

# Install missing dependencies
if [ ${#cmds[@]} -ne 0 ];
then
  if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    sudo apt-get update
    sudo apt-get install -y ${cmds[@]}
  else
    brew install ${cmds[@]}
  fi
fi

cd modules/emsdk/
# Update emsdk if possible (may fail on fresh submodule checkout - that's OK)
git pull 2>/dev/null || true
./emsdk install 3.1.2
./emsdk activate 3.1.2
cd ../../