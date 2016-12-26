# profile/shibboleth/idp.pp
# Manage Shibboleth IdP Service
#

class shibidp::attribute_resolver inherits shibidp {

  concat { 'attribute-resolver.xml':
    path => "${shibidp::shib_install_base}/conf/attribute-resolver-new.xml",
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

  # Create the attribute-resolver.xml configuration file.
  file { "${shibidp::shib_install_base}/conf/attribute-resolver.xml":
    ensure  => file,
    owner   => $shibidp::shib_user,
    group   => $shibidp::shib_group,
    mode    => '0600',
    content => template("${module_name}/shibboleth/conf/attribute-resolver.xml.erb"),
    #require => [File[$shibidp::shib_install_base], Exec['shibboleth idp install']],
    #notify  => Exec['shibboleth idp build'],
  }

}