# Aggregating Nagios Checks for Better Alerts

_This article was written by [Jordan Sissel](http://www.semicomplete.com/) ([@jordansissel](http://twitter.com/jordansissel))_

Chances are that your infrastructure has more than one machine performing the
same role - frontend (webapps, etc), backend (databases, log collectors, etc),
middleware (message brokers, proxies, etc), support services (config
management, etc). Horizontal scaling means that you scale by adding more server
resources, right?

Monitoring a horizontally scaled system can often lead to unintended noise. You
might have 10 web servers, but 3 are broken, so you get 3 alerts. Maybe you
monitor ssh health on all 50 of your servers, and someone pushed a bad config
or there is a bad network connection, and now all 50 servers are alerting you
about failures. Further, I believe that monitoring alerts (things that page
you) should generally be business-oriented, not
single-metric-and-single-server-oriented.

Even if you aren't running systems with duplicate roles, it still makes sense
to collect multiple individual health checks into a single alert.
 
This calls for aggregating your data. You must keep the noise from your
monitoring system at a low level so you don't end up accidentally training
yourself (and others) to ignore that system - don't let your monitoring server
<a href="http://en.wikipedia.org/wiki/The_Boy_Who_Cried_Wolf">cry, "Wolf!"</a>.

If you aggregate alert conditions, you get a stronger signal while reducing
noise. Further, alerting on aggregates means you can do cool things like only
alerting if, for example, more than 5% of things are failing - assuming that's
safe for your business.

If you could keep the existing checks you have, not alert on them, but add
aggregate checks that cause alerting, you could maintain your current
fine-grain monitoring while improving alerting in both noise level and business
relevance! Sounds like win-win.

There are some solutions for this already, like
[check_multi](http://my-plugin.de/wiki/projects/check_multi/configuration/file).
but I didn't want to run additional or duplicate checks. Why? Some checks may
take a long time (like a complex Selenium test), or be resource-intensive to
run (like verifying a large backup), or won't scale if I have to run 200 of
them to answer one aggregated health check.

So, I took a different approach. Nagios already records [state in a file on
disk](http://nagios.sourceforge.net/docs/3_0/configmain.html#status_file), so
we can parse that file and produce an aggregate check. Lucky for me, there are
already tools that parse this format, so most of
the work is done already (
[nagiosity](http://code.google.com/p/nagiosity/),
[checkmk_livestatus](http://mathias-kettner.de/checkmk_livestatus.html), and
[ruby-nagios](http://code.google.com/p/ruby-nagios/)
). I picked ruby-nagios, for no particular reason. It didn't require much
hacking to add what I needed. The result is
[nagios-manage](https://rubygems.org/gems/nagios-manage) and a tool:
`check_check.rb` (comes with the nagios-manage rubygem).

Notes: Currently, this tool assumes a few things about what I want:

* Skips checks that have notifications disabled
* Skips checks that are marked in downtime
* Only uses the `hard` state. If it is in `soft critical`, for example, it will
  assume the previous `hard` state.

The above constraints let me aggregate other nagios-state data into health that
is deemed important - if one server is down for maintenance or has a known
failure, I don't want to alert about it.

Examples:

    # Summarize all checks for all hosts:
    % check_check.rb
    OK=110 WARNING=0 CRITICAL=0 UNKNOWN=0 services=// hosts=// 

    # Summarize solr checks, when one check is failing:
    % check_check.rb -s solrserver
    OK=27 WARNING=0 CRITICAL=1 UNKNOWN=0 services=/solrserver/ hosts=// 
    Services in CRITICAL:
      frontend1.example.com => solrserver client tests

The result in nagios looks something like this:

![nagios check_check](http://lh4.ggpht.com/_u-5lMShiO40/TPyrT6Io2GI/AAAAAAAAAGA/hfsdcMj44b4/nagios-check_check.png)

By the way, the no-argument invocation is super useful for, from the command
line, checking the overall health of everything nagios monitors.

For the solrserver check above, I would create one single check that would run
the above `check_check.rb` command and alert appropriately. This saves me from
having 28 potentially-failing-and-alerting checks. Further, if I get an alert
about 1 critical check, I still have the further fine-grained alerting per
server so I can easily drill into what is failing.

Summarizing: I still have monitoring track fine-grained details like cpu usage,
network activity, server behavior, etc, but individual checks do not cause
alerts themselves. This means setting the `contacts` for your individual checks
to something that won't alert you. I rely on these special aggregate checks
(using the tool above) to collect relevant data for me, and alert me on
important failures in a way that doesn't flood my pager.
