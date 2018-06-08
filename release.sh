#!/bin/sh

#
# Near-automatic releases.
#


if [ -z "$1" ]
  then
	echo "Usage: release.sh [version] [release]"
	exit 1
  fi

if [ -z "$2" ]
  then
	echo "Usage: release.sh [version] [release]"
	exit 1
  fi
  
VERSION=$1
RELEASE=$2


echo "======"
echo "Export Without SVN"
echo "======"

rm -rf /tmp/deimos-release
mkdir /tmp/deimos-release
cd /tmp/deimos-release

svn export svn+ssh://aaron@syn.zadzmo.org/home/aaron/repos/deimos \
	./deimos-$VERSION 	|| exit 1

cd deimos-$VERSION
  

echo "======"
echo "Running tests"
echo "======"

./test.lua || exit 1


echo "======"
echo "Check Version Number"
echo "======"

v1=`lua ./printver.lua`
v2="$VERSION `date +%Y.%m%d`"

echo $v1
echo $v2

if [ "$v1" != "$v2" ]
  then
	echo "Version number not right!"
	exit 1
  fi


echo "======"
echo "Generate Docs"
echo "======"

ldoc.lua . || exit 1


echo "======"
echo "Rockspec handling"
echo "======"

sed -ie "s/%VERSION%/$VERSION/g" deimos.rockspec 	|| exit 1
sed -ie "s/%RELEASE%/$RELEASE/g" deimos.rockspec	|| exit 1


echo "======"
echo "Tarball"
echo "======"

cd ..
tar -cvf deimos-$VERSION.tar deimos-$VERSION
gzip -9 deimos-$VERSION.tar

cp deimos-$VERSION/deimos.rockspec deimos-$VERSION-$RELEASE.rockspec
