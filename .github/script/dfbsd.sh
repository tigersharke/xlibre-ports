#!/bin/sh
pwd
ls -lah
whoami
env
uname -a
env IGNORE_OSVERSION=yes pkg install -y ccache-static
ccache --max-size="200M"
ls /usr/dports
export PORTS_BRANCH="master"
if [ ! -f "/usr/dports/${PORTS_BRANCH}" ] ; then mkdir -p /usr/dports && fetch "https://github.com/dragonflybsd/dports/archive/refs/heads/${PORTS_BRANCH}.tar.gz" -o - | tar xf - -C /usr/dports --strip-components=1 && touch "/usr/dports/${PORTS_BRANCH}" ; fi
echo "WITH_CCACHE_BUILD=yes" >> /etc/make.conf
{
{
patch -N /usr/dports/Mk/bsd.port.subdir.mk << EOF
@@ -173,6 +173,11 @@
 TARGETS+=	realinstall
 TARGETS+=	reinstall
 TARGETS+=	tags
+TARGETS+=	stage
+TARGETS+=	stage-qa
+TARGETS+=	check-plist
+TARGETS+=	run-depends-list
+TARGETS+=	build-depends-list

 .for __target in ${TARGETS}
 .  if !target(${__target})
EOF
} || true
}
grep -n '^TARGETS+=' /usr/dports/Mk/bsd.port.subdir.mk
echo 'OVERLAYS=/'"$(pwd)"'/' >> /etc/make.conf
echo 'WITH_DEBUG=yes' >> /etc/make.conf
echo 'DEBUG_FLAGS+= -O0' >> /etc/make.conf
cat /etc/make.conf
make run-depends-list | sort | uniq | grep -v '^==\|xlibre' | cut -d '/' -f 4- | xargs pkg install -y
make build-depends-list | sort | uniq | grep -v '^==\|xlibre\|xorg-macros' | cut -d '/' -f 4- | xargs pkg install -y
make -C /usr/dports/devel/xorg-macros/ clean
make stage
make stage-qa
make check-plist
export PACKAGES="$(pwd)/pkgs/"
mkdir $PACKAGES
make package
export PACKAGES="$(pwd)/pkgs/"
ABI="$(pkg config abi)"
mv $PACKAGES/All $PACKAGES/$ABI
pkg repo -l $PACKAGES/$ABI
pkg install -y tree
cd $PACKAGES/$ABI 
tree -h -D -C -H -./ --houtro=/dev/null -T 'XLibre binaries for FreeBSD' ./ > ./index.html
