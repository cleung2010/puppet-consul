# == Class consul::service
#
# This class is meant to be called from consul
# It ensure the service is running
#
class consul::run_service {

  service { 'consul':
    ensure     => $consul::service_ensure,
    enable     => $consul::service_enable,
  }

  if $consul::join_cluster {

    case $::operatingsystem {
      centos, redhat, debian, ubuntu, Fedora: {
        exec { 'join consul cluster':
          cwd         => $consul::config_dir,
          path        => [$consul::bin_dir,'/bin','/usr/bin'],
          command     => "consul join ${consul::join_cluster}",
          onlyif      => 'consul info | grep -P "num_peers\s*=\s*0"',
          subscribe   => Service['consul'],
        }
      }
      windows: {
        exec { 'join consul cluster':
          cwd         => $consul::config_dir,
          path        => $consul::bin_dir,
          command     => "consul join ${consul::join_cluster}",
          onlyif      => 'consul info | findstr /r c:"num_peers *= *0"',
          subscribe   => Service['consul'],
        }
      }
    }
  }

}
