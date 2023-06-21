# Class: shibboleth_idp::attribute_filter
#
# This class creates the attribute filter configuration
#

class shibboleth_idp::attribute_filter inherits shibboleth_idp {

  # Create the attribute-filter.xml configuration file.
  $shib_major_version = $shibboleth_idp::shib_major_version
  
  concat { 'attribute-filter.xml':
    path   => "${shibboleth_idp::shib_install_base}/conf/attribute-filter.xml",
    owner  => $shibboleth_idp::shib_user,
    group  => $shibboleth_idp::shib_group,
    mode   => '0600',
    notify => Class['shibboleth_idp::service'],
  }

  concat::fragment { 'attribute_filter_head':
    target  => 'attribute-filter.xml',
    order   => '01',
    content => template("${module_name}/shibboleth/attribute_filter/_attribute_filter_head.erb"),
  }

  concat::fragment { 'attribute_filter_foot':
    target  => 'attribute-filter.xml',
    order   => '99',
    content => template("${module_name}/shibboleth/attribute_filter/_attribute_filter_foot.erb"),
  }

  create_resources('shibboleth_idp::attribute_filter::policy', $shibboleth_idp::filters)

}
