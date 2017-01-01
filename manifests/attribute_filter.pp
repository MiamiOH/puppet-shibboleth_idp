# Class: shibidp::attribute_filter
#
# This class creates the attribute filter configuration
#

class shibidp::attribute_filter inherits shibidp {

  # Create the attribute-filter.xml configuration file.
  concat { 'attribute-filter.xml':
    path => "${shibidp::shib_install_base}/conf/attribute-filter.xml",
    owner   => $shibidp::shib_user,
    group   => $shibidp::shib_group,
    mode    => '0600',
  }

  concat::fragment { 'attribute_filter_head':
    target => 'attribute-filter.xml',
    order  => '01',
    content => template("${module_name}/shibboleth/attribute_filter/_attribute_filter_head.erb")
  }

  concat::fragment { 'attribute_filter_foot':
    target => 'attribute-filter.xml',
    order  => '99',
    content => template("${module_name}/shibboleth/attribute_filter/_attribute_filter_foot.erb")
  }

  create_resources('shibidp::attribute_filter::policy', $shibidp::filters)

}