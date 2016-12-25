# profile/shibboleth/idp.pp
# Manage Shibboleth IdP Service
#

class shibidp::jetty inherits shibidp {

  $java_home = $::profile::java::java_home
  $jetty_home = $::jetty::home

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

  archive { "/tmp/slf4j-${shibidp::slf4j_version}.tar.gz":
    source        => "http://slf4j.org/dist/slf4j-${shibidp::slf4j_version}.tar.gz",
    extract       => true,
    extract_path  => '/tmp',
    cleanup       => false,
    checksum_type => $shibidp::slf4j_checksum_type,
    checksum      => $shibidp::slf4j_checksum,
    creates       => "/tmp/slf4j-${shibidp::slf4j_version}/README.md",
  }

  file { "${shibidp::idp_jetty_base}/lib/logging/slf4j-api.jar":
    ensure  => file,
    owner   => $shibidp::shib_user,
    group   => $shibidp::shib_group,
    mode    => '0644',
    source  => "/tmp/slf4j-${shibidp::slf4j_version}/slf4j-api-${shibidp::slf4j_version}.jar",
    require => Archive["/tmp/slf4j-${shibidp::slf4j_version}.tar.gz"],
  }
  
  archive { "/tmp/logback-${shibidp::logback_version}.tar.gz":
    source        => "http://logback.qos.ch/dist/logback-${shibidp::logback_version}.tar.gz",
    extract       => true,
    extract_path  => '/tmp',
    cleanup       => false,
    checksum_type => $shibidp::logback_checksum_type,
    checksum      => $shibidp::logback_checksum,
    creates       => "/tmp/logback-${shibidp::logback_version}/README.txt",
  }
  
  ['logback-access', 'logback-classic', 'logback-core'].each |$jar_file| {
    file { "${shibidp::idp_jetty_base}/lib/logging/${jar_file}.jar":
      ensure  => file,
      owner   => $shibidp::shib_user,
      group   => $shibidp::shib_group,
      mode    => '0644',
      source  => "/tmp/logback-${shibidp::logback_version}/${jar_file}-${shibidp::logback_version}.jar",
      require => Archive["/tmp/logback-${shibidp::logback_version}.tar.gz"],
      #notify  => Service['jetty'],
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
      #notify  => Service['jetty'],
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
