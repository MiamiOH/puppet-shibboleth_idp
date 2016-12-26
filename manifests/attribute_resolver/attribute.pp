define shibidp::attribute_resolver::attribute (
  $id = $name,
  $type = undef,
  $scope = undef,
  $source_attribute_id = undef,
  $transient = false,
  $script = undef,

  $dependencies = {},
  $encoders = {},
) {

  concat::fragment { "attribute_resolver_attribute_${id}":
    target => 'attribute-resolver.xml',
    order  => '20',
    content => template("${module_name}/shibboleth/attribute_resolver/_attribute.erb")
  }

}
