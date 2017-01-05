# Type: shibidp::attribute_filter::policy
#
# This type represents a policy applied during attribute filtering
#

define shibidp::attribute_filter::policy (
  $id = $name,

  $requesters = {},
  $attributes = {},
) {

  concat::fragment { "attribute_filter_policy_${id}":
    target  => 'attribute-filter.xml',
    order   => '20',
    content => template("${module_name}/shibboleth/attribute_filter/_policy.erb"),
  }

}
