#!/bin/sh

if [ "$#" -eq 0 ]; then
	echo "Please give image name!"
	exit 1
fi
echo "To build image $1"

rm -rf archive/
git archive --format=tar --prefix=archive/ HEAD | tar xf -

GIT_COMMIT=$(git log -1 --oneline --decorate=short)
echo docker build --build-arg GIT_COMMIT="$GIT_COMMIT" -t "$1" .
docker build -f Dockerfile --build-arg GIT_COMMIT="$GIT_COMMIT" -t "$1" .

rm -rf archive/
