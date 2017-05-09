Puppet::Type.newtype(:windowsfirewall) do
  desc "Puppet type that models Windows Firewall rules"
  ensurable

  newparam(:name, :namevar => true) do
    newvalues(:domain, :public, :private)
    desc "Windows firewall zones - either 'domain', 'public', or 'private'"
  end

  newproperty(:default_inbound_action) do
    desc "Default inbound rules for the zone"
    munge do |value|
      value.downcase
    end
    def insync?(is)
      is.downcase == should.downcase
    end
  end

  newproperty(:default_outbound_action) do
    desc "Default outbound rules for the zone"
    munge do |value|
      value.downcase
    end
    def insync?(is)
      is.downcase == should.downcase
    end
  end

  newparam(:notify_on_listen) do
    desc "Notify on listen"
    munge do |value|
      value.downcase
    end
    def insync?(is)
      is.downcase == should.downcase
    end
  end
end
