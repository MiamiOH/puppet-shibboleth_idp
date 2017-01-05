# Class: shibidp::jetty
#
# This class sets up the JETTY_BASE to be used for the IdP
# It DOES NOT install Jetty itself.
#

class shibidp::jetty (
  $jetty_version          = $shibidp::params::jetty_version,
  $jetty_home             = $shibidp::params::jetty_home,
  $jetty_manage_user      = $shibidp::params::jetty_manage_user,
  $jetty_user             = $shibidp::params::jetty_user,
  $jetty_group            = $shibidp::params::jetty_group,
  $jetty_service_ensure   = $shibidp::params::jetty_service_ensure,
  $jetty_java_home        = $shibidp::params::jetty_java_home,
) inherits shibidp {

  $java_home = $jetty_java_home

  if $jetty_manage_user {
    ensure_resource('user', $jetty_user, {
        managehome => true,
        system     => true,
        gid        => jetty_group,
        shell      => '/sbin/nologin',
    })

    ensure_resource('group', jetty_group, {
        ensure => present
    })
  }

  archive { "/usr/local/src/jetty-distribution-${jetty_version}.tar.gz":
    source       => "https://repo1.maven.org/maven2/org/eclipse/jetty/jetty-distribution/${jetty_version}/jetty-distribution-${jetty_version}.tar.gz",
    extract      => true,
    extract_path => $jetty_home,
    cleanup      => false,
    creates      => "${jetty_home}/jetty-distribution-${jetty_version}/README.TXT",
    notify       => Service['jetty'],
  } ->

  file { "${jetty_home}/jetty":
    ensure => 'link',
    target => "${jetty_home}/jetty-distribution-${jetty_version}",
  } ->

  file { '/var/log/jetty':
    ensure => "${jetty_home}/jetty/logs",
  } ->

  file { '/etc/init.d/jetty':
    ensure => "${jetty_home}/jetty-distribution-${jetty_version}/bin/jetty.sh",
  }

  if $::service_provider == 'systemd' {
    # systemd::unit_file { 'jetty.service':
    #   content => template("${module_name}/jetty.service.erb"),
    #   require => File['/etc/init.d/jetty'],
    #   before => Service['jetty'],
    # }
    file { '/usr/lib/systemd/system/jetty.service':
      ensure  => file,
      owner   => 'root',
      group   => 'root',
      mode    => '0644',
      content => template("${module_name}/jetty/jetty.service.erb"),
    }
  }

  service { 'jetty':
    ensure     => $jetty_service_ensure,
    enable     => true,
    hasstatus  => false,
    hasrestart => true,
  }

  # TODO Why does notifying the jetty service cause a dependency cycle in puppet?
  # TODO Why is the jetty service running as root?

  ####################################

  ####################################
  # Create the IdP Jetty base. This uses a directory of files
  # which are overridden by templates when necessary.
  $jetty_files = [ "${shibidp::idp_jetty_base}/lib", "${shibidp::idp_jetty_base}/lib/logging",
  "${shibidp::idp_jetty_base}/logs", "${shibidp::idp_jetty_base}/lib/ext", "${shibidp::idp_jetty_base}/tmp" ]

  file { $shibidp::idp_jetty_base:
    ensure  => directory,
    owner   => $shibidp::shib_user,
    group   => $shibidp::shib_group,
    mode    => '0744',
    recurse => true,
    source  => "puppet:///modules/${module_name}/jetty_base",
  } ->

  file { $jetty_files:
    ensure  => directory,
    owner   => $shibidp::shib_user,
    group   => $shibidp::shib_group,
    mode    => '0744',
    recurse => true,
  }

  archive { "/usr/local/src/slf4j-${shibidp::slf4j_version}.tar.gz":
    source        => "http://slf4j.org/dist/slf4j-${shibidp::slf4j_version}.tar.gz",
    extract       => true,
    extract_path  => '/usr/local/src',
    cleanup       => false,
    checksum_type => $shibidp::slf4j_checksum_type,
    checksum      => $shibidp::slf4j_checksum,
    creates       => "/usr/local/src/slf4j-${shibidp::slf4j_version}/README.md",
  }

  file { "${shibidp::idp_jetty_base}/lib/logging/slf4j-api.jar":
    ensure  => file,
    owner   => $shibidp::shib_user,
    group   => $shibidp::shib_group,
    mode    => '0644',
    source  => "/usr/local/src/slf4j-${shibidp::slf4j_version}/slf4j-api-${shibidp::slf4j_version}.jar",
    require => Archive["/usr/local/src/slf4j-${shibidp::slf4j_version}.tar.gz"],
  }
  
  archive { "/usr/local/src/logback-${shibidp::logback_version}.tar.gz":
    source        => "http://logback.qos.ch/dist/logback-${shibidp::logback_version}.tar.gz",
    extract       => true,
    extract_path  => '/usr/local/src',
    cleanup       => false,
    checksum_type => $shibidp::logback_checksum_type,
    checksum      => $shibidp::logback_checksum,
    creates       => "/usr/local/src/logback-${shibidp::logback_version}/README.txt",
  }
  
  ['logback-access', 'logback-classic', 'logback-core'].each |$jar_file| {
    file { "${shibidp::idp_jetty_base}/lib/logging/${jar_file}.jar":
      ensure  => file,
      owner   => $shibidp::shib_user,
      group   => $shibidp::shib_group,
      mode    => '0644',
      source  => "/usr/local/src/logback-${shibidp::logback_version}/${jar_file}-${shibidp::logback_version}.jar",
      require => Archive["/usr/local/src/logback-${shibidp::logback_version}.tar.gz"],
    }
  }

  ['start.ini', 'start.d/ssl.ini', 'start.d/http.ini',
  ].each |$config_file| {
    file { "${shibidp::idp_jetty_base}/${config_file}":
      ensure  => file,
      owner   => $shibidp::shib_user,
      group   => $shibidp::shib_group,
      mode    => '0644',
      content => template("${module_name}/jetty_base/${config_file}.erb"),
      require => File[$shibidp::idp_jetty_base],
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

  file { '/etc/default/jetty':
    ensure  => file,
    content => template("${module_name}/default.erb"),
  }

  ####################################

}
