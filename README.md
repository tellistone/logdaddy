# logdaddy 1.1

The Gangsta Log Spam tool! 

Bombard your cluster with Raw, Syslog, JSON, CEF, Paloalto, Netflow, Beats, GELF, Cluster-to-Cluster messages to every input at once with the press of a button!

Confluence page with instructions on how to install and use here:

https://graylogdocumentation.atlassian.net/wiki/spaces/~42516692/pages/2534866955/LogDaddy+-+The+Gangsta+Log+Spam+Tool 

# Flags

-l parameter defines how many times the script loops. Setting the first parameter to 0 means the script loops forever.

-t parameter defines over how many seconds the script sends the logs. 

-i parameter defines the rate at which logs are sent instead via the “Equivalent rate to daily traffic of x GB” value. Note that use of the -i parameter negates any value set for the -t parameter. 

-s parameter allows you to define the address of the Graylog server (overwriting the default within the script). Supply an IP address or hostname.

-f parameter allows you to define the address of the Graylog Fowarder (overwriting the default within the script). Supply an IP address or hostname.
