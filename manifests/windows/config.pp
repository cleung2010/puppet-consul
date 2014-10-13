# == Class consul::config
#
# This class is called from consul
#
class consul::windows::config(
  $purge = true
) {

  $full_path = mkdir_p($consul::config_dir)
  file { $full_path:
    ensure => directory
  }

  file { $consul::config_dir:
    ensure  => 'directory',
    purge   => $purge,
    recurse => $purge,
  } ->
  file { 'config.json':
    path    => "${consul::config_dir}\\config.json",
    content => regsubst(template("consul/config.json.erb"), '\n', "\r\n", 'EMG'),
  }

}
