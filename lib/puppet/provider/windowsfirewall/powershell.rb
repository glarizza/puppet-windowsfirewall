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
    sites = instances
    resources.keys.each do |site|
      if provider = sites.find { |s| s.name.downcase == site.downcase }
        Puppet.debug "-----FOUND IT------"
        resources[site].provider = provider
      end
    end
    #Puppet.debug "-----Inside Prefetch----"
    #instances.each do |prov|
    #  Puppet.debug "Second prefetch, prov: #{prov.name}"
    #  if resource = resources[prov.name]
    #    Puppet.debug "Inside prefetch, resource.provider: #{resource.provider}, prov: #{prov.name}"
    #    resource.provider = prov
    #  end
    #end
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
    Puppet.debug "Hash of properties is: #{hash_of_properties}"
    hash_of_properties
  end

  def method_map
    self.class.method_map
  end

  ## Dynamically create methods from the method_map above
  #method_map.each do |key,val|
  #  define_method(key) do
  #    Puppet.debug "Inside getter - property hash is: #{@property_hash}"
  #    @property_hash[key.intern]
  #  end

  #  define_method("#{key}=") do |value|
  #    Puppet.debug "Setting @property_flush[#{key.intern}] to #{value}..."
  #    @property_flush[key.intern] = value
  #  end
  #end

  def exists?
    Puppet.debug "the value of property hash is:  #{@property_hash}" 
    enabled = powershell("(Get-NetFirewallProfile -profile \"#{resource[:name]}\").Enabled")
    enabled.delete("\n").strip == 'True'
  end

  def create
    args = []
    args << 'Set-NetFirewallProfile' << '-Profile' << "\"#{resource[:name]}\"" << '-Enabled' << 'True'
    args << "-#{method_map['default_inbound_action']}" << "\"#{resource[:default_inbound_action]}\"" if resource[:default_inbound_action]
    args << "-#{method_map['default_outbound_action']}" << "\"#{resource[:default_outbound_action]}\"" if resource[:default_outbound_action]
    args << "-#{method_map['allow_inbound_rules']}" << "\"#{resource[:allow_inbound_rules]}\"" if resource[:allow_inbound_rules]
    args << "-#{method_map['allow_local_firewall_rules']}" << "\"#{resource[:allow_local_firewall_rules]}\"" if resource[:allow_local_firewall_rules]
    args << "-#{method_map['allow_local_ipsec_rules']}" << "\"#{resource[:allow_local_ipsec_rules]}\"" if resource[:allow_local_ipsec_rules]
    args << "-#{method_map['allow_user_apps']}" << "\"#{resource[:allow_user_apps]}\"" if resource[:allow_user_apps]
    args << "-#{method_map['allow_user_ports']}" << "\"#{resource[:allow_user_ports]}\"" if resource[:allow_user_ports]
    args << "-#{method_map['allow_unicast_response_to_multicast']}" << "\"#{resource[:allow_unicast_response_to_multicast]}\"" if resource[:allow_unicast_response_to_multicast]
    args << "-#{method_map['notify_on_listen']}" << "\"#{resource[:notify_on_listen]}\"" if resource[:notify_on_listen]
    args << "-#{method_map['enable_stealth_mode_for_ipsec']}" << "\"#{resource[:enable_stealth_mode_for_ipsec]}\"" if resource[:enable_stealth_mode_for_ipsec]
    args << "-#{method_map['log_file_name']}" << "\"#{resource[:log_file_name]}\"" if resource[:log_file_name]
    args << "-#{method_map['log_max_size_kilobytes']}" << "\"#{resource[:log_max_size_kilobytes]}\"" if resource[:log_max_size_kilobytes]
    args << "-#{method_map['log_allowed']}" << "\"#{resource[:log_allowed]}\"" if resource[:log_allowed]
    args << "-#{method_map['log_blocked']}" << "\"#{resource[:log_blocked]}\"" if resource[:log_blocked]
    args << "-#{method_map['log_ignored']}" << "\"#{resource[:log_ignored]}\"" if resource[:log_ignored]
    args << "-#{method_map['disabled_interface_aliases']}" << "\"#{resource[:disabled_interface_aliases]}\"" if resource[:disabled_interface_aliases]
    powershell(args) unless args.empty?
  end

  def destroy
    args = []
    args << 'Set-NetFirewallProfile' << '-Profile' << "\"#{resource[:name]}\"" << '-Enabled' << 'False'
    powershell(args)
  end

  def flush
    args = []
    unless @property_flush.empty?
      args << 'Set-NetFirewallProfile' << '-Profile' << "\"#{resource[:name]}\"" << '-Enabled' << 'True'
      args << "-#{method_map['default_inbound_action']}" << "\"#{@property_flush[:default_inbound_action]}\"" if @property_flush[:default_inbound_action]
      args << "-#{method_map['default_outbound_action']}" << "\"#{@property_flush[:default_outbound_action]}\"" if @property_flush[:default_outbound_action]
      args << "-#{method_map['allow_inbound_rules']}" << "\"#{@property_flush[:allow_inbound_rules]}\"" if @property_flush[:allow_inbound_rules]
      args << "-#{method_map['allow_local_firewall_rules']}" << "\"#{@property_flush[:allow_local_firewall_rules]}\"" if @property_flush[:allow_local_firewall_rules]
      args << "-#{method_map['allow_local_ipsec_rules']}" << "\"#{@property_flush[:allow_local_ipsec_rules]}\"" if @property_flush[:allow_local_ipsec_rules]
      args << "-#{method_map['allow_user_apps']}" << "\"#{@property_flush[:allow_user_apps]}\"" if @property_flush[:allow_user_apps]
      args << "-#{method_map['allow_user_ports']}" << "\"#{@property_flush[:allow_user_ports]}\"" if @property_flush[:allow_user_ports]
      args << "-#{method_map['allow_unicast_response_to_multicast']}" << "\"#{@property_flush[:allow_unicast_response_to_multicast]}\"" if @property_flush[:allow_unicast_response_to_multicast]
      args << "-#{method_map['notify_on_listen']}" << "\"#{@property_flush[:notify_on_listen]}\"" if @property_flush[:notify_on_listen]
      args << "-#{method_map['enable_stealth_mode_for_ipsec']}" << "\"#{@property_flush[:enable_stealth_mode_for_ipsec]}\"" if @property_flush[:enable_stealth_mode_for_ipsec]
      args << "-#{method_map['log_file_name']}" << "\"#{@property_flush[:log_file_name]}\"" if @property_flush[:log_file_name]
      args << "-#{method_map['log_max_size_kilobytes']}" << "\"#{@property_flush[:log_max_size_kilobytes]}\"" if @property_flush[:log_max_size_kilobytes]
      args << "-#{method_map['log_allowed']}" << "\"#{@property_flush[:log_allowed]}\"" if @property_flush[:log_allowed]
      args << "-#{method_map['log_blocked']}" << "\"#{@property_flush[:log_blocked]}\"" if @property_flush[:log_blocked]
      args << "-#{method_map['log_ignored']}" << "\"#{@property_flush[:log_ignored]}\"" if @property_flush[:log_ignored]
      args << "-#{method_map['disabled_interface_aliases']}" << "\"#{@property_flush[:disabled_interface_aliases]}\"" if @property_flush[:disabled_interface_aliases]
    end
    powershell(args) unless args.empty?
  end
end

