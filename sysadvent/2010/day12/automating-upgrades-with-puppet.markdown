# Automating Upgrades with Puppet

Puppet and other configuration tools help you describe your infrastructure.
Puppet's model is resources: files, users, packages, etc. Each resource has
attributes. For example, a package has a name, a version, possibly a provider
(gem, apt, yum), etc.

<p>

With this model-driven infrastructure, you get cool things like easy upgrades
by just updating the version you specify on a package.

Many of my puppet manifests used to look like this:

    class nginx::server {
      package {
        "nginx": ensure => "0.8.52";
      }
      ...
    }

To upgrade versions, I would just edit the manifest and change the version.


