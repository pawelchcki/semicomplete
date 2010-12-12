# Automating Upgrades with Puppet

This primarily is primarily about separating your configuration model from
your configuration inputs. You might have the same service model in multiple
environments but versions, accounts, ownership, etc, may change between them.
The idea of separ

Puppet and other configuration tools help you describe your infrastructure.
Puppet's model is resources: files, users, packages, etc. Each resource has
attributes like package version, file path, file contents, service restart
command, package provider (gem, apt, yum), user uid, etc.

Many of my puppet manifests look a bit like this:

    class nginx::server {
      package {
        "nginx": ensure => "0.8.52";
      }
      ...
    }

To upgrade versions, I would just edit the manifest and change the version.

Static manifests don't scale very well. Puppet has support for environments so
you can use different manifests (say, a different nginx::server class) in
different situations. You could do tihs:

    class nginx::server {
      package {
        "nginx":
          ensure => $environment {
            "production" => "0.8.52",
            "testing" => "0.8.53",
            "dev" => "latest",
          };
      }
    }

The variable above comes from puppet calls a 'fact.' Facts such as cpu speed,
ip addresses, chassis info, virtualization source, etc, are provided to help
you conditionally tune your infrastructure. Facts come from a puppet tool
called Facter, which means facts are essentially an external input for puppet.

This model of external inputs is a good one. Using facts, you could conditionally
install things like Dell OpenManage, or template service configs based on ram
or cpu counts. Combining the inputs (facts) with your model (puppet resources)
helps you steer puppet into doing the correct thing for each machine it is run on.
Very useful!

The problem with the above puppet example is that it doesn't scale very well.
Each time you add a new environment (a new testing environment, some one-off
dev cluster, etc), you have to edit the manifest (your infrastructure model).

The solution here is to follow the facts example and allow yourself a way to
specify your own inputs - what I would call, "truth," Truth is very similar to
facts, just more human-driven and I only use a different, but similar, term for
the sake of identifying source. I use "truth" to refer to human-originated
inputs (such as "what package to install"), and I use "facts" to refer to
machine-originated information (such as "number of cpus on this system").

For the above puppet manifest, you could write truth in separate manifest that
defines `$nginx_version` based on `$environment`:

    # truth.pp
    case $environment {
      "production": { $nginx_version = "0.8.52" }
      "testing": { $nginx_version = "0.8.53" }
      "dev": { $nginx_version =  "latest" }
    }

    # modules/nginx/manifests/server.pp
    class nginx::server {
      package {
        "nginx": ensure => $nginx_version;
      }
    }

Ultimately, setting variables with conditionals (case statements, etc) is more
code than you need - in Puppet 2.6.1, a solution to this problem was included:
[extlookup](http://docs.puppetlabs.com/references/stable/function.html#extlookup)().
(It existed prior, but it now officially ships with puppet)

This new function lets you separate your configuration inputs from your
infrastructure model. An example of the above manifest using extlookup:

    class nginx::server {
      package {
        "nginx": ensure => extlookup("package/nginx");
      }
    }

You configure extlookup in puppet by setting some variables, here's an example:

    $extlookup_datadir = "/etc/puppet/manifests/extdata"
    $extlookup_precedence = ["nodes/%{fqdn}", "environments/%{environment}", "common"]

The values in `%{ ... }` are evaluated with each node's facts. This lets you
put all production environment data in
`/etc/puppet/manifests/extdata/environments/**production**.csv`.

You data format extlookup uses currently is
[csv](http://en.wikipedia.org/wiki/Comma-separated_values) files for values.

It's basically a bunch of key-value pairs you can query with a precedence
order. For example, the above config would look in `nodes/somehostname.csv` first, which
would allow you to override environment-specific configuration values per host, but
if no `nodes/somehostname.csv` file exists or the requested value is not present, it will
fall down to the next file in the list. You can also specify default values in extlookup,
but that is outside the scope of this article.

Building on the examples above, here is what your extlookup files would look like:

    # /etc/puppet/manifests/extdata/environments/production.csv
    package/nginx,0.8.52

    # /etc/puppet/manifests/extdata/environments/testing.csv
    package/nginx,0.8.53

    # /etc/puppet/manifests/extdata/environments/dev.csv
    package/nginx,latest

At work, I use extlookup for:

* package versions. Of note, for developer systems, I set some package
  'ensure' values to "absent" so developer activity won't be overwritten by
  puppet trying to deploy our internal apps.
* application flags and tuning. For production, we want to do backups to Amazon S3. For random development systems, we don't.
* syslog configuration (what remote syslog host to ship logs to, per deployment)
* database information (database name, credentials, etc)
* some dns automation (what certain internal CNAME records point to)
* nagios contact configuration (example: notify pager in prod 24/7, only during daytime for staging, but never for development)

Point is, once you separate your model from your inputs (facts, truth, etc),
you become more agile. Tune settings per machine, per environment, or per any
value.  You get the idea. One important note is that all of the things I use
extlookup for are truth, aka human-based, inputs.

Further reading:

* [Puppet facts with Facter](http://www.puppetlabs.com/puppet-3/related-projects/facter/)
* [Chef facts with Ohai](http://wiki.opscode.com/display/chef/Ohai)
* [Complex data and Puppet](http://www.devco.net/archives/2009/08/31/complex_data_and_puppet.php)

