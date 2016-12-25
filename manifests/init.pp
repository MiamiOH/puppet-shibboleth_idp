# profile/shibboleth/idp.pp
# Manage Shibboleth IdP Service
#

class shibidp (
  $shib_idp_version       = $shibidp::params::shib_idp_version,
  $shib_user              = $shibidp::params::shib_user,
  $shib_group             = $shibidp::params::shib_group,
  $shib_src_dir           = $shibidp::params::shib_src_dir,
  $shib_install_base      = $shibidp::params::shib_install_base,
  $idp_jetty_base         = $shibidp::params::idp_jetty_base,
  $idp_jetty_user         = $shibidp::params::idp_jetty_user,
  $idp_entity_id          = $shibidp::params::idp_entity_id,
  
  $ldap_url               = $shibidp::params::ldap_url,
  $ldap_base_dn           = $shibidp::params::ldap_base_dn,
  $ldap_bind_dn           = $shibidp::params::ldap_bind_dn,
  $ldap_bind_pw           = $shibidp::params::ldap_bind_pw,
  $ldap_dn_format         = $shibidp::params::ldap_dn_format,
  $ldap_return_attributes = $shibidp::params::ldap_return_attributes,
  
  $ad_ldap_url            = $shibidp::params::ad_ldap_url,
  $ad_base_dn             = $shibidp::params::ad_base_dn,
  $ad_bind_dn             = $shibidp::params::ad_bind_dn,
  $ad_bind_pw             = $shibidp::params::ad_bind_pw,
  $ad_return_attributes   = $shibidp::params::ad_return_attributes,

  $slf4j_version          = $shibidp::params::slf4j_version,
  $slf4j_checksum_type    = $shibidp::params::slf4j_checksum_type,
  $slf4j_checksum         = $shibidp::params::slf4j_checksum,
  $logback_version        = $shibidp::params::logback_version,
  $logback_checksum_type  = $shibidp::params::logback_checksum_type,
  $logback_checksum       = $shibidp::params::logback_checksum,
  $cas_server_url         = $shibidp::params::cas_server_url,
  $idp_server_url         = $shibidp::params::idp_server_url,
  $idp_server_name        = $shibidp::params::idp_server_name,
  $ks_password            = $shibidp::params::ks_password,
  $ldap_cert_type         = $shibidp::params::ldap_cert_type,
) inherits shibidp::params {

  class { '::shibidp::install': }
  contain shibidp::install
  
}
