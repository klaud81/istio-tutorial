#!/bin/bash
modules="git docker mvn curl stern siege java"

curl -sL https://git.io/_has | HAS_ALLOW_UNSAFE=y bash -s ${modules}
