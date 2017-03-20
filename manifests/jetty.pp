# Class: shibboleth_idp::jetty
#
# This class sets up the JETTY_BASE to be used for the IdP
# It DOES NOT install Jetty itself.
#

class shibboleth_idp::jetty (
  $jetty_version          = $shibboleth_idp::params::jetty_version,
  $jetty_home             = $shibboleth_idp::params::jetty_home,
  $jetty_manage_user      = $shibboleth_idp::params::jetty_manage_user,
  $jetty_user             = $shibboleth_idp::params::jetty_user,
  $jetty_user_uid         = undef,
  $jetty_group            = $shibboleth_idp::params::jetty_group,
  $jetty_group_gid        = undef,
  $java_home              = $shibboleth_idp::java_home,
  $jetty_start_minutes    = $shibboleth_idp::params::jetty_start_minutes,
  $src_directory          = $shibboleth_idp::params::shib_src_dir,
) inherits shibboleth_idp {

  validate_integer($jetty_start_minutes)
  # Based on jetty startup script of 'sleep 4' repeated 1..15
  $jetty_start_interval = 4 * $jetty_start_minutes

  $idp_jetty_base = $shibboleth_idp::idp_jetty_base
  $idp_jetty_log_dir = $shibboleth_idp::idp_jetty_log_dir
  $idp_jetty_log_level = $shibboleth_idp::idp_jetty_log_level

  if $jetty_manage_user {
    ensure_resource('user', $jetty_user, {
        managehome => true,
        system     => true,
        gid        => $jetty_group,
        uid        => $jetty_user_uid,
        shell      => '/sbin/nologin',
        home       => "/var/lib/${jetty_user}",
    })

    ensure_resource('group', $jetty_group, {
        ensure => present,
        gid    => $jetty_group_gid,
    })
  }

  archive { "/tmp/jetty-distribution-${jetty_version}.tar.gz":
    source       => "https://repo1.maven.org/maven2/org/eclipse/jetty/jetty-distribution/${jetty_version}/jetty-distribution-${jetty_version}.tar.gz",
    extract      => true,
    extract_path => $jetty_home,
    cleanup      => true,
    creates      => "${jetty_home}/jetty-distribution-${jetty_version}/README.TXT",
    notify       => Class['shibboleth_idp::service'],
  } ->

  file { "${jetty_home}/jetty":
    ensure => 'link',
    target => "${jetty_home}/jetty-distribution-${jetty_version}",
  }

  if $::service_provider == 'systemd' {
    systemd::unit_file { 'jetty.service':
      content => template("${module_name}/jetty/jetty.service.erb"),
      require => File["${jetty_home}/jetty"],
      notify  => Class['shibboleth_idp::service'],
    }
  } else {
    file_line { 'jetty_startup_minutes':
      ensure  => present,
      path    => "${jetty_home}/jetty-distribution-${jetty_version}/bin/jetty.sh",
      line    => "    sleep ${jetty_start_interval}",
      match   => '^    sleep \d+',
      require => File["${jetty_home}/jetty"],
    } ->

    file { '/etc/init.d/jetty':
      ensure => 'link',
      target => "${jetty_home}/jetty-distribution-${jetty_version}/bin/jetty.sh",
    } ->

    file { '/etc/default/jetty':
      ensure  => file,
      content => template("${module_name}/default.erb"),
      notify  => Class['shibboleth_idp::service'],
    }
  }

  ####################################

  ####################################
  # Create the IdP Jetty base. This uses a directory of files
  # which are overridden by templates when necessary.
  $jetty_files = [ "${shibboleth_idp::idp_jetty_base}/lib", "${shibboleth_idp::idp_jetty_base}/lib/logging",
  "${shibboleth_idp::idp_jetty_base}/lib/ext", "${shibboleth_idp::idp_jetty_base}/tmp" ]

  file { $shibboleth_idp::idp_jetty_base:
    ensure  => directory,
    owner   => $shibboleth_idp::shib_user,
    group   => $shibboleth_idp::shib_group,
    mode    => '0644',
    recurse => true,
    source  => "puppet:///modules/${module_name}/jetty_base",
  } ->

  file { $jetty_files:
    ensure  => directory,
    owner   => $shibboleth_idp::shib_user,
    group   => $shibboleth_idp::shib_group,
    mode    => '0750',
    recurse => false,
    notify  => Class['shibboleth_idp::service'],
  } ->

  file { $idp_jetty_log_dir:
    ensure => directory,
    owner  => $shibboleth_idp::shib_user,
    group  => $shibboleth_idp::shib_group,
    mode   => '0750',
  }

  archive { "/tmp/slf4j-${shibboleth_idp::slf4j_version}.tar.gz":
    source        => "http://slf4j.org/dist/slf4j-${shibboleth_idp::slf4j_version}.tar.gz",
    extract       => true,
    extract_path  => $src_directory,
    cleanup       => true,
    checksum_type => $shibboleth_idp::slf4j_checksum_type,
    checksum      => $shibboleth_idp::slf4j_checksum,
    creates       => "${src_directory}/slf4j-${shibboleth_idp::slf4j_version}/README.md",
  }

  file { "${shibboleth_idp::idp_jetty_base}/lib/logging/slf4j-api.jar":
    ensure  => file,
    owner   => $shibboleth_idp::shib_user,
    group   => $shibboleth_idp::shib_group,
    mode    => '0644',
    source  => "${src_directory}/slf4j-${shibboleth_idp::slf4j_version}/slf4j-api-${shibboleth_idp::slf4j_version}.jar",
    require => Archive["/tmp/slf4j-${shibboleth_idp::slf4j_version}.tar.gz"],
  }

  archive { "/tmp/logback-${shibboleth_idp::logback_version}.tar.gz":
    source        => "http://logback.qos.ch/dist/logback-${shibboleth_idp::logback_version}.tar.gz",
    extract       => true,
    extract_path  => $src_directory,
    cleanup       => true,
    checksum_type => $shibboleth_idp::logback_checksum_type,
    checksum      => $shibboleth_idp::logback_checksum,
    creates       => "${src_directory}/logback-${shibboleth_idp::logback_version}/README.txt",
  }

  ['logback-access', 'logback-classic', 'logback-core'].each |$jar_file| {
    file { "${shibboleth_idp::idp_jetty_base}/lib/logging/${jar_file}.jar":
      ensure  => file,
      owner   => $shibboleth_idp::shib_user,
      group   => $shibboleth_idp::shib_group,
      mode    => '0644',
      source  => "${src_directory}/logback-${shibboleth_idp::logback_version}/${jar_file}-${shibboleth_idp::logback_version}.jar",
      require => Archive["/tmp/logback-${shibboleth_idp::logback_version}.tar.gz"],
      notify  => Class['shibboleth_idp::service'],
    }
  }

  ['start.ini', 'start.d/ssl.ini', 'start.d/http.ini',
    'resources/logback.xml', 'resources/logback-access.xml',
  ].each |$config_file| {
    file { "${shibboleth_idp::idp_jetty_base}/${config_file}":
      ensure  => file,
      owner   => $shibboleth_idp::shib_user,
      group   => $shibboleth_idp::shib_group,
      mode    => '0644',
      content => template("${module_name}/jetty_base/${config_file}.erb"),
      require => File[$shibboleth_idp::idp_jetty_base],
      notify  => Class['shibboleth_idp::service'],
    }
  }

  ####################################

  ####################################
  # Set up shell variables
  profiled::script { 'jetty-idp.sh':
    ensure  => file,
    content => template("${module_name}/shib-idp-profile.sh.erb"),
    shell   => 'absent',
  }

  ####################################

}
