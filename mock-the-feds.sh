#!/bin/bash

SCM=~/projects/samba/samba-hack
BASE="91f6439"
VERS="4.5.1"
PKG=~/projects/fedora/samba
REPO=~/repos/f23/x86_64
REPO_NAME="jarrpa"

MOCK_OPTS="--no-clean --without=configure --nocheck --no-cleanup-after"
if [ "x${1}" == "xclean" ]; then
  MOCK_OPTS="--no-cleanup-after"
elif [ "x${1}" == "xconfig" ]; then
  MOCK_OPTS="${MOCK_OPTS/without=configure/with=configure}"
fi

pushd $PKG

pushd $SCM
RELNUM=`git rev-list ${BASE}..HEAD --abbrev-commit | wc -l`
RELEASE="${RELNUM}.${BASE}"

SRPM="samba-${VERS}-${RELEASE}.fc23.src.rpm"

if [ -f "${REPO}/${SRPM}" ]; then
  CMD="SAMBA_PKGS=\`dnf -C list installed | grep \"samba\\\|ctdb\\\|libwb\\\|libsmb\" | awk '{printf \$1; printf \" \"}'\`; \
       sudo dnf -y remove \$SAMBA_PKGS; \
       sudo dnf -y --refresh --allowerasing --disablerepo=* --enablerepo=${REPO_NAME} install \$SAMBA_PKGS"
else
  CMD="sudo dnf -y --refresh --allowerasing --disablerepo=* --enablerepo=${REPO_NAME} update"
fi

git archive --format=tar.gz --prefix=samba-${VERS}/ HEAD -o $PKG/samba-${VERS}.tar.gz
popd

sed -i "s/\\(define samba_version \\).*/\\1${VERS}/" samba.spec
sed -i "s/\\(define main_release \\).*/\\1${RELEASE}/" samba.spec
md5sum samba-${VERS}.tar.gz >sources
fedpkg --dist f23 srpm || exit $?
sudo rm -rf /var/lib/mock/fedora-23-x86_64/root//builddir/build/SRPMS/*src.rpm
sudo mock ${MOCK_OPTS} -r f23-x86_64 rebuild ${SRPM} || exit $?

popd

./scripts/hark-a-vagrant.sh ${CMD}
