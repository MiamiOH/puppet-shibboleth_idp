# Class: shibboleth_idp::simplesp
#
# This class provisions a SimpleSAMLPHP based SP for testing
#
# IMPORTANT!!!!
#
# This VM is intended only for testing in a local Vagrant environment.
# It should not be built in the data center for any reason. If an SP
# is needed for additional testing, we will need to provision one for
# that purpose.
#

class shibboleth_idp::simplesp (
  $ss_version        = $shibboleth_idp::params::ss_version,
  $ss_install_base   = $shibboleth_idp::params::ss_install_base,
  $ss_sp_host        = $shibboleth_idp::params::ss_sp_host,
  $ss_sp_port        = $shibboleth_idp::params::ss_sp_port,
  $ss_sp_url_path    = $shibboleth_idp::params::ss_sp_url_path,
  $ss_admin_password = $shibboleth_idp::params::ss_admin_password,
  $ss_secret_salt    = $shibboleth_idp::params::ss_secret_salt,
  $ss_cert_owner     = $shibboleth_idp::params::ss_cert_owner,
  $ss_cert_group     = $shibboleth_idp::params::ss_cert_group,
  $proxy_server      = undef,
  $proxy_type        = undef,
) inherits shibboleth_idp::params {

  Archive {
    proxy_server => $proxy_server,
    proxy_type   => $proxy_type,
  }

  $ss_sp_domain = $ss_sp_port ? {
    undef   => $ss_sp_host,
    default => "${ss_sp_host}:${ss_sp_port}",
  }

  file { $ss_install_base:
    ensure => directory,
  } ->

  archive { "/tmp/simplesamlphp-${ss_version}.tar.gz":
    source          => "https://github.com/simplesamlphp/simplesamlphp/releases/download/v${ss_version}/simplesamlphp-${ss_version}.tar.gz",
    extract         => true,
    extract_command => 'tar xfz %s --strip-components=1',
    extract_path    => $ss_install_base,
    creates         => "${ss_install_base}/README.md",
    cleanup         => true,
  }

  ['config/config.php', 'config/authsources.php', 'metadata/saml20-idp-remote.php',
  ].each |$config_file| {
    file { "${ss_install_base}/${config_file}":
      ensure  => file,
      content => template("${module_name}/simplesp/${config_file}.erb"),
      require => Archive["/tmp/simplesamlphp-${ss_version}.tar.gz"],
    }
  }

  # This cert pair is used only for signing SAML assertions between the SP
  # and an IdP. It is NOT user facing via the web server.
  openssl::certificate::x509 { $ss_sp_host:
    ensure       => present,
    country      => 'US',
    organization => 'miamioh.edu',
    commonname   => $ss_sp_host,
    state        => 'OH',
    locality     => 'Oxford',
    days         => 3456,
    base_dir     => "${ss_install_base}/cert",
    owner        => $ss_cert_owner,
    group        => $ss_cert_group,
  }

}
