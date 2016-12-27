# profile/shibboleth/idp.pp
# Manage Shibboleth IdP Service
#

class shibidp::metadata inherits shibidp {

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

  # Create the attribute-resolver.xml configuration file.
  concat { 'metadata-providers.xml':
    path    => "${shibidp::shib_install_base}/conf/metadata-providers.xml",
    owner   => $shibidp::shib_user,
    group   => $shibidp::shib_group,
    mode    => '0600',
  }

  concat::fragment { 'metadata_providers_head':
    target  => 'metadata-providers.xml',
    order   => '01',
    content => template("${module_name}/shibboleth/metadata_providers/_metadata_providers_head.erb")
  }

  concat::fragment { 'metadata_providers_foot':
    target  => 'metadata-providers.xml',
    order   => '99',
    content => template("${module_name}/shibboleth/metadata_providers/_metadata_providers_foot.erb")
  }

}