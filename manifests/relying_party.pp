# Class: shibidp::relying_party
#
# This class creates the relying party configuration
#

class shibidp::relying_party inherits shibidp {

  # Create the relying-party.xml configuration file.
  concat { 'relying-party.xml':
    path  => "${shibidp::shib_install_base}/conf/relying-party.xml",
    owner => $shibidp::shib_user,
    group => $shibidp::shib_group,
    mode  => '0600',
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

  create_resources('shibidp::relying_party::profile', $shibidp::relying_party_profiles)

}
