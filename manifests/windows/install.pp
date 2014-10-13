# == Class consul::intall
#
class consul::windows::install {

  class { 'windows::nssm': }

  if $consul::data_dir {
    file { "${consul::data_dir}":
      ensure => 'directory',
      owner => $consul::user,
      group => 'Administrators',
      mode  => '0755',
    }
  }

  if $consul::install_method == 'url' {
     file { "${consul::bin_dir}":
      ensure => 'directory',
    }->
    vp_artifactory::artifact { "Download consul-${consul::version} binary":
      ensure => present,
      gav => "vp-third-party-libraries/thirdparty:consul:${consul::version}",
      output => "${consul::bin_dir}\\consul.exe",
      packaging => "exe"
    }->
    file { "${consul::bin_dir}\\consul.exe":
      owner => $consul::user,
      group => 'Administrators',
      mode  => '0555',
    }

    if ($consul::ui_dir and $consul::data_dir) {
      file { "${consul::data_dir}/${consul::version}_web_ui":
        ensure => 'directory',
        owner  => $consul::user,
        group  => 'Administrators',
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
      file { "${consul::bin_dir}\\consul.bat":
        mode  => '0555',
        group => 'Administrators', 
        content => regsubst(template("consul/consul.bat.erb"), '\n', "\r\n", 'EMG')
      }->
      exec { "Runs batch file to create consul service":
        command => "cmd /C \"${consul::bin_dir}\\consul.bat\" ",
        path    => "c:\\windows\\system32\\" 
      }
    }
    default : {
      fail("I don't know how to create an init script for style $init_style")
    }
  }

  $user_password = 'S0m3L337P4SS'

  if $consul::manage_user {
    user { $consul::user:
      ensure => 'present',
      password   => $user_password,
    }
  }
  if $consul::manage_group {
    group { 'Administrators':
      ensure => 'present',
    }
  }
}
