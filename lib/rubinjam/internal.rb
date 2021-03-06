module Rubinjam
  ROOT = File.expand_path("../", __FILE__) << "/rubinjam/"

  class << self
    def normalize_file(file)
      return file unless file.start_with?("/")
      if file.start_with?(ROOT)
        file.sub(ROOT, "")
      else
        file.split('/lib/').last
      end
    end

    def file_from_nesting(mod, const)
      if file = mod.rubinjam_autload[const]
        return [mod, file]
      end

      nesting(mod.name)[1..-1].detect do |mod|
        file = mod.rubinjam_autload[const]
        break [mod, file] if file
      end
    end

    # this does not reflect the actual Module.nesting of the caller,
    # but it should be close enough
    def nesting(name)
      nesting = []
      namespace = name.split("::")
      namespace.inject(Object) do |base, n|
        klass = base.const_get(n)
        nesting << klass
        klass
      end
      nesting.reverse
    end
  end

  module ModuleAutoloadFix
    def self.included(base)
      base.class_eval do
        def rubinjam_autload
          @rubinjam_autload ||= {}
        end

        alias autoload_without_rubinjam autoload
        def autoload(const, file)
          normalized_file = Rubinjam.normalize_file(file)
          if Rubinjam::LIBRARIES[normalized_file]
            rubinjam_autload[const] = normalized_file
          else
            autoload_without_rubinjam(const, file)
          end
        end

        alias const_missing_without_rubinjam const_missing
        def const_missing(const)
          # do not load twice / go into infitire loops
          @rubinjam_tried_const_missing ||= {}
          if @rubinjam_tried_const_missing[const]
            return const_missing_without_rubinjam(const)
          end
          @rubinjam_tried_const_missing[const] = true

          # try to find autoload in current module or nesting
          nesting, file = Rubinjam.file_from_nesting(self, const)
          if file
            require file
            nesting.const_get(const)
          else
            const_missing_without_rubinjam(const)
          end
        end
      end
    end
  end

  module BaseAutoloadFix
    def self.included(base)
      base.class_eval do
        alias autoload_without_rubinjam autoload

        def autoload(const, file)
          normalized_file = Rubinjam.normalize_file(file)
          if Rubinjam::LIBRARIES[normalized_file]
            require normalized_file
          else
            autoload_without_rubinjam(const, file)
          end
        end
      end
    end
  end
end

Module.send(:include, Rubinjam::ModuleAutoloadFix)
include Rubinjam::BaseAutoloadFix

def require(file)
  normalized_file = Rubinjam.normalize_file(file)
  if code = Rubinjam::LIBRARIES[normalized_file]
    return if code == :loaded
    eval(code, TOPLEVEL_BINDING, "rubinjam/#{normalized_file}.rb")
    Rubinjam::LIBRARIES[normalized_file] = :loaded
  else
    super
  end
end
