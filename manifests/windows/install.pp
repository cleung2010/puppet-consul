# == Class consul::intall
#
class consul::windows::install {

  if $consul::data_dir {
    file { "${consul::data_dir}":
      ensure => 'directory',
      owner => $consul::user,
      group => $consul::group,
      mode  => '0755',
    }
  }

  if $consul::install_method == 'url' {

    ensure_packages(['unzip'])
    staging::file { 'consul.zip':
      source => $consul::download_url
    } ->
    staging::extract { 'consul.zip':
      target  => $consul::bin_dir,
      creates => "${consul::bin_dir}\\consul",
    } ->
    file { "${consul::bin_dir}\\consul":
      owner => 'root',
      group => 'root',
      mode  => '0555',
    }

    if ($consul::ui_dir and $consul::data_dir) {
      file { "${consul::data_dir}/${consul::version}_web_ui":
        ensure => 'directory',
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
      } ->
      staging::deploy { 'consul_web_ui.zip':
        source  => "${consul::ui_download_url}",
        target  => "${consul::data_dir}\\${consul::version}_web_ui",
        creates => "${consul::data_dir}\\${consul::version}_web_ui\\dist",
      }
      file { "${consul::ui_dir}":
        ensure => 'symlink',
        target => "${consul::data_dir}\\${consul::version}_web_ui\\dist",
      }
    }

  } elsif $consul::install_method == 'package' {

    package { $consul::package_name:
      ensure => $consul::package_ensure,
    }

    if $consul::ui_dir {
      package { $consul::ui_package_name:
        ensure => $consul::ui_package_ensure,
      }
    }

  } else {
    fail("The provided install method ${consul::install_method} is invalid")
  }

  case $consul::init_style {
    'bat' : {
      file { 'C:\\consul':
        mode  => '0555',
        group => 'Administrators', 
        content => regsubst(template("consul/consul.bat.erb"), '\n', "\r\n", 'EMG')
      }
    }
    default : {
      fail("I don't know how to create an init script for style $init_style")
    }
  }

  if $consul::manage_user {
    user { $consul::user:
      ensure => 'present',
    }
  }
  if $consul::manage_group {
    group { $consul::group:
      ensure => 'present',
    }
  }
}
