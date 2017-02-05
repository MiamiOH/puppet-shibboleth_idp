# Class: apache
#
# This class installs the Shibboleth IdP

class shibboleth_idp (
  $idp_server_name,
  $idp_entity_id,

  $shib_idp_version        = $shibboleth_idp::params::shib_idp_version,
  $shib_user               = $shibboleth_idp::params::shib_user,
  $shib_group              = $shibboleth_idp::params::shib_group,
  $manage_user             = $shibboleth_idp::params::manage_user,
  $shib_src_dir            = $shibboleth_idp::params::shib_src_dir,
  $shib_install_base       = $shibboleth_idp::params::shib_install_base,
  $idp_jetty_base          = $shibboleth_idp::params::idp_jetty_base,
  $idp_jetty_user          = $shibboleth_idp::params::idp_jetty_user,
  $idp_server_url          = $shibboleth_idp::params::idp_server_url,
  $jce_policy_src          = $shibboleth_idp::params::jce_policy_src,

  $include_cas             = $shibboleth_idp::params::include_cas,
  $cas_server_url          = $shibboleth_idp::params::cas_server_url,

  $ldap_url                = $shibboleth_idp::params::ldap_url,
  $ldap_base_dn            = $shibboleth_idp::params::ldap_base_dn,
  $ldap_bind_dn            = $shibboleth_idp::params::ldap_bind_dn,
  $ldap_bind_pw            = $shibboleth_idp::params::ldap_bind_pw,
  $ldap_dn_format          = $shibboleth_idp::params::ldap_dn_format,
  $ldap_return_attributes  = $shibboleth_idp::params::ldap_return_attributes,

  $slf4j_version           = $shibboleth_idp::params::slf4j_version,
  $slf4j_checksum_type     = $shibboleth_idp::params::slf4j_checksum_type,
  $slf4j_checksum          = $shibboleth_idp::params::slf4j_checksum,
  $logback_version         = $shibboleth_idp::params::logback_version,
  $logback_checksum_type   = $shibboleth_idp::params::logback_checksum_type,
  $logback_checksum        = $shibboleth_idp::params::logback_checksum,

  $idp_log_dir             = $shibboleth_idp::params::idp_log_dir,
  $idp_log_history         = $shibboleth_idp::params::idp_log_history,
  $idp_loglevel_idp        = $shibboleth_idp::params::idp_loglevel_idp,
  $idp_loglevel_ldap       = $shibboleth_idp::params::idp_loglevel_ldap,
  $idp_loglevel_messages   = $shibboleth_idp::params::idp_loglevel_messages,
  $idp_loglevel_encryption = $shibboleth_idp::params::idp_loglevel_encryption,
  $idp_loglevel_opensaml   = $shibboleth_idp::params::idp_loglevel_opensaml,
  $idp_loglevel_props      = $shibboleth_idp::params::idp_loglevel_props,
  $idp_loglevel_spring     = $shibboleth_idp::params::idp_loglevel_spring,
  $idp_loglevel_container  = $shibboleth_idp::params::idp_loglevel_container,
  $idp_loglevel_xmlsec     = $shibboleth_idp::params::idp_loglevel_xmlsec,
  $idp_loglevel_attrmap    = $shibboleth_idp::params::idp_loglevel_attrmap,

  $signing_keypair         = $shibboleth_idp::params::signing_keypair,
  $encryption_keypair      = $shibboleth_idp::params::encryption_keypair,

  $relying_party_profiles  = $shibboleth_idp::params::relying_party_profiles,
  $metadata_providers      = $shibboleth_idp::params::metadata_providers,
  $dataconnectors          = $shibboleth_idp::params::dataconnectors,
  $attributes              = $shibboleth_idp::params::attributes,
  $filters                 = $shibboleth_idp::params::filters,

  $inc_signing_cert_src    = $shibboleth_idp::params::inc_signing_cert_src,
  $jetty_ks_path           = $shibboleth_idp::params::jetty_ks_path,
  $jetty_ks_type           = $shibboleth_idp::params::jetty_ks_type,
  $jetty_ks_password       = $shibboleth_idp::params::jetty_ks_password,

  $java_home               = $shibboleth_idp::params::java_home,

  $proxy_type              = undef,
  $proxy_host              = undef,
  $proxy_port              = undef,

  $service_name            = $shibboleth_idp::params::service_name,
  $service_enable          = $shibboleth_idp::params::service_enable,
  $service_manage          = $shibboleth_idp::params::service_manage,
  $service_ensure          = $shibboleth_idp::params::service_ensure,
  $service_restart         = $shibboleth_idp::params::service_restart,

) inherits shibboleth_idp::params {

  validate_hash($metadata_providers)

  ['idp_loglevel_idp', 'idp_loglevel_ldap', 'idp_loglevel_messages',
    'idp_loglevel_encryption', 'idp_loglevel_opensaml', 'idp_loglevel_props',
    'idp_loglevel_spring', 'idp_loglevel_container', 'idp_loglevel_xmlsec',
    'idp_loglevel_attrmap',
  ].each |$log| {
    $log_level = getvar($log)
    validate_re($log_level, ['^TRACE$', '^DEBUG$', '^INFO$', '^WARN$', '^ERROR$'],
    "Log level ${log} is not valid for IdP logging, use one of 'TRACE', 'DEBUG', 'INFO', 'WARN', 'ERROR'")
  }

  validate_integer($idp_log_history)

  $proxy_port_string = $proxy_port ? {
    undef   => undef,
    default => ":${proxy_port}",
  }

  $proxy_server = $proxy_host ? {
    undef   => undef,
    default => "http://${proxy_host}${proxy_port_string}",
  }

  Archive {
    proxy_server => $proxy_server,
    proxy_type   => $proxy_type,
  }

  class { '::shibboleth_idp::install': } ->
  class { '::shibboleth_idp::relying_party': } ->
  class { '::shibboleth_idp::metadata': } ->
  class { '::shibboleth_idp::attribute_resolver': } ->
  class { '::shibboleth_idp::attribute_filter': }

  class { '::shibboleth_idp::service': }

  contain '::shibboleth_idp::install'
  contain '::shibboleth_idp::relying_party'
  contain '::shibboleth_idp::metadata'
  contain '::shibboleth_idp::attribute_resolver'
  contain '::shibboleth_idp::attribute_filter'
  contain '::shibboleth_idp::service'

}
