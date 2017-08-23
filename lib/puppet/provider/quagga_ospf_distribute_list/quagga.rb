Puppet::Type.type(:quagga_ospf_distribute_list).provide :quagga do
  @doc = 'Manages OSPF distribute-lists using quagga.'

  commands :vtysh => 'vtysh'

  def initialize(value)
    super(value)
    @property_flush = {}
  end

  def self.instances
    providers = []
    hash = {}
    found_distribute_list = false

    config = vtysh('-c', 'show running-config')
    config.split(/\n/).collect do |line|

      next if line =~ /\A!\Z/

      if line =~ /\A\sdistribute-list\s(\w+)\sout(\w+)\Z/

        found_distribute_list = true

        hash = {
            :ensure => :present,
            :name => $2,
            :access_list => $1,
        }

        providers << new(hash)
      elsif line =~ /\A\w/ and found_distribute_list
        break
      end
    end
    providers
  end

  def self.prefetch(resources)
    providers = instances
    resources.keys.each do |name|
      if provider = providers.find { |provider| provider.name == name }
        resources[name].provider = provider
      end
    end
  end

  def create
    debug 'Creating the ospf distribute-list for %{name}.' % {
      :name => @resource[:name],
    }

    cmds = []
    cmds << 'configure terminal'
    cmds << 'router ospf'

    cmds << 'distribute-list %{acl} out %{name}' % {
        :name => @resource[:name],
        :acl  => @resource[:access_list],
    }

    cmds << 'end'
    cmds << 'write memory'
    vtysh(cmds.reduce([]){ |cmds, cmd| cmds << '-c' << cmd })

    @property_hash[:ensure] = :present
  end

  def destroy
    debug 'Destroying the bgp community list %{name}.' % {
      :name => @property_hash[:name],
    }

    cmds = []
    cmds << 'configure terminal'
    cmds << 'router ospf'

    cmds << 'no distribute-list %{acl} out %{name}' % {
      :name => @property_hash[:name],
      :acl  => $property_hash[:access_list],
    }

    cmds << 'end'
    cmds << 'write memory'
    vtysh(cmds.reduce([]){ |cmds, cmd| cmds << '-c' << cmd })

    @property_hash.clear
  end

  def exists?
    @property_hash[:ensure] == :present
  end

  def access_list=(value)

  end
end
