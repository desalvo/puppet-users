# == Defined class: users
#
# Users configuration module
#
# === Parameters
#
# [*name*]
#   (namevar) The user name. Value defaults to the resource's title if omitted.
#
# [*uid*]
#   The user ID; must be specified numerically. If omitted then one will be chosen automatically.
#
# [*gid*]
#   The user's primary group. Can be specified numerically or by name.
#
# [*groups*]
#   Groups to which the user belongs. Primary group should not be listed here.
#
# [*homepath*]
#   Home dir path, defaults to '/home'
#
# [*authorized_keys*]
#   Hash of optional authorized keys. Example:
#   { "root-key-1" => { key => '<public key>', type => 'rsa', user => 'root' } }
#
# [*keys*]
#   Hash of optional keys. Example:
#   { "root-key-1" => { priv => '<private key>', pub => '<public key>', type => 'rsa', user => 'root' } }
#
# [*ensure*]
#   Ensure present or absent for this user
#
# === Examples
#
#  users { 'foo':
#    gid => 'bar',
#    groups => [ 'foo', 'baz' ],
#  }
#
# === Authors
#
# Alessandro De Salvo <Alessandro.DeSalvo@roma1.infn.it>
#
# === Copyright
#
# Copyright 2014 Alessandro De Salvo
#
define users (
    $uid = undef,
    $gid = undef,
    $groups = undef,
    $homepath = '/home',
    $ensure = 'present',
    $authorized_keys = undef,
    $keys = undef,
) {
    validate_absolute_path($homepath)

    $user_home_path = $name ? {
        root => "/root",
        default => "${homepath}/${name}",
    }

    $user_ssh_path = "${user_home_path}/.ssh"

    if ($name != 'root') {
        $user_name = { name => $name }
        if ($uid) { $user_uid = {uid => $uid} } else { $user_uid = {} }
        if ($gid) { $user_gid = {gid => $gid} } else { $user_gid = {} }
        if ($groups) { $user_groups = {groups => $groups} } else { $user_groups = {} }
        $user_data = merge($user_name, $user_uid, $user_gid, $user_groups)
        $user_hash = { "$title" => $user_data }
        $user_defaults = {
            ensure => $ensure,
            managehome => true,
            home => $user_home_path,
            purge_ssh_keys => true
        }
        create_resources(user, $user_hash, $user_defaults)
        $user_req = User[$name]
    } else {
        $user_req = []
    }

    if ($ensure == 'present') {
        file {$user_ssh_path:
            ensure  => directory,
            owner   => $name,
            group   => $gid,
            mode    => 700,
            require => $user_req,
        }

        if ($keys) {
            if ($gid) { $key_group = $gid } else { $key_group = $name }
            $keys_defaults = {
                user   => $name,
                group  => $key_group,
                sshdir => $user_ssh_path,
                type   => 'ssh-rsa',
                require => File[$user_ssh_path],
            }
            create_resources (users::config_ssh_keys, $keys, $keys_defaults)
        }

        if ($authorized_keys) {
            $ak_defaults = {
                type   => 'ssh-rsa',
                ensure => present,
                user   => $name,
                require => File[$user_ssh_path],
            }
            create_resources (ssh_authorized_key, $authorized_keys, $ak_defaults)
        }
    }
}
