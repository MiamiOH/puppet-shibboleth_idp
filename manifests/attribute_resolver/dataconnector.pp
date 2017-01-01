# Type: shibidp::attribute_filter::dataconnector
#
# This type represents a data connector for resolving attributes
#

define shibidp::attribute_resolver::dataconnector (
  $id = $name,
  $type = undef,

  $ldap_url = undef,
  $ldap_base_dn = undef,
  $ldap_principal = undef,
  $ldap_principal_credential = cache_data('cache_data/shibidp', "${id}_${::environment}_password", random_password(32)),
  $ldap_use_start_tls = undef,
  $ldap_filter_template = undef,
  $ldap_filter_tls_trust_id = undef,
  $ldap_filter_tls_trust_cert = undef,
  $ldap_return_attributes = undef,
  $ldap_trust_cert_source = undef,
) {

  concat::fragment { "attribute_resolver_dataconnector_${id}":
    target => 'attribute-resolver.xml',
    order  => '80',
    content => template("${module_name}/shibboleth/attribute_resolver/_dataconnector.erb")
  }

  if $type == 'LDAPDirectory' {
    concat::fragment { "dataconnector_properties_${id}":
      target => 'dataconnectors.properties',
      order  => '10',
      content => template("${module_name}/shibboleth/attribute_resolver/_ldap_properties.erb")
    }
  }

  if $ldap_trust_cert_source {
    file { "${shibidp::shib_install_base}/${ldap_filter_tls_trust_cert}":
      ensure  => file,
      source  => $ldap_trust_cert_source,
      owner   => $shibidp::shib_user,
      group   => $shibidp::shib_group,
      mode    => '0644',
    }
  }
}
