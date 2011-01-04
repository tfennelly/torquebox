require 'vfs/glob_filter'
require 'vfs/debug_filter'

class Dir

  class << self

    alias_method :open_before_vfs, :open
    alias_method :glob_before_vfs, :glob
    alias_method :mkdir_before_vfs, :mkdir
    alias_method :new_before_vfs, :new
    alias_method :entries_before_vfs, :entries
    alias_method :foreach_before_vfs, :foreach

    def open(str,&block)
      #if ( ::File.exist_without_vfs?( str.to_str ) && ! Java::OrgJbossVirtualPluginsContextJar::JarUtils.isArchive( str.to_str ) )
      if ( ::File.exist_without_vfs?( str.to_str ) )
        return open_before_vfs(str,&block)
      end
      #puts "open(#{str})"
      result = dir = VFS::Dir.new( str.to_str )
      #puts "  result = #{result}"
      if block
        begin
          result = block.call(dir)
        ensure
          dir.close
        end
      end
      #puts "open(#{str}) return #{result}"
      result
    end

    def [](pattern)
      self.glob( pattern )
    end

    def glob(pattern,flags=0, &block)
      is_absolute_vfs = false

      #str_pattern = "#{pattern}"
      str_pattern = pattern.to_str
      #puts "glob(#{str_pattern})"

      segments = str_pattern.split( '/' )

      base_segments = []
      for segment in segments
        if ( segment =~ /[\*\?\[\{\}]/ )
          break
        end
        base_segments << segment
      end

      base = base_segments.join( '/' )

      base.gsub!( /\\(.)/, '\1' )

      #if ( base.empty? || ( ::File.exist_without_vfs?( base ) && ! Java::OrgJbossVirtualPluginsContextJar::JarUtils.isArchive( base ) ) )
      #if ( base.empty? || ( ::File.exist_without_vfs?( base ) ) )
        #puts "doing FS glob"
        #paths = glob_before_vfs( str_pattern, flags, &block )
        #return paths
      #end

      #puts "base= #{base}"

      vfs_url, child_path = VFS.resolve_within_archive( base )
      #puts "vfs_url=#{vfs_url}"
      #puts "child_path=#{child_path}"

      return []       if vfs_url.nil?
      #puts "segments.size==base_segments.size? #{segments.size == base_segments.size}"
      return [ base ] if segments.size == base_segments.size

      matcher_segments = segments - base_segments
      matcher = matcher_segments.join( '/' )
      #puts "matcher [#{matcher}]"

      begin
        #puts "0 vfs_url=#{vfs_url}"
        starting_point = root = org.jboss.vfs::VFS.child( vfs_url )
        starting_point = root.get_child( child_path ) unless ( child_path.nil? || child_path == '' )
        #puts "B starting_point=#{starting_point.path_name}"
        return [] if ( starting_point.nil? || ! starting_point.exists? )
        child_path = starting_point.path_name
        #puts "child- #{child_path}"
        unless ( child_path =~ %r(/$) )
          child_path = "#{child_path}/"
        end
        child_path = "" if child_path == "/"
        puts "child_path=#{child_path}"
        #puts "base=#{base}"
        filter = VFS::GlobFilter.new( child_path, matcher )
        puts "starting_port #{starting_point}"
        puts "filter is #{filter}"

        #starting_point.getChildrenRecursively( VFS::DebugFilter.new )

        paths = starting_point.getChildrenRecursively( filter ).collect{|e|
          #path_name = e.path_name
          path_name = e.getPathNameRelativeTo( starting_point )
          #puts "(collect) path_name=#{path_name}"
          result = ::File.join( base, path_name )
          #puts "(collect) result=#{result}"
          result
        }
        paths.each{|p| block.call(p)} if block
        #puts "Path=#{paths.inspect}"
        paths
      rescue Java::JavaIo::IOException => e
        return []
      end
    end

    def mkdir(path, mode=0777)
      #real_path = path =~ /^vfs:/ ? path[4..-1] : path
      case ( path )
        when %r(^vfs:/([a-zA-Z]:.*)$)
	  #puts "windows absolute"
	  real_path = $1
	when %r(^vfs:(.*)$)
	  #puts "unix absolute"
	  real_path = $1
	else
	  #puts "otherwise!"
	  real_path = path
      end
      #puts "REAL_PATH 1 #{real_path}"
      mkdir_before_vfs( real_path, mode )
    rescue Errno::ENOTDIR => e
      #puts "REAL_PATH 2 #{path}"
      path = VFS.writable_path_or_error( path, e )
      mkdir_before_vfs( path, mode )
    rescue Errno::ENOENT => e
      #puts "REAL_PATH 3 #{path}"
      path = VFS.writable_path_or_error( path, e )
      mkdir_before_vfs( path, mode )
    end

    def new(string)
      if ( ::File.exist_without_vfs?( string.to_s ) )
        return new_before_vfs( string )
      end
      VFS::Dir.new( string.to_s )
    end

    def entries(path)
      if ( ::File.exist_without_vfs?( path.to_str ) )
        return entries_before_vfs(path.to_str)
      end
      vfs_dir = org.jboss.vfs::VFS.child( path )
      [ '.', '..' ] + vfs_dir.children.collect{|e| e.name }
    end

    def foreach(path,&block)
      entries(path).each{|e| yield e}
    end 

  end
end

