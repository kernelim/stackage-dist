#!/bin/bash

mkdir -p per-package.data
stack  --resolver=lts-6.1 generate-build-plan-makefile "../per-package \$@ --base \"\$(BASE_PACKAGES)\"" > per-package.data/Makefile
