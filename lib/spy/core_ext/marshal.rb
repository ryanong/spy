module Marshal
  class << self
    # @private
    def dump_with_mocks(*args)
      object = args.shift
      spies = Spy::Subroutine.get_spies(object)
      if spies.empty?
        return dump_without_mocks(*args.unshift(object))
      end

      spy_hook_options = spies.map do |spy|
        [spy.hook_opts, spy.unhook]
      end

      begin
        dump_without_mocks(*args.unshift(object.dup))
      ensure
        spy_hook_options.each do |hook_opts, spy|
          spy.hook(hook_opts)
        end
      end
    end

    alias_method :dump_without_mocks, :dump
    undef_method :dump
    alias_method :dump, :dump_with_mocks
  end
end
