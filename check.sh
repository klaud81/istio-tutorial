#!/bin/bash
modules="git docker curl java virtualbox minishift stern siege"
#modules="git docker curl stern siege java"

curl -sL https://git.io/_has | HAS_ALLOW_UNSAFE=y bash -s ${modules}
