# Copyright 1999-2018 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=6
#PYTHON_COMPAT=( python2_7 )

#CROS_WORKON_COMMIT="bdfda8c2971ecf01f8fcca2e3c961f49406db7c9"
#CROS_WORKON_TREE="dc715afb377abbc9f3bfa8a33ea602262630e79f"
#CROS_WORKON_PROJECT="anbox"
#CROS_WORKON_REPO="https://github.com/anbox"
#CROS_WORKON_LOCALNAME="initramfs"
#CROS_WORKON_OUTOFTREE_BUILD="1"
#CROS_WORKON_DESTDIR="${S}"
#CROS_WORKON_BLACKLIST="1"

#inherit cmake-utils git-r3 linux-info python-single-r1 systemd udev versionator
# inherit cros-workon cros-board cros-constants cmake-utils git-r3 linux-info python-single-r1 versionator
#inherit cmake-utils git-r3 linux-info python-single-r1 versionator
inherit cmake-utils git-r3 linux-info versionator

DESCRIPTION="Run Android applications on any GNU/Linux operating system"
HOMEPAGE="https://anbox.io/"
EGIT_REPO_URI="https://github.com/${PN}/${PN}.git"
EGIT_COMMIT="bdfda8c2971ecf01f8fcca2e3c961f49406db7c9"
IMG_PATH="$(get_version_component_range 2)/$(get_version_component_range 3)/$(get_version_component_range 4)"
#IMG_REVISION="$(get_version_component_range 5)"
#SRC_URI="http://build.anbox.io/android-images/${IMG_PATH}/android_${IMG_REVISION}_amd64.img"
SRC_URI="http://build.anbox.io/android-images/${IMG_PATH}/android_amd64.img"

LICENSE="GPL-3"
SLOT="0"
KEYWORDS="~amd64 ~x86"
IUSE="test privileged"
RESTRICT="mirror"

## Anbox makes use of LXC containers ##
# File and directory permissions are set by LXC as either a 'privileged' or 'unprivileged' container #
# For fperms to be correct inside the Anbox container, LXC must start the container as 'unprivileged' #
#  Otherwise fperms will appear corrupt as 'u1_<uid>' and 'u1_<gid>' #
# LXC hardcodes the use of sys-apps/shadow 'newuidmap' and 'newgidmap' (if they exist on the host) to map UID/GID inside the container #
#	LXC requires correct setup of /etc/subuid and /etc/subgid files
#	Anbox usually run inside a 'snap' environment, relies on LXC not detecting 'newuidmap' and 'newgidmap' on the host system, #
#		leading to LXC then falling through to directly setup UID/GID mapping itself #
# DEBUGGING:
#	LXC tools can be used to test the container:
#		lxc-start -P /var/lib/anbox/containers/ -n default -F
#		lxc-info -P /var/lib/anbox/containers/ -n default
#		lxc-stop -P /var/lib/anbox/containers/ -n default
#	/var/lib/anbox/containers/default/default.log	# LXC container log
#	/var/lib/anbox/rootfs/data/system.log		# Android system log
#	ANBOX_LOG_LEVEL=debug anbox session-manager
##
# anbox-container-manager.service does the following:
#	Sets up cgroups and mounts /var/lib/anbox/android.img on LXC path /var/lib/anbox/rootfs/
#	Bind mounts as desktop user	/var/lib/anbox/cache on /var/lib/anbox/rootfs/cache
#					/var/lib/anbox/data on /var/lib/anbox/rootfs/data
# anbox.desktop automatically starts 'anbox session-manger' and launches the windowed Android Application Manager

RDEPEND="
  chromeos-base/arc-base
  chromeos-base/arc-setup
  chromeos-base/selinux-policy

  dev-util/android-tools
	net-firewall/iptables 
  dev-libs/boost:=[threads]
  media-libs/sdl2-image	
  >=app-emulation/lxc-3  
"
#media-libs/swiftshader
#app-emulation/lxc
#app-admin/cgmanager
#app-emulation/lxc[cgmanager]

#	dev-libs/dbus-c++

DEPEND="  
  ${RDEPEND}

	dev-libs/glib:2
	dev-cpp/properties-cpp
	dev-libs/protobuf
	media-libs/glm
  sys-apps/dbus     
  sys-kernel/chromeos-kernel-4_14 
	media-libs/libsdl2[wayland]
	media-libs/mesa[egl,gles2]
	sys-libs/libcap
	test? ( dev-cpp/gtest )
"

#sys-apps/systemd[nat]
#chromeos-kernel-4_14
#	~ANDROID_BINDER_IPC
#	~ASHMEM

CONFIG_CHECK="
	~NAMESPACES
	~IPC_NS
	~NET_NS
	~PID_NS
	~USER_NS
	~UTS_NS
	~BRIDGE
	~IP_NF_IPTABLES
	~IP_NF_MANGLE
	~IP_NF_NAT
	~NF_NAT_MASQUERADE_IPV4
	~NETFILTER_XT_MATCH_COMMENT
	~NETFILTER_XT_TARGET_CHECKSUM
"

pkg_setup() {
	linux-info_pkg_setup
	#python-single-r1_pkg_setup
}

src_prepare() {  
  epatch "${FILESDIR}"/00-without-dbus.patch

	cmake-utils_src_prepare

	! use test && \
		truncate -s0 cmake/FindGMock.cmake tests/CMakeLists.txt
}

src_install() {
	cmake-utils_src_install

	# 'anbox-container-manager.service' is started as root #
	# insinto $(systemd_get_systemunitdir)
	# doins "${FILESDIR}/anbox-container-manager.service"
	# use privileged && \
	# 	sed -e 's:--daemon --data-path:--daemon --privileged --data-path:g' \
	# 		-i $(systemd_get_systemunitdir)/anbox-container-manager.service
	# dosym $(systemd_get_systemunitdir)/anbox-container-manager.service \
	# 	$(systemd_get_systemunitdir)/default.target.wants/anbox-container-manager.service

	# 'anbox0' network interface #
	# insinto $(systemd_get_utildir)/network
	# doins "${FILESDIR}/80-anbox-bridge.network"
	# doins "${FILESDIR}/80-anbox-bridge.netdev"
	# dosym $(systemd_get_systemunitdir)/systemd-networkd.service \
	# 	$(systemd_get_systemunitdir)/default.target.wants/systemd-networkd.service

	# 'anbox-launch' wrapper script to start 'session-manager' and anbox appmgr #
	exeinto /usr/bin
	doexe "${FILESDIR}/anbox-launch"
  # doexe "${FILESDIR}/anbox-container"
  # doexe "${FILESDIR}/anbox-session"

	# anbox.desktop and icon #
	insinto /usr/share/applications
	doins "${FILESDIR}/anbox.desktop"
	insinto /usr/share/pixmaps
	newins snap/gui/icon.png anbox.png

	insinto /var/lib/anbox  
  #insinto /opt/anbox
#	newins "${DISTDIR}/android_${IMG_REVISION}_amd64.img" android.img
	newins "${DISTDIR}/android_amd64.img" android.img
  doins "${FILESDIR}"/config.json

	# udev_dorules "${FILESDIR}/99-anbox.rules"

  insinto /etc/init
	doins "${FILESDIR}"/anbox-init.conf
}

# src_compile(){
#   echo $CXXFLAGS  
# }

src_configure(){
  filter-flags -fno-exceptions

  cmake-utils_src_configure
}

pkg_postinst() {  
	if ! use privileged; then
		if [ ! -e /etc/subuid ] || [ ! -e /etc/subuid ]; then
			elog "Oops...no /etc/subuid or /etc/subgid files have been detected on the system"
			elog "LXC unprivileged container support requires correct setup of /etc/subuid and /etc/subgid files so that it can use"
			elog " sys-apps/shadow's 'newuidmap' and 'newgidmap' to map UIDs/GIDs from the host to the container"
			elog " See here -> https://stgraber.org/2014/01/17/lxc-1-0-unprivileged-containers/"
			elog "TLDR? Here is a working example of /etc/subgid and /etc/subuid files (both have the same content):"
			elog "	root:100000:65536"
			elog "	root:1000:2"
			elog "	<username>:100000:65536"
			elog "	<username>:1000:2"
		fi
	fi
}
