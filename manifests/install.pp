# profile/shibboleth/idp.pp
# Manage Shibboleth IdP Service
#

class shibidp::install inherits shibidp {

  ensure_packages('unzip')

  $exec_path = '/usr/local/bin:/bin:/usr/bin:/usr/local/sbin:/usr/sbin:/sbin:'
  $java_home = $::profile::java::java_home

  file { $shibidp::shib_src_dir:
    ensure => directory,
  }

  ####################################
  # The Shibboleth IdP uses the Java unlimited strength crypto libraries.
  # We have the required files as an artifact, just download and install.
  archive { "${shibidp::shib_src_dir}/UnlimitedJCEPolicyJDK8.tar.gz":
    source       => "${profile::core::params::miamioh_env_artifacts_uri}/shibboleth/UnlimitedJCEPolicyJDK8.tar.gz",
    extract      => true,
    extract_path => $shibidp::shib_src_dir,
    cleanup      => false,
    creates      => "${shibidp::shib_src_dir}/UnlimitedJCEPolicyJDK8.tar.gz",
    require      => File[$shibidp::shib_src_dir],
  }

  ['local_policy.jar', 'US_export_policy.jar',
  ].each |$jar_file| {
    file { "${java_home}/jre/lib/security/${jar_file}":
      ensure  => file,
      owner   => $shibidp::shib_user,
      group   => $shibidp::shib_group,
      mode    => '0744',
      source  => "${shibidp::shib_src_dir}/UnlimitedJCEPolicyJDK8/${jar_file}",
      require => Archive["${shibidp::shib_src_dir}/UnlimitedJCEPolicyJDK8.tar.gz"],
    }
  }
  ####################################

  ####################################
  # The following sets up the Shibboleth IdP installation.

  file { $shibidp::shib_install_base:
    ensure  => directory,
    owner   => $shibidp::shib_user,
    group   => $shibidp::shib_group,
    mode    => '0744',
    require => File[$shibidp::shib_src_dir],
  } ->

  archive { "/tmp/shibboleth-identity-provider-${shibidp::shib_idp_version}.tar.gz":
    source       => "https://shibboleth.net/downloads/identity-provider/${shibidp::shib_idp_version}/shibboleth-identity-provider-${shibidp::shib_idp_version}.tar.gz",
    extract      => true,
    extract_path => $shibidp::shib_src_dir,
    cleanup      => true,
    creates      => "${shibidp::shib_src_dir}/shibboleth-identity-provider-${shibidp::shib_idp_version}/LICENSE.txt",
    notify       => Exec['shibboleth idp install'],
  }

  # The install and merge properties contain settings which influence the
  # Shibboleth installation process.
  ['idp.install.properties', 'idp.merge.properties'].each |$file| {
    file { "${shibidp::shib_src_dir}/${file}":
      ensure  => file,
      content => template("${module_name}/shibboleth/${file}.erb"),
      require => Archive["/tmp/shibboleth-identity-provider-${shibidp::shib_idp_version}.tar.gz"],
      notify  => Exec['shibboleth idp install'],
    }
  }

  # Install the signing and encryption certs. These are used internally, not
  # through the web front end. Any change requires coordination with InCommon
  # and our service providers.
  ['idp-encryption', 'idp-signing'].each |$type| {
    $keypair = cache_data('cache_data/shibboleth', "${type}_${::environment}_keypair", {cert => undef, key => undef})

    file { "${shibidp::shib_install_base}/credentials/${type}.crt":
      ensure  => file,
      content => template("${module_name}/shibboleth/credentials/cert.erb"),
      owner   => $shibidp::shib_user,
      group   => $shibidp::shib_group,
      mode    => '0644',
      require => Exec['shibboleth idp install'],
      notify  => Exec['shibboleth idp build'],
    }

    file { "${shibidp::shib_install_base}/credentials/${type}.key":
      ensure  => file,
      content => template("${module_name}/shibboleth/credentials/key.erb"),
      owner   => $shibidp::shib_user,
      group   => $shibidp::shib_group,
      mode    => '0600',
      require => Exec['shibboleth idp install'],
      notify  => Exec['shibboleth idp build'],
    }
  }

  # These certs are required for the connections to OpenLDAP and AD to be
  # trusted. Run:
  #  openssl s_client -showcerts -connect ldap.miamioh.edu:636
  # and take the copy the first cert in the chain.
  ['ldap', 'ad',
  ].each |$directory| {
    file { "${shibidp::shib_install_base}/credentials/${directory}-server.crt":
      ensure  => file,
      source  => "puppet:///modules/${module_name}/${directory}-${shibidp::ldap_cert_type}-server.crt",
      owner   => $shibidp::shib_user,
      group   => $shibidp::shib_group,
      mode    => '0644',
      require => Exec['shibboleth idp install'],
      notify  => Exec['shibboleth idp build'],
    }
  }

  # This is the InCommon signing key public cert used to validate the downloaded
  # InCommon metadata. The metadata-providers.xml config contains instructions
  # for acquiring the cert and the configuration for the automated refresh.
  file { "${shibidp::shib_install_base}/credentials/inc-md-cert.pem":
    ensure  => file,
    source  => "puppet:///modules/${module_name}/inc-md-cert.pem",
    owner   => $shibidp::shib_user,
    group   => $shibidp::shib_group,
    mode    => '0644',
    require => Exec['shibboleth idp install'],
    notify  => Exec['shibboleth idp build'],
  }

  # The same keypairs appear in the idp-metadata.xml file, which must be
  # updated any time the certs change.
  $signing_keypair = cache_data('cache_data/shibboleth', "idp-signing_${::environment}_keypair", {cert => undef, key => undef})
  $encryption_keypair = cache_data('cache_data/shibboleth', "idp-encryption_${::environment}_keypair", {cert => undef, key => undef})
  file { "${shibidp::shib_install_base}/metadata/idp-metadata.xml":
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
    file { "${shibidp::shib_install_base}/metadata/${file}":
      ensure  => file,
      owner   => $shibidp::shib_user,
      group   => $shibidp::shib_group,
      mode    => '0644',
      source  => "puppet:///modules/${module_name}/metadata/${file}",
      require => Exec['shibboleth idp install'],
    }
  }

  # Fetch and install the ShibCAS component.
  archive { '/tmp/master.zip':
    source       => 'https://github.com/Unicon/shib-cas-authn3/archive/master.zip',
    extract      => true,
    extract_path => '/tmp',
    cleanup      => true,
    creates      => '/tmp/shib-cas-authn3-master/README.md',
  } ->

  file { "${shibidp::shib_install_base}/flows/authn/Shibcas":
    ensure  => directory,
    owner   => $shibidp::shib_user,
    group   => $shibidp::shib_group,
    mode    => '0644',
    recurse => true,
    source  => '/tmp/shib-cas-authn3-master/IDP_HOME/flows/authn/Shibcas',
    require => Exec['shibboleth idp install'],
    notify  => Exec['shibboleth idp build'],
  }

  archive { "${shibidp::shib_install_base}/edit-webapp/WEB-INF/lib/shib-cas-authenticator-3.0.0.jar":
    source  => 'https://github.com/Unicon/shib-cas-authn3/releases/download/v3.0.0/shib-cas-authenticator-3.0.0.jar',
    extract => false,
    cleanup => false,
    creates => "${shibidp::shib_install_base}/edit-webapp/WEB-INF/lib/shib-cas-authenticator-3.0.0.jar",
    require => Exec['shibboleth idp install'],
    notify  => Exec['shibboleth idp build'],
  }

  # This one does not support https, so verify the md5 hash
  archive { "${shibidp::shib_install_base}/edit-webapp/WEB-INF/lib/cas-client-core-3.4.1.jar":
    source        => 'http://central.maven.org/maven2/org/jasig/cas/client/cas-client-core/3.4.1/cas-client-core-3.4.1.jar',
    extract       => false,
    cleanup       => false,
    checksum_type => 'md5',
    checksum      => '0cde05fb6892018f19913eb6f3081758',
    creates       => "${shibidp::shib_install_base}/edit-webapp/WEB-INF/lib/cas-client-core-3.4.1.jar",
    require       => Exec['shibboleth idp install'],
    notify        => Exec['shibboleth idp build'],
  }

  # Render the Shibboleth configuration. These are run time and not used
  # during the build process. It should restart Jetty, though.
  ['ldap.properties', 'idp.properties', 'metadata-providers.xml', 'authn/general-authn.xml',
    'attribute-resolver.xml', 'relying-party.xml', 'attribute-filter.xml',
  ].each |$config_file| {
    file { "${shibidp::shib_install_base}/conf/${config_file}":
      ensure  => file,
      owner   => $shibidp::shib_user,
      group   => $shibidp::shib_group,
      mode    => '0600',
      content => template("${module_name}/shibboleth/conf/${config_file}.erb"),
      require => [File[$shibidp::shib_install_base], Exec['shibboleth idp install']],
      notify  => Exec['shibboleth idp build'],
    }
  }

  # The install should run only once for a given version. This creates
  # the Shibboleth install base (by default /opt/shibboleth-dip).
  exec { 'shibboleth idp install':
    command     => "${shibidp::shib_src_dir}/shibboleth-identity-provider-${shibidp::shib_idp_version}/bin/install.sh  -Didp.property.file=${shibidp::shib_src_dir}/idp.install.properties",
    cwd         => "${shibidp::shib_src_dir}/shibboleth-identity-provider-${shibidp::shib_idp_version}",
    environment => ["JAVA_HOME=${java_home}"],
    path        => "${::path}:${java_home}",
    refreshonly => true,
    unless      => "test -f ${shibidp::shib_install_base}/war/idp.war",
    #notify      => Service['jetty'],
  }

  # The build will be rerun after certain changes in the source material. This
  # expects the Shibboleth install base to be present and will build  a new war file
  # based on the contents.
  exec { 'shibboleth idp build':
    command     => "${shibidp::shib_install_base}/bin/build.sh -Didp.target.dir=${shibidp::shib_install_base}",
    cwd         => $shibidp::shib_install_base,
    environment => ["JAVA_HOME=${java_home}"],
    path        => "${::path}:${java_home}",
    refreshonly => true,
    #notify      => Service['jetty'],
  }

}
