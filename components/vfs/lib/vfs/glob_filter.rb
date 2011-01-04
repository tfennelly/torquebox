require 'vfs/glob_translator'


module VFS
  class GlobFilter
    include Java::org.jboss.vfs.VirtualFileFilter
  
    def initialize(child_path, glob)
      regexp_str = GlobTranslator.translate( glob )
      if ( child_path && child_path != '' )
        if ( child_path[-1,1] == '/' )
          regexp_str = "^#{child_path}#{regexp_str}$"
        else
          regexp_str = "^#{child_path}/#{regexp_str}$"
        end
      else
        regexp_str = "^#{regexp_str}$"
      end
      @regexp = Regexp.new( regexp_str ) 
      #puts "new glob filter: #{@regexp}"
    end
  
    def accepts(file)
      #puts "accepts? #{file}"
      !!( file.path_name =~ @regexp )
    end

    def to_s
      "[GlobFilter: @regxp=#{@regexp}]"
    end
  end
end

