# puppet-windowsfirewall

A type/provider to manage the three Windows firewall zones ('domain', 'public',
'private') on Windows Server 2012 or above (i.e. any windows server node for
which Powershell allows you to configure the firewall).

More readme to come, but here's a sample declaration:

```puppet
windowsfirewall { 'domain':
  ensure                              => 'present',
  allow_inbound_rules                 => 'NotConfigured',
  allow_local_firewall_rules          => 'NotConfigured',
  allow_local_ipsec_rules             => 'NotConfigured',
  allow_unicast_response_to_multicast => 'NotConfigured',
  allow_user_apps                     => 'NotConfigured',
  allow_user_ports                    => 'NotConfigured',
  default_inbound_action              => 'allow',
  default_outbound_action             => 'allow',
  disabled_interface_aliases          => '{NotConfigured}',
  enable_stealth_mode_for_ipsec       => 'NotConfigured',
  log_allowed                         => 'False',
  log_blocked                         => 'False',
  log_file_name                       => '%systemroot%\system32\LogFiles\Firewall\pfirewall.log',
  log_ignored                         => 'NotConfigured',
  log_max_size_kilobytes              => '4096',
  notify_on_listen                    => 'False',
}
```

This provider also implements `self.instances`, so feel free to install it and run `puppet resource windowsfirewall` for fun and profit!
