# Type: shibboleth_idp::attribute_resolver::attribute
#
# This type represents an attribute to be resolved
#

define shibboleth_idp::attribute_resolver::attribute (
  $id = $name,
  $type = undef,
  $scope = undef,
  $source_attribute_id = undef,
  $transient = false,
  $script = undef,
  $script_file = undef,
  $source = undef,
  $return = undef,

  $dependencies = {},
  $encoders = {},
) {

  if $type == 'Script' {
    fail("Attribute type 'Script' must be replaced with 'ScriptedAttribute' as of Shibboleth IdP 3.3")
  }

  concat::fragment { "attribute_resolver_attribute_${id}":
    target  => 'attribute-resolver.xml',
    order   => '20',
    content => template("${module_name}/shibboleth/attribute_resolver/_attribute.erb"),
  }

}
