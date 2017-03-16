# Class: shibboleth_idp::install
#
# This is the core class for installing the IdP software
#

class shibboleth_idp::install inherits shibboleth_idp {

  $exec_path = '/usr/local/bin:/bin:/usr/bin:/usr/local/sbin:/usr/sbin:/sbin:'

  $java_home = $shibboleth_idp::java_home
  $include_cas = $shibboleth_idp::include_cas
  $shibcas_version = $shibboleth_idp::shibcas_version
  $shibcas_auth_version = $shibboleth_idp::shibcas_auth_version
  $proxy_host = $shibboleth_idp::proxy_host
  $proxy_port = $shibboleth_idp::proxy_port
  $nameid_generators = $shibboleth_idp::nameid_generators
  $nameid_allowed_entities = $shibboleth_idp::nameid_allowed_entities

  if $shibboleth_idp::manage_user {
    ensure_resource('user', $shibboleth_idp::shib_user, {
        managehome => true,
        system     => true,
        uid        => $shibboleth_idp::shib_user_uid,
        gid        => $shibboleth_idp::shib_group,
        shell      => '/sbin/nologin',
        home       => "/var/lib/${shibboleth_idp::shib_user}",
    })

    ensure_resource('group', $shibboleth_idp::shib_group, {
        ensure => present,
        gid    => $shibboleth_idp::shib_group_gid,
    })
  }

  file { $shibboleth_idp::shib_src_dir:
    ensure => directory,
    owner  => $shibboleth_idp::shib_user,
    group  => $shibboleth_idp::shib_group,
    mode   => '0644',
  }

  file { $shibboleth_idp::idp_log_dir:
    ensure => directory,
    owner  => $shibboleth_idp::shib_user,
    group  => $shibboleth_idp::shib_group,
    mode   => '0644',
  }

  ####################################
  # The Shibboleth IdP uses the Java unlimited strength crypto libraries.
  # We have the required files as an artifact, just download and install.
  if $shibboleth_idp::jce_policy_src {
    archive { '/tmp/UnlimitedJCEPolicyJDK8.tar.gz':
      source       => $shibboleth_idp::jce_policy_src,
      extract      => true,
      extract_path => $shibboleth_idp::shib_src_dir,
      cleanup      => true,
      creates      => "${shibboleth_idp::shib_src_dir}/UnlimitedJCEPolicyJDK8/local_policy.jar",
      require      => File[$shibboleth_idp::shib_src_dir],
    }

    ['local_policy.jar', 'US_export_policy.jar',
    ].each |$jar_file| {
      file { "${java_home}/jre/lib/security/${jar_file}":
        ensure  => file,
        owner   => $shibboleth_idp::shib_user,
        group   => $shibboleth_idp::shib_group,
        mode    => '0744',
        source  => "${shibboleth_idp::shib_src_dir}/UnlimitedJCEPolicyJDK8/${jar_file}",
        require => Archive['/tmp/UnlimitedJCEPolicyJDK8.tar.gz'],
      }
    }
  }
  ####################################

  ####################################
  # The following sets up the Shibboleth IdP installation.

  file { $shibboleth_idp::shib_install_base:
    ensure  => directory,
    owner   => $shibboleth_idp::shib_user,
    group   => $shibboleth_idp::shib_group,
    mode    => '0744',
    require => File[$shibboleth_idp::shib_src_dir],
  } ->

  archive { "/tmp/shibboleth-identity-provider-${shibboleth_idp::shib_idp_version}.tar.gz":
    source       => "https://shibboleth.net/downloads/identity-provider/${shibboleth_idp::shib_idp_version}/shibboleth-identity-provider-${shibboleth_idp::shib_idp_version}.tar.gz",
    extract      => true,
    extract_path => $shibboleth_idp::shib_src_dir,
    user         => $shibboleth_idp::shib_user,
    group        => $shibboleth_idp::shib_group,
    cleanup      => true,
    creates      => "${shibboleth_idp::shib_src_dir}/shibboleth-identity-provider-${shibboleth_idp::shib_idp_version}/LICENSE.txt",
    notify       => Exec['shibboleth idp install'],
  }

  # The install and merge properties contain settings which influence the
  # Shibboleth installation process.
  ['idp.install.properties', 'idp.merge.properties'].each |$file| {
    file { "${shibboleth_idp::shib_src_dir}/${file}":
      ensure  => file,
      content => template("${module_name}/shibboleth/${file}.erb"),
      owner   => $shibboleth_idp::shib_user,
      group   => $shibboleth_idp::shib_group,
      require => Archive["/tmp/shibboleth-identity-provider-${shibboleth_idp::shib_idp_version}.tar.gz"],
      notify  => Exec['shibboleth idp install'],
    }
  }

  # Install the signing and encryption certs. These are used internally, not
  # through the web front end. Any change requires coordination with InCommon
  # and our service providers.
  [{name=>'idp-signing', keypair=>$shibboleth_idp::signing_keypair},
  {name=>'idp-encryption', keypair=>$shibboleth_idp::encryption_keypair}].each |$certificate| {
    # lint:ignore:variable_scope
    # $keypair is used in the crt and key templates
    $keypair = $certificate['keypair']

    file { "${shibboleth_idp::shib_install_base}/credentials/${certificate['name']}.crt":
      ensure  => file,
      content => template("${module_name}/shibboleth/credentials/cert.erb"),
      owner   => $shibboleth_idp::shib_user,
      group   => $shibboleth_idp::shib_group,
      mode    => '0644',
      require => Exec['shibboleth idp install'],
      notify  => Class['shibboleth_idp::service'],
    }

    file { "${shibboleth_idp::shib_install_base}/credentials/${certificate['name']}.key":
      ensure  => file,
      content => template("${module_name}/shibboleth/credentials/key.erb"),
      owner   => $shibboleth_idp::shib_user,
      group   => $shibboleth_idp::shib_group,
      mode    => '0600',
      require => Exec['shibboleth idp install'],
      notify  => Class['shibboleth_idp::service'],
    }
    # lint:endignore
  }

  # Fetch and install the ShibCAS component.
  if $include_cas {
    archive { '/tmp/master.tar.gz':
      source       => "https://github.com/Unicon/shib-cas-authn3/archive/v${shibcas_version}.tar.gz",
      extract      => true,
      extract_path => $shibboleth_idp::shib_src_dir,
      user         => $shibboleth_idp::shib_user,
      group        => $shibboleth_idp::shib_group,
      cleanup      => true,
      creates      => "${shibboleth_idp::shib_src_dir}/shib-cas-authn3-${shibcas_version}/README.md",
    } ->

    file { "${shibboleth_idp::shib_install_base}/flows/authn/Shibcas":
      ensure  => directory,
      owner   => $shibboleth_idp::shib_user,
      group   => $shibboleth_idp::shib_group,
      mode    => '0644',
      recurse => true,
      source  => "${shibboleth_idp::shib_src_dir}/shib-cas-authn3-${shibcas_version}/IDP_HOME/flows/authn/Shibcas",
      require => Exec['shibboleth idp install'],
      notify  => Exec['shibboleth idp build'],
    }

    # Use archive to fetch a couple of jar files, but do not extract them.
    archive { "${shibboleth_idp::shib_install_base}/edit-webapp/WEB-INF/lib/shib-cas-authenticator-${shibcas_auth_version}.jar":
      source  => "https://github.com/Unicon/shib-cas-authn3/releases/download/v${shibcas_auth_version}/shib-cas-authenticator-${shibcas_auth_version}.jar",
      extract => false,
      cleanup => false,
      user    => $shibboleth_idp::shib_user,
      group   => $shibboleth_idp::shib_group,
      creates => "${shibboleth_idp::shib_install_base}/edit-webapp/WEB-INF/lib/shib-cas-authenticator-${shibcas_auth_version}.jar",
      require => Exec['shibboleth idp install'],
      notify  => Exec['shibboleth idp build'],
    }

    # This one does not support https, so verify the md5 hash
    archive { "${shibboleth_idp::shib_install_base}/edit-webapp/WEB-INF/lib/cas-client-core-3.4.1.jar":
      source        => 'http://central.maven.org/maven2/org/jasig/cas/client/cas-client-core/3.4.1/cas-client-core-3.4.1.jar',
      extract       => false,
      cleanup       => false,
      user          => $shibboleth_idp::shib_user,
      group         => $shibboleth_idp::shib_group,
      checksum_type => 'md5',
      checksum      => '0cde05fb6892018f19913eb6f3081758',
      creates       => "${shibboleth_idp::shib_install_base}/edit-webapp/WEB-INF/lib/cas-client-core-3.4.1.jar",
      require       => Exec['shibboleth idp install'],
      notify        => Exec['shibboleth idp build'],
    }
  }

  # Render the Shibboleth configuration. These are run time and not used
  # during the build process. It should restart Jetty, though.
  ['ldap.properties', 'idp.properties', 'authn/general-authn.xml', 'logback.xml',
    'c14n/subject-c14n.xml', 'saml-nameid.xml',
  ].each |$config_file| {
    file { "${shibboleth_idp::shib_install_base}/conf/${config_file}":
      ensure  => file,
      owner   => $shibboleth_idp::shib_user,
      group   => $shibboleth_idp::shib_group,
      mode    => '0600',
      content => template("${module_name}/shibboleth/conf/${config_file}.erb"),
      require => [File[$shibboleth_idp::shib_install_base], Exec['shibboleth idp install']],
      notify  => Class['shibboleth_idp::service'],
    }
  }

  # The install should run only once for a given version. This creates
  # the Shibboleth install base (by default /opt/shibboleth-dip).
  exec { 'shibboleth idp install':
    command     => "${shibboleth_idp::shib_src_dir}/shibboleth-identity-provider-${shibboleth_idp::shib_idp_version}/bin/install.sh  -Didp.property.file=${shibboleth_idp::shib_src_dir}/idp.install.properties",
    cwd         => "${shibboleth_idp::shib_src_dir}/shibboleth-identity-provider-${shibboleth_idp::shib_idp_version}",
    user        => $shibboleth_idp::shib_user,
    environment => ["JAVA_HOME=${java_home}"],
    path        => "${::path}:${java_home}",
    # refreshonly => true,
    unless      => "test -f ${shibboleth_idp::shib_install_base}/war/idp.war",
  }

  # The build will be rerun after certain changes in the source material. This
  # expects the Shibboleth install base to be present and will build  a new war file
  # based on the contents.
  exec { 'shibboleth idp build':
    command     => "/usr/bin/sh ${shibboleth_idp::shib_install_base}/bin/build.sh -Didp.target.dir=${shibboleth_idp::shib_install_base}",
    cwd         => $shibboleth_idp::shib_install_base,
    user        => $shibboleth_idp::shib_user,
    environment => ["JAVA_HOME=${java_home}"],
    path        => "${::path}:${java_home}",
    refreshonly => true,
    notify      => Class['shibboleth_idp::service'],
  }

}
