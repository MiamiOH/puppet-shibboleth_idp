# Class: shibboleth_idp::relying_party
#
# This class creates the relying party configuration
#

class shibboleth_idp::relying_party inherits shibboleth_idp {

  # Create the relying-party.xml configuration file.
  concat { 'relying-party.xml':
    path   => "${shibboleth_idp::shib_install_base}/conf/relying-party.xml",
    owner  => $shibboleth_idp::shib_user,
    group  => $shibboleth_idp::shib_group,
    mode   => '0600',
    notify => Class['shibboleth_idp::service'],
  }

  concat::fragment { 'relying_party_head':
    target  => 'relying-party.xml',
    order   => '01',
    content => template("${module_name}/shibboleth/relying_party/_relying_party_head.erb"),
  }

  concat::fragment { 'relying_party_foot':
    target  => 'relying-party.xml',
    order   => '99',
    content => template("${module_name}/shibboleth/relying_party/_relying_party_foot.erb"),
  }

  create_resources('shibboleth_idp::relying_party::profile', $shibboleth_idp::relying_party_profiles)

}
