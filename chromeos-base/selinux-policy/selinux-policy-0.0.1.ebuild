# Copyright (c) 2018 The Fyde OS Authors. All rights reserved.
# Distributed under the terms of the BSD

EAPI="5"

DESCRIPTION="replace google selinux policy"
HOMEPAGE="http://fydeos.com"

LICENSE="BSD-Google"
SLOT="0"
KEYWORDS="amd64 arm"

IUSE="
    android-container-nyc
    android-container-pi
     "
RDEPEND="sys-apps/restorecon"

DEPEND="${RDEPEND}"

S="${WORKDIR}"

src_install() {
   	local source_dir=${FILESDIR} 
	if use amd64 ; then
        if use android-container-nyc; then
         source_dir="${source_dir}/amd64"
        elif use android-container-pi; then
         source_dir="${source_dir}/amd64_pi"
                fi
    elif use arm ; then
        source_dir="${source_dir}/arm"
    fi
    insinto /etc
	doins -r ${source_dir}/selinux
}
