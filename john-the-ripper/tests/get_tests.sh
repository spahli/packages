#!/bin/bash

######################################################################
# Copyright (c) 2019 Claudio André <claudioandre.br at gmail.com>
#
# This program comes with ABSOLUTELY NO WARRANTY; express or implied.
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, as expressed in version 2, seen at
# http://www.gnu.org/licenses/gpl-2.0.html
######################################################################

#Check to assure we are in the right place
if [[ ! -d src || ! -d run ]] && [[ $1 != "-f" ]]; then
    echo
    echo 'It seems you are in the wrong directory. To ignore this message, add -f to the command line.'
    exit 1
fi

#Changes needed
rm -rf .travis.yml buggy.sh circle.yml appveyor.yml .travis/ .circle/ .circleci/

mkdir -p .circleci/
mkdir -p .travis/

wget https://raw.githubusercontent.com/claudioandre-br/packages/master/john-the-ripper/tests/buggy.sh

wget https://raw.githubusercontent.com/claudioandre-br/packages/master/john-the-ripper/tests/appveyor.yml

wget https://raw.githubusercontent.com/claudioandre-br/packages/master/john-the-ripper/tests/.travis.yml
wget https://raw.githubusercontent.com/claudioandre-br/packages/master/john-the-ripper/tests/CI-tests.sh   -P .travis/
wget https://raw.githubusercontent.com/claudioandre-br/packages/master/john-the-ripper/tests/travis-ci.sh  -P .travis/

wget https://raw.githubusercontent.com/claudioandre-br/packages/master/john-the-ripper/tests/config.yml    -P .circleci/
wget https://raw.githubusercontent.com/claudioandre-br/packages/master/john-the-ripper/tests/circle-ci.sh  -P .circleci/

wget https://raw.githubusercontent.com/claudioandre-br/packages/master/john-the-ripper/tests/.cirrus.yml

chmod +x buggy.sh
chmod +x .travis/CI-tests.sh
chmod +x .travis/travis-ci.sh
chmod +x .circleci/circle-ci.sh

git add appveyor.yml
git add .travis.yml
git add .cirrus.yml
git add .travis/
git add .circleci/

# Ban all problematic formats (disable buggy formats)
# If a formats fails its tests on super, I will burn it.
./buggy.sh disable

# Save the resulting state
git commit -a -m "CI: do test plus Windows packaging $(date)"

# Clean up
rm -f buggy.sh
rm -f get_tests.sh

