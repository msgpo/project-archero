项目简介
---------------

archero 是基于 anbox 来替换 arc++ 来实现 chromiumos 中的安卓子系统部分模块。
该项目主要生成两个可执行文件：

* anbox-container 主要用于挂载 android rootfs。程序会随系统启动而启动，以管理员的方式运行于后台。
* anbox-session 主要提供开发者提供测试功能，生产环境不依赖这个程序，在 anbox-container 正常运行的情况下，指定 anbox-session 可以通过系统的进程列表看到相关的 android 进程。 anbox-session 的代码最终是需要集成到 chromium 中的，其中包括了输入输出控制等。

同时也替换了系统中的 /dev/ashmem 和 /dev/binder 两个 android 子系统依赖的驱动。

问题
---------------
anbox-session 在启动过程中，会给系统的 lxc 发送请求，用 lxc 的接口来启动一个 anroid container，目前的问题是在 chromiumos 中 lxc 启动会使用 cgroup 控制系统资源，但是实际情况会请求失败。从而导致容器启动失败。同样的代码可以工作在 archlinux 上面，目前看了一下 chromiumos 的 cgroup 内核依赖，基本是没有问题的，但是 /sys/fs/cgroup 中的目录结构缺不太一样，导致了 lxc 调用 cgroup 找不到相关的正确路径。

解决思路
---------------
chromiumos 本身的子系统并没有使用 lxc 的方式来启动。可以尝试使用 chromiumos 自身的方式来启动。