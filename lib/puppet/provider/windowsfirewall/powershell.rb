Puppet::Type.type(:windowsfirewall).provide(:powershell) do
  confine :operatingsystem => :windows
  commands :powershell =>
    if File.exists?("#{ENV['SYSTEMROOT']}\\sysnative\\WindowsPowershell\\v1.0\\powershell.exe")
      "#{ENV['SYSTEMROOT']}\\sysnative\\WindowsPowershell\\v1.0\\powershell.exe"
    elsif File.exists?("#{ENV['SYSTEMROOT']}\\system32\\WindowsPowershell\\v1.0\\powershell.exe")
      "#{ENV['SYSTEMROOT']}\\system32\\WindowsPowershell\\v1.0\\powershell.exe"
    elsif File.exists?('/usr/bin/powershell')
      '/usr/bin/powershell'
    elsif File.exists?('/usr/local/bin/powershell')
      '/usr/local/bin/powershell'
    elsif !Puppet::Util::Platform.windows?
      "powershell"
    else
      'powershell.exe'
    end

  desc <<-EOT
    Does very Windows-firewall-y stuff
  EOT

  mk_resource_methods

  def initialize(value={})
    super(value)
    @property_flush = {}
  end

  def self.method_map
    {
      'ensure'                              => 'Enabled',
      'default_inbound_action'              => 'DefaultInboundAction',
      'default_outbound_action'             => 'DefaultOutboundAction',
      'allow_inbound_rules'                 => 'AllowInboundRules',
      'allow_local_firewall_rules'          => 'AllowLocalFirewallRules',
      'allow_local_ipsec_rules'             => 'AllowLocalIPsecRules',
      'allow_user_apps'                     => 'AllowUserApps',
      'allow_user_ports'                    => 'AllowUserPorts',
      'allow_unicast_response_to_multicast' => 'AllowUnicastResponseToMulticast',
      'notify_on_listen'                    => 'NotifyOnListen',
      'enable_stealth_mode_for_ipsec'       => 'EnableStealthModeForIPsec',
      'log_file_name'                       => 'LogFileName',
      'log_max_size_kilobytes'              => 'LogMaxSizeKilobytes',
      'log_allowed'                         => 'LogAllowed',
      'log_blocked'                         => 'LogBlocked',
      'log_ignored'                         => 'LogIgnored',
      'disabled_interface_aliases'          => 'DisabledInterfaceAliases'
    }
  end

  def self.instances
    array_of_instances = []
    ['domain', 'private', 'public'].each do |zone|
      instance_properties = get_firewall_properties(zone)
      array_of_instances << new(instance_properties)
    end
    array_of_instances
  end

  def self.prefetch(resources)
    instances.each do |prov|
      if resource = resources[prov.name]
        resource.provider = prov
      end
    end
  end

  def self.get_firewall_properties(zone)
    output = powershell(['Get-NetFirewallProfile', '-profile', "\"#{zone}\""]).split("\n")
    3.times { output.shift }
    hash_of_properties = {}
    output.each do | line|
      key, val = line.split(':')
      property_name = method_map.key(key.strip)
      hash_of_properties[property_name.intern] = val.strip.chomp
    end
    hash_of_properties[:name] = zone
    hash_of_properties[:ensure] = hash_of_properties[:ensure] == 'True' ? :present : :absent
    hash_of_properties[:provider] = :powershell
    Puppet.debug "Windowsfirewall found this hash of properties on the system: #{hash_of_properties}"
    hash_of_properties
  end

  def method_map
    self.class.method_map
  end

  # Dynamically create setter methods from the method_map above
  method_map.keys.each do |key|
    define_method("#{key}=") do |value|
      @property_flush[key.intern] = value
    end
  end

  def exists?
    @property_hash[:ensure] == :present
  end

  def build_arguments_for_powershell(from_which_method)
    case from_which_method
    when 'create'
      value = resource
    when 'flush'
      value = @property_flush
    else
      Puppet.fail "Windowsfirewall resource (powershell provider) is unable to build necessary arguments for Powershell."
    end

    if value
      args = []
      args << 'Set-NetFirewallProfile' << '-Profile' << "\"#{resource[:name]}\"" << '-Enabled' << 'True'
      args << "-#{method_map['default_inbound_action']}" << "\"#{value[:default_inbound_action]}\"" if value[:default_inbound_action]
      args << "-#{method_map['default_outbound_action']}" << "\"#{value[:default_outbound_action]}\"" if value[:default_outbound_action]
      args << "-#{method_map['allow_inbound_rules']}" << "\"#{value[:allow_inbound_rules]}\"" if value[:allow_inbound_rules]
      args << "-#{method_map['allow_local_firewall_rules']}" << "\"#{value[:allow_local_firewall_rules]}\"" if value[:allow_local_firewall_rules]
      args << "-#{method_map['allow_local_ipsec_rules']}" << "\"#{value[:allow_local_ipsec_rules]}\"" if value[:allow_local_ipsec_rules]
      args << "-#{method_map['allow_user_apps']}" << "\"#{value[:allow_user_apps]}\"" if value[:allow_user_apps]
      args << "-#{method_map['allow_user_ports']}" << "\"#{value[:allow_user_ports]}\"" if value[:allow_user_ports]
      args << "-#{method_map['allow_unicast_response_to_multicast']}" << "\"#{value[:allow_unicast_response_to_multicast]}\"" if value[:allow_unicast_response_to_multicast]
      args << "-#{method_map['notify_on_listen']}" << "\"#{value[:notify_on_listen]}\"" if value[:notify_on_listen]
      args << "-#{method_map['enable_stealth_mode_for_ipsec']}" << "\"#{value[:enable_stealth_mode_for_ipsec]}\"" if value[:enable_stealth_mode_for_ipsec]
      args << "-#{method_map['log_file_name']}" << "\"#{value[:log_file_name]}\"" if value[:log_file_name]
      args << "-#{method_map['log_max_size_kilobytes']}" << "\"#{value[:log_max_size_kilobytes]}\"" if value[:log_max_size_kilobytes]
      args << "-#{method_map['log_allowed']}" << "\"#{value[:log_allowed]}\"" if value[:log_allowed]
      args << "-#{method_map['log_blocked']}" << "\"#{value[:log_blocked]}\"" if value[:log_blocked]
      args << "-#{method_map['log_ignored']}" << "\"#{value[:log_ignored]}\"" if value[:log_ignored]
      args << "-#{method_map['disabled_interface_aliases']}" << "\"#{value[:disabled_interface_aliases]}\"" if value[:disabled_interface_aliases]
      Puppet.debug "Arguments built for windowsfirewall powershell provider returns: #{args}"
      args
    end
  end

  def create
    args = build_arguments_for_powershell('create')
    powershell(args) unless args.empty?
  end

  def destroy
    args = []
    args << 'Set-NetFirewallProfile' << '-Profile' << "\"#{resource[:name]}\"" << '-Enabled' << 'False'
    powershell(args)
  end

  def flush
    args = build_arguments_for_powershell('flush')
    powershell(args) unless args.empty?
  end
end

