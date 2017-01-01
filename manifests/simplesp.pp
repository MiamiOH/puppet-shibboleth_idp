# Class: shibidp::simplesp
#
# This class provisions a SimpleSAMLPHP based SP for testing
#

class shibidp::simplesp (
  $ss_version     = '1.14.11',
  $install_base   = '/var/simplesamlphp',
  $sp_host        = 'shibvm-sp.miamioh.edu:31443',
  $sp_url_path    = 'simplesaml',
  $admin_password = cache_data('cache_data/shibboleth', "simplesp_${::environment}_adminpassword", random_password(32)),
  $secret_salt    = cache_data('cache_data/shibboleth', "simplesp_${::environment}_secretsalt", random_password(64)),
){

  file { $install_base:
    ensure => directory,
  } ->

  archive { "/tmp/simplesamlphp-${ss_version}.tar.gz":
    source          => "https://github.com/simplesamlphp/simplesamlphp/releases/download/v${ss_version}/simplesamlphp-${ss_version}.tar.gz",
    extract         => true,
    extract_command => 'tar xfz %s --strip-components=1',
    extract_path    => $install_base,
    creates         => "${install_base}/README.md",
    cleanup         => true,
  }

  ['config/config.php', 'config/authsources.php', 'metadata/saml20-idp-remote.php',
  ].each |$config_file| {
    file { "${install_base}/${config_file}":
      ensure  => file,
      content => template("${module_name}/simplesp/${config_file}.erb"),
      require => Archive["/tmp/simplesamlphp-${ss_version}.tar.gz"],
    }
  }

  openssl::certificate::x509 { 'sp':
    ensure       => present,
    country      => 'US',
    organization => 'miamioh.edu',
    commonname   => $::fqdn,
    state        => 'OH',
    locality     => 'Oxford',
    days         => 3456,
    base_dir     => "${install_base}/cert",
    owner        => $::apache::params::user,
    group        => $::apache::params::group,
  }

  apache::vhost { $::fqdn:
    port          => 443,
    ssl           => true,
    docroot       => '/var/www/html',
    default_vhost => true,
    setenv        => ["SIMPLESAMLPHP_CONFIG_DIR ${install_base}/config"],
    aliases       => [
      {
        'alias' => '/simplesaml',
        'path'  => "${install_base}/www",
      },
    ],
    directories   => [
      {
        path    => "${install_base}/www",
        require => 'all granted',
      },
    ],
  }
}
