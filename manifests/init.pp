# == Defined class: users
#
# Users configuration module
#
# === Parameters
#
# [*name*]
#   User name. Value defaults to the resource's title if omitted.
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
    $gid = undef,
    $groups = undef,
    $homepath = '/home',
    $ensure = 'present',
    $authorized_keys = undef,
    $keys = undef,
) {
    $username = $name

    if ($name != 'root') {
        $user_name = { name => $name }
        if ($gid) { $user_gid = {gid => $gid} } else { $user_gid = {} }
        if ($groups) { $user_groups = {groups => $groups} } else { $user_groups = {} }
        $user_data = merge($user_name, $user_gid, $user_groups)
        $user_hash = { "$title" => $user_data }
        $user_defaults = {
            ensure => $ensure,
            managehome => true,
            home => "${homepath}/${username}",
            purge_ssh_keys => true
        }
        create_resources(user, $user_hash, $user_defaults)
        $ssh_dir = "${homepath}/${username}/.ssh"
        $user_req = User[$name]
    } else {
        $user_req = []
        $ssh_dir = "/${username}/.ssh"
    }

    if ($ensure == 'present') {
        file {$ssh_dir:
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
                sshdir => "${ssh_dir}",
                type   => 'ssh-rsa',
                require => File[$ssh_dir],
            }
            create_resources (users::config_ssh_keys, $keys, $keys_defaults)
        }

        if ($authorized_keys) {
            $ak_defaults = {
                type   => 'ssh-rsa',
                ensure => present,
                user   => $name,
                require => File[$ssh_dir],
            }
            create_resources (ssh_authorized_key, $authorized_keys, $ak_defaults)
        }
    }
}
