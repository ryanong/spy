module Spy
  module Rails
    class IllegalDataAccessException
      def to_s
        @mesg || "stubbed models are not allowed to access the database"
      end
    end

    module ActiveModelStubExtensions
      # Stubs `persisted` to return false and `id` to return nil
      def as_new_record
        Spy.on(self, :persisted? => false, :id => nil)
        self
      end

      # Returns `true` by default. Override with a stub.
      def persisted?
        true
      end
    end

    module ActiveRecordStubExtensions
      # Stubs `id` (or other primary key method) to return nil
      def as_new_record
        self.__send__("#{self.class.primary_key}=", nil)
        super
      end

      # Returns the opposite of `persisted?`.
      def new_record?
        !persisted?
      end

      # Raises an IllegalDataAccessException (stubbed models are not allowed to access the database)
      # @raises IllegalDataAccessException
      def connection
        raise Spy::Rails::IllegalDataAccessException
      end
    end

    @@model_id = 1000
    class << self
      def next_id
        @@model_id += 1
      end

      def model(klass, stubs = {})
        model_class.new.tap do |m|
          m.extend ActiveModelStubExtensions
          if defined?(ActiveRecord) && model_class < ActiveRecord::Base
            m.extend ActiveRecordStubExtensions
            primary_key = model_class.primary_key.to_sym
            stubs = stubs.reverse_merge(primary_key => next_id)
            stubs = stubs.reverse_merge(:persisted? => !!stubs[primary_key])
          else
            stubs = stubs.reverse_merge(:id => next_id)
            stubs = stubs.reverse_merge(:persisted? => !!stubs[:id])
          end
          stubs = stubs.reverse_merge(:blank? => false)
          stubs.each do |k,v|
            m.__send__("#{k}=", stubs.delete(k)) if m.respond_to?("#{k}=")
          end
          Spy.on(self, stubs)
          yield m if block_given?
        end
      end
    end
  end
end
