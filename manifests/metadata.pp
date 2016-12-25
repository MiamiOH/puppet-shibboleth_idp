# profile/shibboleth/idp.pp
# Manage Shibboleth IdP Service
#

class shibidp::metadata inherits shibidp {

  $providers = $shibidp::metadata_files

  # This is the InCommon signing key public cert used to validate the downloaded
  # InCommon metadata. The metadata-providers.xml config contains instructions
  # for acquiring the cert and the configuration for the automated refresh.
  file { "${shibidp::shib_install_base}/credentials/inc-md-cert.pem":
    ensure  => file,
    source  => "puppet:///modules/${module_name}/inc-md-cert.pem",
    owner   => $shibidp::shib_user,
    group   => $shibidp::shib_group,
    mode    => '0644',
    #require => Exec['shibboleth idp install'],
    #notify  => Exec['shibboleth idp build'],
  }

  # The idp-metadata.xml file represents our IdP to service providers. It
  # contains the public keys for our signing and encryption certs and
  # must be updated any time the certs change.
  $signing_keypair = cache_data('cache_data/shibboleth', "idp-signing_${::environment}_keypair", {cert => undef, key => undef})
  $encryption_keypair = cache_data('cache_data/shibboleth', "idp-encryption_${::environment}_keypair", {cert => undef, key => undef})
  file { "${shibidp::shib_install_base}/metadata/idp-metadata.xml":
    ensure  => file,
    content => template("${module_name}/shibboleth/metadata/idp-metadata.xml.erb"),
    #require => Exec['shibboleth idp install'],
    #notify  => Exec['shibboleth idp build'],
  }

  # Create the metadata-providers.xml configuration file.
  file { "${shibidp::shib_install_base}/conf/metadata-providers.xml":
    ensure  => file,
    owner   => $shibidp::shib_user,
    group   => $shibidp::shib_group,
    mode    => '0600',
    content => template("${module_name}/shibboleth/conf/metadata-providers.xml.erb"),
    #require => [File[$shibidp::shib_install_base], Exec['shibboleth idp install']],
    #notify  => Exec['shibboleth idp build'],
  }

  # Manage the SP metadata backing files. These are provided by some SPs
  # out-of-band.
  $providers.each |$key, $config| {
    $config_real = pick($config, {})
    $file = pick($config_real['filename'], "${key}-metadata.xml")
    file { "${shibidp::shib_install_base}/metadata/${file}":
      ensure  => file,
      owner   => $shibidp::shib_user,
      group   => $shibidp::shib_group,
      mode    => '0644',
      source  => "puppet:///modules/${module_name}/metadata/${file}",
      #require => Exec['shibboleth idp install'],
    }
  }

}