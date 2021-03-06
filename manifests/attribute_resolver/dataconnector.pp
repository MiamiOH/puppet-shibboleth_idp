# Type: shibboleth_idp::attribute_filter::dataconnector
#
# This type represents a data connector for resolving attributes
#

define shibboleth_idp::attribute_resolver::dataconnector (
  $id = $name,
  $type = undef,

  $ldap_url = undef,
  $ldap_base_dn = undef,
  $ldap_principal = undef,
  $ldap_principal_credential = undef,
  $ldap_use_start_tls = undef,
  $ldap_filter_template = undef,
  $ldap_tls_trust_cert = undef,
  $ldap_return_attributes = undef,
  $static_attributes = undef,
) {

  if $type == 'LDAPDirectory' {
    $dataconnector_template = '_ldap_dataconnector'

    concat::fragment { "dataconnector_properties_${id}":
      target  => 'dataconnectors.properties',
      order   => '10',
      content => template("${module_name}/shibboleth/attribute_resolver/_ldap_properties.erb"),
    }
  } elsif $type == 'Static' {
    $dataconnector_template = '_static_dataconnector'
  } else {
    fail("shibboleth_idp::attribute_resolver::dataconnector does not support type: ${type}")
  }

  concat::fragment { "attribute_resolver_dataconnector_${id}":
    target  => 'attribute-resolver.xml',
    order   => '80',
    content => template("${module_name}/shibboleth/attribute_resolver/${dataconnector_template}.erb"),
  }

}
