# Class: shibidp::attribute_resolver
#
# This class creates the attribute resolver configuration
#

class shibidp::attribute_resolver inherits shibidp {

  # Create the dataconnectors.properties file.
  concat { 'dataconnectors.properties':
    path => "${shibidp::shib_install_base}/conf/dataconnectors.properties",
    owner   => $shibidp::shib_user,
    group   => $shibidp::shib_group,
    mode    => '0600',
  }

  # Create the attribute-resolver.xml configuration file.
  concat { 'attribute-resolver.xml':
    path => "${shibidp::shib_install_base}/conf/attribute-resolver.xml",
    owner   => $shibidp::shib_user,
    group   => $shibidp::shib_group,
    mode    => '0600',
  }

  concat::fragment { 'attribute_resolver_head':
    target => 'attribute-resolver.xml',
    order  => '01',
    content => template("${module_name}/shibboleth/attribute_resolver/_attribute_resolver_head.erb")
  }

  concat::fragment { 'attribute_resolver_foot':
    target => 'attribute-resolver.xml',
    order  => '99',
    content => template("${module_name}/shibboleth/attribute_resolver/_attribute_resolver_foot.erb")
  }

  create_resources('shibidp::attribute_resolver::dataconnector', $shibidp::dataconnectors)
  create_resources('shibidp::attribute_resolver::attribute', $shibidp::attributes)

}