# Type: shibboleth_idp::metadata::provider
#
# This type represents an SP metadata provider
#

define shibboleth_idp::metadata::provider (
  $id = $name,
  $filename = "${name}-metadata.xml",
  $owner = undef,
  $group = undef,
  $mode = '0644',
  $source_path = undef,
  $source_file = $filename,
) {

  concat::fragment { "metadata_providers_${id}":
    target  => 'metadata-providers.xml',
    order   => '80',
    content => template("${module_name}/shibboleth/metadata_providers/_provider.erb"),
  }

  file { "${shibboleth_idp::shib_install_base}/metadata/${filename}":
    ensure => file,
    owner  => $owner,
    group  => $group,
    mode   => $mode,
    source => "${source_path}/${source_file}",
  }

}
