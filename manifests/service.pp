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
class shibboleth_idp::service {
  # The base class must be included first because parameter defaults depend on it
  if ! defined(Class['shibboleth_idp::params']) {
    fail('You must include the shibboleth_idp::params class before using any shibboleth_idp defined resources')
  }
  validate_bool($shibboleth_idp::params::service_enable)
  validate_bool($shibboleth_idp::params::service_manage)

  case $shibboleth_idp::params::service_ensure {
    true, false, 'running', 'stopped': {
      $_service_ensure = $shibboleth_idp::params::service_ensure
    }
    default: {
      $_service_ensure = undef
    }
  }

  $_service_hasrestart = $shibboleth_idp::params::service_restart == undef

  if $shibboleth_idp::params::service_manage {
    service { 'jetty':
      ensure     => $_service_ensure,
      name       => $shibboleth_idp::params::service_name,
      enable     => $shibboleth_idp::params::service_enable,
      restart    => $shibboleth_idp::params::service_restart,
      hasrestart => $_service_hasrestart,
    }
  }
}
