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

  def exists?
    enabled = powershell '(Get-NetFirewallProfile -profile "domain").Enabled'
    enabled.delete("\n").strip == 'True' ? true : false
  end

  def create
    Puppet.debug "Create the thing here"
  end

  def destroy
    Puppet.debug "Destroy the thing here"
  end

  def default_inbound_action
    value = powershell "(Get-NetFirewallProfile -profile \"domain\").DefaultInboundAction"
    value.delete("\n").strip
  end

  def default_inbound_action=(value)
    @property_flush[:default_inbound_action] = value
  end

  def default_outbound_action
    value = powershell "(Get-NetFirewallProfile -profile \"domain\").DefaultOutboundAction"
    value.delete("\n").strip
  end

  def default_outbound_action=(value)
    @property_flush[:default_outbound_action] = value
  end

  def notify_on_listen
    powershell "(Get-NetFirewallProfile -profile \"domain\").NotifyOnListen".delete("\n").strip
  end

  def notify_on_listen=(value)
    @property_flush[:notify_on_listen] = value
  end

  def flush
    args = []
    unless @property_flush.empty?
      args << 'Set-NetFirewallProfile' << '-Profile' << '"domain"'
      args << '-DefaultInboundAction' << @property_flush[:default_inbound_action] if @property_flush[:default_inbound_action]
      args << '-DefaultOutboundAction' << @property_flush[:default_outbound_action] if @property_flush[:default_outbound_action]
      args << '-NotifyOnListen' << @property_flush[:notify_on_listen] if @property_flush[:notify_on_listen]
    end
    Puppet.debug "Ready to flush values with: with command: `#{args}`"
    powershell args unless args.empty?
  end
end

