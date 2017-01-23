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
class shibboleth_idp::service (
  $service_name    = 'jetty',
  $service_enable  = true,
  $service_ensure  = true,
  $service_manage  = 'running',
  $service_restart = undef,
) {
  # The base class must be included first because parameter defaults depend on it
  if ! defined(Class['shibboleth_idp::params']) {
    fail('You must include the shibboleth_idp::params class before using any shibboleth_idp defined resources')
  }
  validate_bool($service_enable)
  validate_bool($service_manage)

  case $service_ensure {
    true, false, 'running', 'stopped': {
      $_service_ensure = $service_ensure
    }
    default: {
      $_service_ensure = undef
    }
  }

  $service_hasrestart = $service_restart == undef

  if $service_manage {
    service { 'jetty':
      ensure     => $_service_ensure,
      name       => $service_name,
      enable     => $service_enable,
      restart    => $service_restart,
      hasrestart => $service_hasrestart,
    }
  }
}
