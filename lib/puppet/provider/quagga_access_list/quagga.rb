Puppet::Type.type(:quagga_access_list).provide :quagga do
  @doc = %q{ Manages access lists using zebra }

  commands :vtysh => 'vtysh'

  mk_resource_methods

  def self.instances
    providers = []
    found_list = false

    name, remark, rules = nil, nil, []

    config = vtysh('-c', 'show running-config')
    config.split(/\n/).collect do |line|

      if line =~ /\Aaccess-list\s(\w)\s(.*)\Z/
        the_data = $2

        if $1 == name or name.nil?
          name = $1
          if the_data =~ /\Aremark/
            remark = the_data[7..-1]
          elsif the_data =~ /\A(deny|permit)/
            rules << the_data
          end
          next
        else
          remark = remark.nil? ? remark : :absent
          hash = {
              name:   name,
              ensure: :present,
              remark:  remark,
              rules: rules,
          }
          debug 'Instantiated the resource %{hash}' % { hash: hash.inspect }
          providers << new(hash)
  
          found_list= true
          name, remark, rules = $1, nil, []
          if the_data =~ /\Aremark/
            remark = the_data[7..-1]
          elsif the_data =~ /\A(deny|permit)/
            rules << the_data
          end
        end
      elsif line =~ /\A\w/ and found_list
        remark = remark.nil? ? remark : :absent
        hash = {
            name:   name,
            ensure: :present,
            remark:  remark,
            rules: rules,
        }
        debug 'Instantiated the resource %{hash}' % { hash: hash.inspect }
        providers << new(hash)
        break
      end
    end

    providers
  end

  def self.prefetch(resources)
    instances.each do |provider|
      if resource = resources[provider.name]
        debug 'Prefetched the resource %{resource}' % { resource: resource.to_hash.inspect }
        resource.provider = provider
      end
    end
  end

  def create
    name = @resource[:name]

    debug 'Creating the resource %{resource}.' % { resource: @resource.to_hash.inspect }

    cmds = []
    cmds << 'configure terminal'

    name = @resource[:name]

    cmds << "no access-list #{name}"
    cmds << "access-list #{name} remark #{@resource[:remark]}" unless @resource[:remark] == :absent

    @resource[:rules].each { |rule|
      cmds << "access-list #{name} #{rule}"
    }

    cmds << 'end'
    cmds << 'write memory'
    vtysh(cmds.reduce([]){ |commands, command| commands << '-c' << command })

    @property_hash = @resource.to_hash
  end

  def destroy
    name = @property_hash[:name]

    debug 'Destroying the resource %{resource}.' % { resource: @property_hash.inspect }

    cmds = []
    cmds << 'configure terminal'

    cmds << "no access-list #{name}"

    cmds << 'end'
    cmds << 'write memory'
    vtysh(cmds.reduce([]){ |commands, command| commands << '-c' << command })

    @property_hash.clear
  end

  def exists?
    @property_hash[:ensure] == :present and @property_hash[:remark] == @resource[:remark] and @property_hash[:rules] == @resource[:rules]
  end

  def remark=(value)
    create
  end

  def rules=(value)
    destroy
    create
  end
end
