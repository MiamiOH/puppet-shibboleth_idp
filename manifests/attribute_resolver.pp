# Class: shibboleth_idp::attribute_resolver
#
# This class creates the attribute resolver configuration
#

class shibboleth_idp::attribute_resolver inherits shibboleth_idp {

  # Create the dataconnectors.properties file.
  concat { 'dataconnectors.properties':
    path   => "${shibboleth_idp::shib_install_base}/conf/dataconnectors.properties",
    owner  => $shibboleth_idp::shib_user,
    group  => $shibboleth_idp::shib_group,
    mode   => '0600',
    notify => Class['shibboleth_idp::service'],
  }

  # Create the attribute-resolver.xml configuration file.
  concat { 'attribute-resolver.xml':
    path   => "${shibboleth_idp::shib_install_base}/conf/attribute-resolver.xml",
    owner  => $shibboleth_idp::shib_user,
    group  => $shibboleth_idp::shib_group,
    mode   => '0600',
    notify => Class['shibboleth_idp::service'],
  }

  concat::fragment { 'attribute_resolver_head':
    target  => 'attribute-resolver.xml',
    order   => '01',
    content => template("${module_name}/shibboleth/attribute_resolver/_attribute_resolver_head.erb"),
  }

  concat::fragment { 'attribute_resolver_foot':
    target  => 'attribute-resolver.xml',
    order   => '99',
    content => template("${module_name}/shibboleth/attribute_resolver/_attribute_resolver_foot.erb"),
  }

  create_resources('shibboleth_idp::attribute_resolver::dataconnector', $shibboleth_idp::dataconnectors)
  create_resources('shibboleth_idp::attribute_resolver::attribute', $shibboleth_idp::attributes)

}
