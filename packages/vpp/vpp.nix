{ config, lib, pkgs, ... }:
  let
      app = pkgs.callPackage ./default.nix {};


     vpp-config = pkgs.writeText "startup.conf" ''
        unix {
  nodaemon
  log /var/log/vpp/vpp.log
  full-coredump
  cli-listen /var/run/vpp/cli.sock
  gid vpp

  ## run vpp in the interactive mode
  # interactive

  ## do not use colors in terminal output
  # nocolor

  ## do not display banner
  # nobanner
}

api-trace {
## This stanza controls binary API tracing. Unless there is a very strong reason,
## please leave this feature enabled.
  on
## Additional parameters:
##
## To set the number of binary API trace records in the circular buffer, configure nitems
##
## nitems <nnn>
##
## To save the api message table decode tables, configure a filename. Results in /tmp/<filename>
## Very handy for understanding api message changes between versions, identifying missing
## plugins, and so forth.
##
## save-api-table <filename>
}

api-segment {
  gid vpp
}

socksvr {
  default
}

# memory {
	## Set the main heap size, default is 1G
	# main-heap-size 2G

	## Set the main heap page size. Default page size is OS default page
	## which is in most cases 4K. if different page size is specified VPP
	## will try to allocate main heap by using specified page size.
	## special keyword 'default-hugepage' will use system default hugepage
	## size
	# main-heap-page-size 1G
	## Set the default huge page size.
	# default-hugepage-size 1G
#}

cpu {
	## In the VPP there is one main thread and optionally the user can create worker(s)
	## The main thread and worker thread(s) can be pinned to CPU core(s) manually or automatically

	## Manual pinning of thread(s) to CPU core(s)

	## Set logical CPU core where main thread runs, if main core is not set
	## VPP will use core 1 if available
	# main-core 1

	## Set logical CPU core(s) where worker threads are running
	# corelist-workers 2-3,18-19

	## Automatic pinning of thread(s) to CPU core(s)

	## Sets number of CPU core(s) to be skipped (1 ... N-1)
	## Skipped CPU core(s) are not used for pinning main thread and working thread(s).
	## The main thread is automatically pinned to the first available CPU core and worker(s)
	## are pinned to next free CPU core(s) after core assigned to main thread
	# skip-cores 4

	## Specify a number of workers to be created
	## Workers are pinned to N consecutive CPU cores while skipping "skip-cores" CPU core(s)
	## and main thread's CPU core
	# workers 2

	## Set scheduling policy and priority of main and worker threads

	## Scheduling policy options are: other (SCHED_OTHER), batch (SCHED_BATCH)
	## idle (SCHED_IDLE), fifo (SCHED_FIFO), rr (SCHED_RR)
	# scheduler-policy fifo

	## Scheduling priority is used only for "real-time policies (fifo and rr),
	## and has to be in the range of priorities supported for a particular policy
	# scheduler-priority 50
}

# buffers {
	## Increase number of buffers allocated, needed only in scenarios with
	## large number of interfaces and worker threads. Value is per numa node.
	## Default is 16384 (8192 if running unpriviledged)
	# buffers-per-numa 128000

	## Size of buffer data area
	## Default is 2048
	# default data-size 2048

	## Size of the memory pages allocated for buffer data
	## Default will try 'default-hugepage' then 'default'
	## you can also pass a size in K/M/G e.g. '8M'
	# page-size default-hugepage
# }

# dpdk {
	## Change default settings for all interfaces
	# dev default {
		## Number of receive queues, enables RSS
		## Default is 1
		# num-rx-queues 3

		## Number of transmit queues, Default is equal
		## to number of worker threads or 1 if no workers treads
		# num-tx-queues 3

		## Number of descriptors in transmit and receive rings
		## increasing or reducing number can impact performance
		## Default is 1024 for both rx and tx
		# num-rx-desc 512
		# num-tx-desc 512

		## VLAN strip offload mode for interface
		## Default is off
		# vlan-strip-offload on

		## TCP Segment Offload
		## Default is off
		## To enable TSO, 'enable-tcp-udp-checksum' must be set
		# tso on

		## Devargs
                ## device specific init args
                ## Default is NULL
		# devargs safe-mode-support=1,pipeline-mode-support=1

		## rss-queues
		## set valid rss steering queues
		# rss-queues 0,2,5-7
	# }

	## Whitelist specific interface by specifying PCI address
	# dev 0000:02:00.0

	## Blacklist specific device type by specifying PCI vendor:device
        ## Whitelist entries take precedence
	# blacklist 8086:10fb

	## Set interface name
	# dev 0000:02:00.1 {
	#	name eth0
	# }

	## Whitelist specific interface by specifying PCI address and in
	## addition specify custom parameters for this interface
	# dev 0000:02:00.1 {
	#	num-rx-queues 2
	# }

	## Change UIO driver used by VPP, Options are: igb_uio, vfio-pci,
	## uio_pci_generic or auto (default)
	# uio-driver vfio-pci

	## Disable multi-segment buffers, improves performance but
	## disables Jumbo MTU support
	# no-multi-seg

	## Change hugepages allocation per-socket, needed only if there is need for
	## larger number of mbufs. Default is 256M on each detected CPU socket
	# socket-mem 2048,2048

	## Disables UDP / TCP TX checksum offload. Typically needed for use
	## faster vector PMDs (together with no-multi-seg)
	# no-tx-checksum-offload

	## Enable UDP / TCP TX checksum offload
	## This is the reversed option of 'no-tx-checksum-offload'
	# enable-tcp-udp-checksum

	## Enable/Disable AVX-512 vPMDs
	# max-simd-bitwidth <256|512>
# }

## node variant defaults
#node {

## specify the preferred default variant
#	default	{ variant avx512 }

## specify the preferred variant, for a given node
#	ip4-rewrite { variant avx2 }

#}


# plugins {
	## Adjusting the plugin path depending on where the VPP plugins are
	#	path /ws/vpp/build-root/install-vpp-native/vpp/lib/vpp_plugins

	## Disable all plugins by default and then selectively enable specific plugins
	# plugin default { disable }
	# plugin dpdk_plugin.so { enable }
	# plugin acl_plugin.so { enable }

	## Enable all plugins by default and then selectively disable specific plugins
	# plugin dpdk_plugin.so { disable }
	# plugin acl_plugin.so { disable }
# }

## Statistics Segment
# statseg {
    # socket-name <filename>, name of the stats segment socket
    #     defaults to /run/vpp/stats.sock
    # size <nnn>[KMG], size of the stats segment, defaults to 32mb
    # page-size <nnn>, page size, ie. 2m, defaults to 4k
    # per-node-counters on | off, defaults to none
    # update-interval <f64-seconds>, sets the segment scrape / update interval
# }

## L2 FIB
# l2fib {
    ## l2fib hash table size.
    #  table-size 512M

    ## l2fib hash table number of buckets. Must be power of 2.
    #  num-buckets 524288
# }

## ipsec
# {
   # ip4 {
   ## ipsec for ipv4 tunnel lookup hash number of buckets.
   #  num-buckets 524288
   # }
   # ip6 {
   ## ipsec for ipv6 tunnel lookup hash number of buckets.
   #  num-buckets 524288
   # }
# }

logging {
   ## set default logging level for logging buffer
   ## logging levels: emerg, alert,crit, error, warn, notice, info, debug, disabled
   # default-log-level debug
   ## set default logging level for syslog or stderr output
   default-syslog-log-level debug
   ## Set per-class configuration
   # class dpdk/cryptodev { rate-limit 100 level debug syslog-level error }
}

     '';

  in
  {

  users.users."vpp" = {
  createHome = true;
  isSystemUser = true;
  group = "vpp";
  home = "/home/vpp";
 };

 users.groups."vpp" = {
     members = ["vpp"];
 };


  systemd.services.vpp = {
  description = "vpp";
  after = [ "network.target" ];
  wantedBy = [ "multi-user.target" ];
  serviceConfig = {
	Type="simple";
	/*
	AmbientCapabilities= [ 
		"CAP_NET_ADMIN" 
		"CAP_SYS_ADMIN" 
		"CAP_NET_BIND_SERVICE"
	
	];
	*/
    ExecStart = "${app}/bin/vpp -c ${vpp-config}";
    User = "vpp";
    Group = "vpp";
    };
  };

  environment.systemPackages = [app];

  boot.kernel.sysctl = {
    # Number of 2MB hugepages desired
    "vm.nr_hugepages" = 1024;
	#"vm.nr_hugepages" = 512;

    # Must be greater than or equal to (2 * vm.nr_hugepages).
    "vm.max_map_count" = 3096;
	#"vm.max_map_count" = 2048;

    # All groups allowed to access hugepages
    "vm.hugetlb_shm_group" = 0;

    # Shared Memory Max must be greater or equal to the total size of hugepages.
    # For 2MB pages, TotalHugepageSize = vm.nr_hugepages * 2 * 1024 * 1024
    # If the existing kernel.shmmax setting  (cat /proc/sys/kernel/shmmax)
    # is greater than the calculated TotalHugepageSize then set this parameter
    # to current shmmax value.
    "kernel.shmmax" = 2147483648;
	#"kernel.shmmax" = 1073741824;
  };

}