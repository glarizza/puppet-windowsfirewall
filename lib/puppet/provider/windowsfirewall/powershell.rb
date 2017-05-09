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

  def initialize(value={})
    super(value)
    @property_flush = {}
  end

  @method_map = {
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

  # Dynamically create methods from the method_map above
  @method_map.each do |key,val|
    define_method(key) do
      args = []
      args << '(Get-NetFirewallProfile' << '-profile' << "\"#{resource[:name]}\").#{val}"
      value = powershell(args)
      Puppet.debug "#{key}: Found value of: #{value}"
      value.delete("\n").strip
    end

    define_method("#{key}=") do |value|
      @property_flush[key.intern] = value
    end
  end

  def exists?
    enabled = powershell("(Get-NetFirewallProfile -profile \"#{resource[:name]}\").Enabled")
    enabled.delete("\n").strip == 'True' ? true : false
  end

  def create
    args = []
    args << 'Set-NetFirewallProfile' << '-Profile' << "\"#{resource[:name]}\"" << '-Enabled' << 'True'
    args << '-DefaultInboundAction' << "\"#{resource[:default_inbound_action]}\"" if resource[:default_inbound_action]
    args << '-DefaultOutboundAction' << "\"#{resource[:default_outbound_action]}\"" if resource[:default_outbound_action]
    args << '-NotifyOnListen' << "\"#{resource[:notify_on_listen]}\"" if resource[:notify_on_listen]
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
      args << '-DefaultInboundAction' << @property_flush[:default_inbound_action] if @property_flush[:default_inbound_action]
      args << '-DefaultOutboundAction' << @property_flush[:default_outbound_action] if @property_flush[:default_outbound_action]
      args << '-NotifyOnListen' << @property_flush[:notify_on_listen] if @property_flush[:notify_on_listen]
    end
    powershell(args) unless args.empty?
  end
end

