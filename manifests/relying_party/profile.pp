# Type: shibidp::relying_party::profile
#
# This type represents a profile describing overrides for a relying party
#

define shibidp::relying_party::profile (
  $entity_id = $name,

  $properties = {},
) {

  concat::fragment { "relying_party_profile_${name}":
    target  => 'relying-party.xml',
    order   => '60',
    content => template("${module_name}/shibboleth/relying_party/_profile.erb"),
  }

}
