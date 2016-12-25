# profile/shibboleth/idp.pp
# Manage Shibboleth IdP Service
#

class shibidp::params {

  $shib_idp_version       = '3.2.1'
  $shib_user              = 'shib'
  $shib_group             = 'shib'
  $shib_src_dir           = '/root/idpv3-source'
  $shib_install_base      = '/opt/shibboleth-idp'
  $idp_jetty_base         = '/opt/idp_jetty'
  $idp_jetty_user         = 'jetty'
  $idp_entity_id          = 'https://shibvm-idp.miamioh.edu:21443/idp/shibboleth'
  
  $ldap_url               = 'ldaps://ldapt.muohio.edu:636'
  $ldap_base_dn           = 'ou=peopledc=muohiodc=edu'
  $ldap_bind_dn           = 'uid=shibbolethou=ldapidsdc=muohiodc=edu'
  $ldap_bind_pw           = cache_data('cache_data/shibboleth', "open_ldap_${::environment}_password", random_password(32))
  $ldap_dn_format         = 'uid=%sou=people,dc=muohio,dc=edu'
  $ldap_return_attributes = ['uid', 'eduPersonPrincipalName']
  
  $ad_ldap_url            = 'ldaps://storm.miamioh.edu:636'
  $ad_base_dn             = 'ou=people,dc=it,dc=muohio,dc=edu'
  $ad_bind_dn             = 'shibboleth@it.muohio.edu'
  $ad_bind_pw             = cache_data('cache_data/shibboleth', "ad_ldap_${::environment}_password", random_password(32))
  $ad_return_attributes   = ['memberOf', 'extensionAttribute5']

  $slf4j_version          = '1.7.22'
  $slf4j_checksum_type    = 'md5'
  $slf4j_checksum         = '7ab9c81ec1881fce4d809bbc48008eb6'
  $logback_version        = '1.1.8'
  $logback_checksum_type  = 'md5'
  $logback_checksum       = '0466114001b29808aeee2bf665e1b2f8'
  $cas_server_url         = 'https://idptest.miamioh.edu/cas'
  $idp_server_url         = 'https://shibvm-idp.miamioh.edu:21443'
  $idp_server_name        = 'shibvm-idp.miamioh.edu'
  $ks_password            = cache_data('cache_data/shibboleth', "keystore_${::environment}_password", random_password(32))
  $ldap_cert_type         = 'test'

}
