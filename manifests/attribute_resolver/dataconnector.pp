define shibidp::attribute_resolver::dataconnector (
  $id = $name,
  $type = undef,

  $ldap_url = undef,
  $base_dn = undef,
  $principal = undef,
  $principal_credential = undef,
  $use_start_tls = undef,
  $filter_template = undef,
  $filter_tls_trust_id = undef,
  $filter_tls_trust_cert = undef,
  $return_attributes = undef,
) {

  concat::fragment { "attribute_resolver_dataconnector_${id}":
    target => 'attribute-resolver.xml',
    order  => '80',
    content => template("${module_name}/shibboleth/attribute_resolver/_dataconnector.erb")
  }

}
