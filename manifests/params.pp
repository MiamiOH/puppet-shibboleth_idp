# Class: shibboleth_idp::params
#
# This class manages parameters for provisioning
#

class shibboleth_idp::params {

  $shib_major_version      = '3'
  $shib_idp_version        = '3.3.2'
  $archive_url             = false
  $shib_user               = 'jetty'
  $shib_group              = 'jetty'
  $manage_user             = false
  $shib_src_dir            = '/opt/idpv3-source'
  $shib_install_base       = '/opt/shibboleth-idp'
  $idp_jetty_base          = '/opt/idp_jetty'
  $idp_jetty_log_dir       = '/opt/idp_jetty/logs'
  $idp_jetty_log_level     = 'INFO'
  $idp_jetty_user          = 'jetty'
  $idp_server_url          = undef
  $jce_policy_src          = undef

  $include_cas             = false
  # These should really be the same, but we have some sort of compatibility issue
  $shibcas_version         = '3.1.0'
  $shibcas_auth_version    = '3.3.0'
  $cas_server_url          = undef

  $ldap_url                = undef
  $ldap_base_dn            = undef
  $ldap_bind_dn            = undef
  $ldap_bind_pw            = undef
  $ldap_dn_format          = undef
  $ldap_return_attributes  = []

  $slf4j_version           = '1.7.22'
  $logback_version         = '1.1.8'

  $admin_allowed_cidr_expr = ['127.0.0.1/32', '::1/128']

  $idp_log_dir             = '/opt/shibboleth-idp/logs'
  $idp_log_history         = 180
  $idp_loglevel_idp        = 'INFO'
  $idp_loglevel_ldap       = 'WARN'
  $idp_loglevel_messages   = 'INFO'
  $idp_loglevel_encryption = 'INFO'
  $idp_loglevel_opensaml   = 'INFO'
  $idp_loglevel_props      = 'INFO'
  $idp_loglevel_spring     = 'ERROR'
  $idp_loglevel_container  = 'ERROR'
  $idp_loglevel_xmlsec     = 'INFO'
  $idp_loglevel_attrmap    = 'INFO'

  $signing_keypair         = { cert => undef, key => undef }
  $encryption_keypair      = { cert => undef, key => undef }

  $relying_party_profiles  = {}
  $metadata_providers      = {}
  $dataconnectors          = {}
  $attributes              = {}
  $filters                 = {}
  $nameid_generators_saml2 = []
  $nameid_generators_saml1 = []
  $nameid_allowed_entities = []

  $inc_signing_cert_src    = undef

  $java_home               = '/usr/java/latest'

  $jetty_version           = undef
  $jetty_home              = '/opt'
  $jetty_max_memory        = '1024m'
  $jetty_manage_user       = true
  $jetty_user              = 'jetty'
  $jetty_group             = 'jetty'
  $jetty_start_minutes     = 4
  $jetty_ks_path           = undef
  $jetty_ks_type           = 'PKCS12'
  $jetty_ks_password       = undef

  $service_name            = 'jetty'
  $service_enable          = true
  $service_manage          = true
  $service_ensure          = 'running'
  $service_restart         = undef

  $ss_version              = '1.15.4'
  $ss_install_base         = '/var/www/simplesamlphp'
  $ss_sp_name              = 'shibvm-sp'
  $ss_sp_host              = undef
  $ss_sp_port              = '31443'
  $ss_sp_url_path          = 'simplesaml'
  $ss_manage_cert          = true
  $ss_admin_password       = undef
  $ss_secret_salt          = undef
  $ss_cert_owner           = undef
  $ss_cert_group           = undef
  $ss_cert_dir             = '/var/www/simplesamlphp/cert'
  $nih_refeds_profile      = false

}
