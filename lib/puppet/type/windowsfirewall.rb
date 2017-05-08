Puppet::Type.newtype(:windowsfirewall) do
  desc "Puppet type that models Windows Firewall rules"
  ensurable

  newparam(:name, :namevar => true) do
    desc "Windows proxy zones"
    #munge do |value|
    #  value.downcase
    #end
    #def insync?(is)
    #  is.downcase == should.downcase
    #end
  end

  newproperty(:default_inbound_action) do
    desc "Default inbound rules for the zone"
  end

  newproperty(:default_outbound_action) do
    desc "Default outbound rules for the zone"
  end

  newparam(:notify_on_listen) do
    desc "Notify on listen"
  end
end
