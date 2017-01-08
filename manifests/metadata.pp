# Class: shibidp::metadata
#
# This class manages the IdP metadata and providers
#

class shibidp::metadata inherits shibidp {

  # This is the InCommon signing key public cert used to validate the downloaded
  # InCommon metadata. The metadata-providers.xml config contains instructions
  # for acquiring the cert and the configuration for the automated refresh.
  # TODO Make this optional and source directly (also impacts the provider xml file)
  file { "${shibidp::shib_install_base}/credentials/inc-md-cert.pem":
    ensure => file,
    source => $shibidp::inc_signing_cert_src,
    owner  => $shibidp::shib_user,
    group  => $shibidp::shib_group,
    mode   => '0644',
  }

  # The idp-metadata.xml file represents our IdP to service providers. It
  # contains the public keys for our signing and encryption certs and
  # must be updated any time the certs change.
  $signing_keypair = cache_data('cache_data/shibboleth', "idp-signing_${::environment}_keypair", {cert => undef, key => undef})
  $encryption_keypair = cache_data('cache_data/shibboleth', "idp-encryption_${::environment}_keypair", {cert => undef, key => undef})
  file { "${shibidp::shib_install_base}/metadata/idp-metadata.xml":
    ensure  => file,
    content => template("${module_name}/shibboleth/metadata/idp-metadata.xml.erb"),
  }

  # The metadata for SPs comes from a federation (InCommon) or directly
  # from the SP. The provider configuration will collect all of the provided
  # sources so the IdP can load them.
  # Create the metadata-providers.xml configuration file.
  concat { 'metadata-providers.xml':
    path  => "${shibidp::shib_install_base}/conf/metadata-providers.xml",
    owner => $shibidp::shib_user,
    group => $shibidp::shib_group,
    mode  => '0600',
  }

  concat::fragment { 'metadata_providers_head':
    target  => 'metadata-providers.xml',
    order   => '01',
    content => template("${module_name}/shibboleth/metadata_providers/_metadata_providers_head.erb"),
  }

  concat::fragment { 'metadata_providers_foot':
    target  => 'metadata-providers.xml',
    order   => '99',
    content => template("${module_name}/shibboleth/metadata_providers/_metadata_providers_foot.erb"),
  }

}
