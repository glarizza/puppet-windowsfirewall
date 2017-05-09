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
    'default_inbound_action' => {
      'cmd'      => "(Get-NetFirewallProfile -profile \"#{resource[:name]}\").DefaultInboundAction",
      'property' => 'DefaultInboundAction'
    },
    'default_outbound_action' => {
      'cmd'      => "(Get-NetFirewallProfile -profile \"#{resource[:name]}\").DefaultOutboundAction",
      'property' => 'DefaultOutboundAction'
    },
    'notify_on_listen' => {
      'cmd'      => "(Get-NetFirewallProfile -profile \"#{resource[:name]}\").NotifyOnListen",
      'property' => 'NotifyOnListen'
    }
  }

  # Dynamically create methods from the method_map above
  @method_map.keys.each do |key|
    define_method(key) do
      value = powershell @method_map[key]['cmd']
      value.delete("\n").strip
    end

    define_method("#{key}=") do |value|
      @property_flush[key.intern] = value
    end
  end

  def exists?
    enabled = powershell "(Get-NetFirewallProfile -profile \"#{resource[:name]}\").Enabled"
    enabled.delete("\n").strip == 'True' ? true : false
  end

  def create
    args = []
    args << 'Set-NetFirewallProfile' << '-Profile' << "\"#{resource[:name]}\"" << '-Enabled' << 'True'
    args << '-DefaultInboundAction' << "\"#{resource[:default_inbound_action]}\"" if resource[:default_inbound_action]
    args << '-DefaultOutboundAction' << "\"#{resource[:default_outbound_action]}\"" if resource[:default_outbound_action]
    args << '-NotifyOnListen' << "\"#{resource[:notify_on_listen]}\"" if resource[:notify_on_listen]
    Puppet.debug "Ready to CREATE resource with: with command: `#{powershell} #{args}`"
    powershell args unless args.empty?
  end

  def destroy
    args = []
    args << 'Set-NetFirewallProfile' << '-Profile' << "\"#{resource[:name]}\"" << '-Enabled' << 'False'
    Puppet.debug "Ready to delete resource with: with command: `#{powershell} #{args}`"
    powershell args
  end

  def flush
    args = []
    unless @property_flush.empty?
      args << 'Set-NetFirewallProfile' << '-Profile' << "\"#{resource[:name]}\"" << '-Enabled' << 'True'
      args << '-DefaultInboundAction' << @property_flush[:default_inbound_action] if @property_flush[:default_inbound_action]
      args << '-DefaultOutboundAction' << @property_flush[:default_outbound_action] if @property_flush[:default_outbound_action]
      args << '-NotifyOnListen' << @property_flush[:notify_on_listen] if @property_flush[:notify_on_listen]
    end
    Puppet.debug "Ready to flush values with: with command: `#{args}`"
    powershell args unless args.empty?
  end
end

