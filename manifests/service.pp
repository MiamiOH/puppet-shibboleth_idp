# Class: shibboleth_idp::service
#
# Manages the Jetty process
#
# Sample Usage:
#
#    sometype { 'foo':
#      notify => Class['shibboleth_idp::service'],
#    }
#
#
class shibboleth_idp::service inherits shibboleth_idp {

  validate_bool($shibboleth_idp::service_enable)
  validate_bool($shibboleth_idp::service_manage)

  case $shibboleth_idp::service_ensure {
    true, false, 'running', 'stopped': {
      $_service_ensure = $shibboleth_idp::service_ensure
    }
    default: {
      $_service_ensure = undef
    }
  }

  $_service_hasrestart = $shibboleth_idp::service_restart == undef

  if $shibboleth_idp::service_manage {
    service { 'jetty':
      ensure     => $_service_ensure,
      name       => $shibboleth_idp::service_name,
      enable     => $shibboleth_idp::service_enable,
      restart    => $shibboleth_idp::service_restart,
      hasrestart => $_service_hasrestart,
    }
  }
}
