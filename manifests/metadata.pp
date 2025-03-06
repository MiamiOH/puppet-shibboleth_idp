# Class: shibboleth_idp::metadata
#
# This class manages the IdP metadata and providers
#

class shibboleth_idp::metadata inherits shibboleth_idp {

  $shib_major_version = $shibboleth_idp::shib_major_version

  # This is the InCommon signing key public cert used to validate the downloaded
  # InCommon metadata. The metadata-providers.xml config contains instructions
  # for acquiring the cert and the configuration for the automated refresh.
  # TODO Make this optional and source directly (also impacts the provider xml file)
  $shibboleth_idp::inc_signing_cert_src.each |$signing_cert| {
    file { "${shibboleth_idp::shib_install_base}/credentials/$signing_cert":
      ensure  => file,
      content => template("${module_name}/shibboleth/credentials/${signing_cert}.erb"),
      owner   => $shibboleth_idp::shib_user,
      group   => $shibboleth_idp::shib_group,
      mode    => '0644',
      notify  => Class['shibboleth_idp::service'],
    }
  }

  # The idp-metadata.xml file represents our IdP to service providers. It
  # contains the public keys for our signing and encryption certs and
  # must be updated any time the certs change.
  $signing_keypair = $shibboleth_idp::signing_keypair
  $encryption_keypair = $shibboleth_idp::encryption_keypair
  file { "${shibboleth_idp::shib_install_base}/metadata/idp-metadata.xml":
    ensure  => file,
    content => template("${module_name}/shibboleth/metadata/idp-metadata.xml.erb"),
  }

  # The metadata for SPs comes from a federation (InCommon) or directly
  # from the SP. The provider configuration will collect all of the provided
  # sources so the IdP can load them.
  # Create the metadata-providers.xml configuration file.
  concat { 'metadata-providers.xml':
    path  => "${shibboleth_idp::shib_install_base}/conf/metadata-providers.xml",
    owner => $shibboleth_idp::shib_user,
    group => $shibboleth_idp::shib_group,
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
