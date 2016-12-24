# profile/shibboleth/idp.pp
# Manage Shibboleth IdP Service
#

class shibidp (
  $shib_idp_version      = '3.2.1',
  $shib_user             = 'shib',
  $shib_group            = 'shib',
  $shib_src_dir          = '/root/idpv3-source',
  $shib_install_base     = '/opt/shibboleth-idp',
  $idp_jetty_base        = '/opt/idp_jetty',
  $idp_jetty_user        = 'jetty',
  $idp_entity_id         = 'https://shibvm-idp.miamioh.edu:21443/idp/shibboleth',
  
  $ldap_url              = 'ldaps://ldapt.muohio.edu:636',
  $ldap_base_dn          = 'ou=people,dc=muohio,dc=edu',
  $ldap_bind_dn          = 'uid=shibboleth,ou=ldapids,dc=muohio,dc=edu',
  $ldap_bind_pw          = cache_data('cache_data/shibboleth', "open_ldap_${::environment}_password", random_password(32)),
  $ldap_dn_format        = 'uid=%s,ou=people,dc=muohio,dc=edu',
  $ldap_return_attributes = ['uid', 'eduPersonPrincipalName'],
  
  $ad_ldap_url           = 'ldaps://storm.miamioh.edu:636',
  $ad_base_dn            = 'ou=people,dc=it,dc=muohio,dc=edu',
  $ad_bind_dn            = 'shibboleth@it.muohio.edu',
  $ad_bind_pw            = cache_data('cache_data/shibboleth', "ad_ldap_${::environment}_password", random_password(32)),
  $ad_return_attributes  = ['memberOf', 'extensionAttribute5'],

  $slf4j_version         = '1.7.22',
  $slf4j_checksum_type   = 'md5',
  $slf4j_checksum        = '7ab9c81ec1881fce4d809bbc48008eb6',
  $logback_version       = '1.1.8',
  $logback_checksum_type = 'md5',
  $logback_checksum      = '0466114001b29808aeee2bf665e1b2f8',
  $cas_server_url        = 'https://idptest.miamioh.edu/cas',
  $idp_server_url        = 'https://shibvm-idp.miamioh.edu:21443',
  $idp_server_name       = 'shibvm-idp.miamioh.edu',
  $ks_password           = cache_data('cache_data/shibboleth', "keystore_${::environment}_password", random_password(32)),
  $ldap_cert_type        = 'test',
){

  ensure_packages('unzip')

  $exec_path = '/usr/local/bin:/bin:/usr/bin:/usr/local/sbin:/usr/sbin:/sbin:'
  $java_home = $::profile::java::java_home
  $jetty_home = $::jetty::home

  file { $shib_src_dir:
    ensure => directory,
  }

  ####################################
  # The Shibboleth IdP uses the Java unlimited strength crypto libraries.
  # We have the required files as an artifact, just download and install.
  archive { "${shib_src_dir}/UnlimitedJCEPolicyJDK8.tar.gz":
    source       => "${profile::core::params::miamioh_env_artifacts_uri}/shibboleth/UnlimitedJCEPolicyJDK8.tar.gz",
    extract      => true,
    extract_path => $shib_src_dir,
    cleanup      => false,
    creates      => "${shib_src_dir}/UnlimitedJCEPolicyJDK8.tar.gz",
    require      => File[$shib_src_dir],
  }

  ['local_policy.jar', 'US_export_policy.jar',
  ].each |$jar_file| {
    file { "${java_home}/jre/lib/security/${jar_file}":
      ensure  => file,
      owner   => $shib_user,
      group   => $shib_group,
      mode    => '0744',
      source  => "${shib_src_dir}/UnlimitedJCEPolicyJDK8/${jar_file}",
      require => Archive["${shib_src_dir}/UnlimitedJCEPolicyJDK8.tar.gz"],
    }
  }
  ####################################

  ####################################
  # The following sets up the Shibboleth IdP installation.

  file { $shib_install_base:
    ensure  => directory,
    owner   => $shib_user,
    group   => $shib_group,
    mode    => '0744',
    require => File[$shib_src_dir],
  } ->

  archive { "/tmp/shibboleth-identity-provider-${shib_idp_version}.tar.gz":
    source       => "https://shibboleth.net/downloads/identity-provider/${shib_idp_version}/shibboleth-identity-provider-${shib_idp_version}.tar.gz",
    extract      => true,
    extract_path => $shib_src_dir,
    cleanup      => true,
    creates      => "${shib_src_dir}/shibboleth-identity-provider-${shib_idp_version}/LICENSE.txt",
    notify       => Exec['shibboleth idp install'],
  }

  # The install and merge properties contain settings which influence the
  # Shibboleth installation process.
  ['idp.install.properties', 'idp.merge.properties'].each |$file| {
    file { "${shib_src_dir}/${file}":
      ensure  => file,
      content => template("${module_name}/shibboleth/${file}.erb"),
      require => Archive["/tmp/shibboleth-identity-provider-${shib_idp_version}.tar.gz"],
      notify  => Exec['shibboleth idp install'],
    }
  }

  # Install the signing and encryption certs. These are used internally, not
  # through the web front end. Any change requires coordination with InCommon
  # and our service providers.
  ['idp-encryption', 'idp-signing'].each |$type| {
    $keypair = cache_data('cache_data/shibboleth', "${type}_${::environment}_keypair", {cert => undef, key => undef})

    file { "${shib_install_base}/credentials/${type}.crt":
      ensure  => file,
      content => template("${module_name}/shibboleth/credentials/cert.erb"),
      owner   => $shib_user,
      group   => $shib_group,
      mode    => '0644',
      require => Exec['shibboleth idp install'],
      notify  => Exec['shibboleth idp build'],
    }

    file { "${shib_install_base}/credentials/${type}.key":
      ensure  => file,
      content => template("${module_name}/shibboleth/credentials/key.erb"),
      owner   => $shib_user,
      group   => $shib_group,
      mode    => '0600',
      require => Exec['shibboleth idp install'],
      notify  => Exec['shibboleth idp build'],
    }
  }

  ['ldap', 'ad',
  ].each |$directory| {
    file { "${shib_install_base}/credentials/${directory}-server.crt":
      ensure  => file,
      source  => "puppet:///modules/${module_name}/${directory}-${ldap_cert_type}-server.crt",
      owner   => $shib_user,
      group   => $shib_group,
      mode    => '0644',
      require => Exec['shibboleth idp install'],
      notify  => Exec['shibboleth idp build'],
    }
  }

  # The same keypairs appear in the idp-metadata.xml file, which must be
  # updated any time the certs change.
  $signing_keypair = cache_data('cache_data/shibboleth', "idp-signing_${::environment}_keypair", {cert => undef, key => undef})
  $encryption_keypair = cache_data('cache_data/shibboleth', "idp-encryption_${::environment}_keypair", {cert => undef, key => undef})
  file { "${shib_install_base}/metadata/idp-metadata.xml":
    ensure  => file,
    content => template("${module_name}/shibboleth/metadata/idp-metadata.xml.erb"),
    require => Exec['shibboleth idp install'],
    notify  => Exec['shibboleth idp build'],
  }

  # Manage the SP metadata backing files. These are provided by some SPs
  # out-of-band.
  ['SANS-metadata.xml', 'Mentis-metadata.xml',
    'WindowsAzureAD-metadata.xml', 'OracleCRM-metadata.xml',
    'Cascade-metadata.xml', 'TestShib-metadata.xml',
    'eShipGlobal-metadata.xml', 'TMS-metadata.xml',
    'Gartner-metadata.xml', 'WeComply-metadata.xml',
  ].each |$file| {
    file { "${shib_install_base}/metadata/${file}":
      ensure  => file,
      owner   => $shib_user,
      group   => $shib_group,
      mode    => '0644',
      source  => "puppet:///modules/${module_name}/metadata/${file}",
      require => Exec['shibboleth idp install'],
    }
  }

  # Fetch InCommon public signing key for verifying the metadata
  $dl_command = "/usr/bin/curl -s https://ds.incommon.org/certs/inc-md-cert.pem \
            | /usr/bin/tee ${shib_install_base}/credentials/inc-md-cert.pem \
            | /usr/bin/openssl x509 -sha1 -fingerprint -noout"
  exec { 'incommon signing key':
    command => $dl_command,
    cwd     => $shib_install_base,
    path    => $::path,
    unless  => "test -f ${shib_install_base}/credentials/inc-md-cert.pem",
    require => Exec['shibboleth idp install'],
  }

  # Fetch and install the ShibCAS component.
  archive { '/tmp/master.zip':
    source       => 'https://github.com/Unicon/shib-cas-authn3/archive/master.zip',
    extract      => true,
    extract_path => '/tmp',
    cleanup      => true,
    creates      => '/tmp/shib-cas-authn3-master/README.md',
  } ->

  file { "${shib_install_base}/flows/authn/Shibcas":
    ensure  => directory,
    owner   => $shib_user,
    group   => $shib_group,
    mode    => '0644',
    recurse => true,
    source  => '/tmp/shib-cas-authn3-master/IDP_HOME/flows/authn/Shibcas',
    require => Exec['shibboleth idp install'],
    notify  => Exec['shibboleth idp build'],
  }

  archive { "${shib_install_base}/edit-webapp/WEB-INF/lib/shib-cas-authenticator-3.0.0.jar":
    source  => 'https://github.com/Unicon/shib-cas-authn3/releases/download/v3.0.0/shib-cas-authenticator-3.0.0.jar',
    extract => false,
    cleanup => false,
    creates => "${shib_install_base}/edit-webapp/WEB-INF/lib/shib-cas-authenticator-3.0.0.jar",
    require => Exec['shibboleth idp install'],
    notify  => Exec['shibboleth idp build'],
  }

  # This one does not support https, so verify the md5 hash
  archive { "${shib_install_base}/edit-webapp/WEB-INF/lib/cas-client-core-3.4.1.jar":
    source        => 'http://central.maven.org/maven2/org/jasig/cas/client/cas-client-core/3.4.1/cas-client-core-3.4.1.jar',
    extract       => false,
    cleanup       => false,
    checksum_type => 'md5',
    checksum      => '0cde05fb6892018f19913eb6f3081758',
    creates       => "${shib_install_base}/edit-webapp/WEB-INF/lib/cas-client-core-3.4.1.jar",
    require       => Exec['shibboleth idp install'],
    notify        => Exec['shibboleth idp build'],
  }

  # Render the Shibboleth configuration. These are run time and not used
  # during the build process. It should restart Jetty, though.
  ['ldap.properties', 'idp.properties', 'metadata-providers.xml', 'authn/general-authn.xml',
    'attribute-resolver.xml', 'relying-party.xml', 'attribute-filter.xml',
  ].each |$config_file| {
    file { "${shib_install_base}/conf/${config_file}":
      ensure  => file,
      owner   => $shib_user,
      group   => $shib_group,
      mode    => '0600',
      content => template("${module_name}/shibboleth/conf/${config_file}.erb"),
      require => [File[$shib_install_base], Exec['shibboleth idp install']],
      notify  => Exec['shibboleth idp build'],
    }
  }

  # The install should run only once for a given version. This creates
  # the Shibboleth install base (by default /opt/shibboleth-dip).
  exec { 'shibboleth idp install':
    command     => "${shib_src_dir}/shibboleth-identity-provider-${shib_idp_version}/bin/install.sh  -Didp.property.file=${shib_src_dir}/idp.install.properties",
    cwd         => "${shib_src_dir}/shibboleth-identity-provider-${shib_idp_version}",
    environment => ["JAVA_HOME=${java_home}"],
    path        => "${::path}:${java_home}",
    refreshonly => true,
    unless      => "test -f ${shib_install_base}/war/idp.war",
    #notify      => Service['jetty'],
  }

  # The build will be rerun after certain changes in the source material. This
  # expects the Shibboleth install base to be present and will build  a new war file
  # based on the contents.
  exec { 'shibboleth idp build':
    command     => "${shib_install_base}/bin/build.sh -Didp.target.dir=${shib_install_base}",
    cwd         => $shib_install_base,
    environment => ["JAVA_HOME=${java_home}"],
    path        => "${::path}:${java_home}",
    refreshonly => true,
    #notify      => Service['jetty'],
  }

  # TODO Why does notifying the jetty service cause a dependency cycle in puppet?
  # TODO Why is the jetty service running as root?

  ####################################

  ####################################
  # Create the IdP Jetty base. This uses a directory of files
  # which are overridden by templates when necessary.
  $jetty_files = [ "${idp_jetty_base}/lib", "${idp_jetty_base}/lib/logging",
  "${idp_jetty_base}/logs", "${idp_jetty_base}/lib/ext", "${idp_jetty_base}/tmp" ]

  file { $idp_jetty_base:
    ensure  => directory,
    owner   => $shib_user,
    group   => $shib_group,
    mode    => '0744',
    recurse => true,
    source  => "puppet:///modules/${module_name}/jetty_base",
  } ->

  file { $jetty_files:
    ensure  => directory,
    owner   => $shib_user,
    group   => $shib_group,
    mode    => '0744',
    recurse => true,
  }

  # TODO Calculate and add checksums
  # https://forge.puppet.com/puppet/archive
  archive { "/tmp/slf4j-${slf4j_version}.tar.gz":
    source        => "http://slf4j.org/dist/slf4j-${slf4j_version}.tar.gz",
    extract       => true,
    extract_path  => '/tmp',
    cleanup       => false,
    checksum_type => $slf4j_checksum_type,
    checksum      => $slf4j_checksum,
    creates       => "/tmp/slf4j-${slf4j_version}/README.md",
  }

  file { "${idp_jetty_base}/lib/logging/slf4j-api.jar":
    ensure  => file,
    owner   => $shib_user,
    group   => $shib_group,
    mode    => '0644',
    source  => "/tmp/slf4j-${slf4j_version}/slf4j-api-${slf4j_version}.jar",
    require => Archive["/tmp/slf4j-${slf4j_version}.tar.gz"],
  }
  
  archive { "/tmp/logback-${logback_version}.tar.gz":
    source        => "http://logback.qos.ch/dist/logback-${logback_version}.tar.gz",
    extract       => true,
    extract_path  => '/tmp',
    cleanup       => false,
    checksum_type => $logback_checksum_type,
    checksum      => $logback_checksum,
    creates       => "/tmp/logback-${logback_version}/README.txt",
  }
  
  ['logback-access', 'logback-classic', 'logback-core'].each |$jar_file| {
    file { "${idp_jetty_base}/lib/logging/${jar_file}.jar":
      ensure  => file,
      owner   => $shib_user,
      group   => $shib_group,
      mode    => '0644',
      source  => "/tmp/logback-${logback_version}/${jar_file}-${logback_version}.jar",
      require => Archive["/tmp/logback-${logback_version}.tar.gz"],
      #notify  => Service['jetty'],
    }
  }

  ['start.ini', 'start.d/ssl.ini', 'start.d/http.ini',
  ].each |$config_file| {
    file { "${idp_jetty_base}/${config_file}":
      ensure  => file,
      owner   => $shib_user,
      group   => $shib_group,
      mode    => '0644',
      content => template("${module_name}/jetty_base/${config_file}.erb"),
      require => File[$idp_jetty_base],
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
