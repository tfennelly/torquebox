
require 'fileutils'
require File.dirname(__FILE__) +  '/spec_helper.rb'

describe "Dir extensions for VFS" do

  before(:each) do
    @executor = java.util.concurrent::Executors.newScheduledThreadPool( 1 )
    @temp_file_provider = org.jboss.vfs::TempFileProvider.create( "vfs-test", @executor )

    @archive1_path = fix_windows_path( File.expand_path( "#{TEST_DATA_DIR}/home/larry/archive1.jar" ) )
    puts "path.1.0=#{@archive1_path}"
    @archive1_file = org.jboss.vfs::VFS.child( @archive1_path )
    puts "archive.1=#{@archive1_file}"
    @archive1_mount_point = org.jboss.vfs::VFS.child( @archive1_path )
    puts "mount.1 = #{@archive1_mount_point}"
    @archive1_handle = org.jboss.vfs::VFS.mountZip( @archive1_file, @archive1_mount_point, @temp_file_provider )

    @archive2_path = "#{@archive1_path}/lib/archive2.jar"
    @archive2_file = org.jboss.vfs::VFS.child( @archive2_path )
    @archive2_mount_point = org.jboss.vfs::VFS.child( @archive2_path )
    puts "mount.2 = #{@archive2_mount_point}"
    @archive2_handle = org.jboss.vfs::VFS.mountZip( @archive2_file, @archive2_mount_point, @temp_file_provider )

    @archive1_path = fix_windows_path( @archive1_path )
    @archive2_path = fix_windows_path( @archive2_path )

    puts "archive1.path=#{@archive1_path}"
    puts "archive2.path=#{@archive2_path}"

  end

  after(:each) do
    @archive2_handle.close
    @archive1_handle.close
  end

  describe "with vfs urls" do
    it "should allow globbing within archives with explicit vfs" do
      pattern = "vfs:#{@archive1_path}/*"
      puts "######## START"
      puts "######## START"
      puts "######## START"
      puts "######## START"
      puts "######## START"
      puts "######## PATTERN #{pattern}"
      items = Dir.glob( pattern )
      puts "######## ITEMS #{items.inspect}"
      puts "######## END"
      puts "######## END"
      puts "######## END"
      puts "######## END"
      puts "######## END"
      items.should_not be_empty
      items.should include File.join( "vfs:#{@archive1_path}", 'web.xml' )
      items.should include File.join( "vfs:#{@archive1_path}", 'lib' )
    end

    it "should allow globbing within nested archives with explicit vfs" do
      pattern = "vfs:#{@archive2_path}/*"
      items = Dir.glob( pattern )
      items.should_not be_empty
      items.should include "vfs:#{@archive2_path}/manifest.txt"
    end

    it "should create new Dirs" do
      lambda {
        Dir.new("vfs:#{@archive2_path}")
      }.should_not raise_error
    end
  end

  [ :absolute, :relative, :vfs ].each do |style|
  #[ :relative ].each do |style|
    describe "with #{style} paths" do

      case ( style )
        when :relative
          prefix = "./#{TEST_DATA_BASE}"
        when :absolute
          prefix = fix_windows_path( File.expand_path( File.join( File.dirname( __FILE__ ), '..', TEST_DATA_BASE ) ) )
        when :vfs
          prefix = "vfs:" + fix_windows_path( File.expand_path( File.join( File.dirname( __FILE__ ), '..', TEST_DATA_BASE ) ) )
      end

      it "should ignore dotfiles by default" do
        items = Dir.glob( "#{prefix}/dotfiles/*" )
        items.should_not be_empty
        items.size.should eql(3)
        items.should include( "#{prefix}/dotfiles/one" )
        items.should include( "#{prefix}/dotfiles/three" )
        items.should include( "#{prefix}/dotfiles/foo.txt" )
      end

      it "should match dotfiles if explicitly asked" do
        items = Dir.glob( "#{prefix}/dotfiles/.*" )
        items.should_not be_empty
        items.size.should eql(2)
        items.should include( "#{prefix}/dotfiles/.two" )
        items.should include( "#{prefix}/dotfiles/.four" )
      end

      it "should allow globbing without any special globbing characters on normal files" do
        items = Dir.glob( "#{prefix}/home/larry" )
        items.should_not be_empty
        items.should include( "#{prefix}/home/larry" )
      end

      it "should allow globbing without any special globbing characters on a single normal file" do
        items = Dir.glob( "#{prefix}/home/larry/file1.txt" )
        items.should_not be_empty
        items.should include( "#{prefix}/home/larry/file1.txt" )
      end

      it "should allow globbing without any special globbing characters for archives" do
        items = Dir.glob( "#{prefix}/home/larry/archive1.jar" )
        items.should_not be_empty
        items.should include( "#{prefix}/home/larry/archive1.jar" )
      end

      it "should allow globbing without any special globbing characters within archives" do
        items = Dir.glob( "#{prefix}/home/larry/archive1.jar/web.xml" )
        items.should_not be_empty
        items.should include( "#{prefix}/home/larry/archive1.jar/web.xml" )
      end

      it "should allow globbing without any special globbing characters for nested archives" do
        items = Dir.glob( "#{prefix}/home/larry/archive1.jar/lib/archive2.jar" )
        items.should_not be_empty
        items.should include( "#{prefix}/home/larry/archive1.jar/lib/archive2.jar" )
      end

      it "should allow globbing without any special globbing characters for within archives" do
        items = Dir.glob( "#{prefix}/home/larry/archive1.jar/lib/archive2.jar/manifest.txt" )
        items.should_not be_empty
        items.should include( "#{prefix}/home/larry/archive1.jar/lib/archive2.jar/manifest.txt" )
      end

      it "should provide access to entries" do
        items = Dir.entries( "#{prefix}/home/larry" )
        items.should_not be_empty
        items.size.should eql( 5 )
        items.should include( "." )
        items.should include( ".." )
        items.should include( "file1.txt" )
        items.should include( "file2.txt" )
        items.should include( "archive1.jar" )
      end

      it "should provide iteration over its entries" do
        items = []
        Dir.foreach( "#{prefix}/home/larry" ) do |e|
          items << e
        end

        items.should_not be_empty
        items.size.should eql( 5 )
        items.should include( "." )
        items.should include( ".." )
        items.should include( "file1.txt" )
        items.should include( "file2.txt" )
        items.should include( "archive1.jar" )
      end

      it "should allow appropriate globbing of normal files" do
        items = Dir.glob( "#{prefix}/home/larry/*" )
        items.should_not be_empty
        items.should include( "#{prefix}/home/larry/file1.txt" )
        items.should include( "#{prefix}/home/larry/file2.txt" )
        items.should include( "#{prefix}/home/larry/archive1.jar" )
      end

      it "should determine if VFS is needed for archives" do
        items = Dir.glob( "#{@archive1_path}/*" )
        items.should_not be_empty
      end

      it "should determine if VFS is needed for nested archives" do
        base = "#{prefix}/home/larry/archive1.jar/lib/archive2.jar"
	puts "glob against #{base}"
        items = Dir.glob( "#{base}/*" )
        items.should_not be_empty
        items.should include( "#{base}/manifest.txt" )
      end

      it "should determine if VFS is needed with relative paths" do
        base = "#{prefix}/home/larry/archive1.jar/lib/archive2.jar"
        items = Dir.glob( "#{base}/*" )
        items.should_not be_empty
        items.should include( "#{base}/manifest.txt" )
      end

      it "should allow character-class matching" do
        items = Dir.glob( "#{prefix}/home/{larry}/file[12].{txt}" )
        items.should_not be_empty
        items.size.should eql 2
        items.should include( "#{prefix}/home/larry/file1.txt" )
        items.should include( "#{prefix}/home/larry/file2.txt" )
      end

      it "should allow alternation globbing on normal files" do
        items = Dir.glob( "#{prefix}/home/{larry}/file{,1,2}.{txt}" )
        items.should_not be_empty
        items.size.should eql 2
        items.should include( "#{prefix}/home/larry/file1.txt" )
        items.should include( "#{prefix}/home/larry/file2.txt" )
      end

      it "should allow alternation globbing within archives" do
        items = Dir.glob( "#{prefix}/home/larry/archive1.jar/lib/archive*{.zip,.jar,.ear}" )
        items.should_not be_empty
        items.size.should eql 3
        items.should     include( "#{prefix}/home/larry/archive1.jar/lib/archive2.jar" )
        items.should     include( "#{prefix}/home/larry/archive1.jar/lib/archive3.ear" )
        items.should     include( "#{prefix}/home/larry/archive1.jar/lib/archive4.zip" )
        items.should_not include( "#{prefix}/home/larry/archive1.jar/lib/archive4.txt" )
      end

      it "should allow alternation globbing with trailing comma" do
        items = Dir.glob( "#{prefix}/home/todd/index{.en,}{.html,}{.erb,.haml,}" )
        items.should_not be_empty
        items.size.should eql 4
        items.should     include( "#{prefix}/home/todd/index.html.erb" )
        items.should     include( "#{prefix}/home/todd/index.en.html.erb" )
        items.should     include( "#{prefix}/home/todd/index.html.haml" )
        items.should     include( "#{prefix}/home/todd/index.en.html.haml" )
      end

      it "should allow alternation globbing with internal globs" do
        items = Dir.glob( "#{prefix}/home/{todd/*,larry/*}{.haml,.txt,.jar}" )
        items.should_not be_empty
        items.should     include( "#{prefix}/home/todd/index.html.haml" )
        items.should     include( "#{prefix}/home/todd/index.en.html.haml" )
        items.should     include( "#{prefix}/home/larry/file1.txt" )
        items.should     include( "#{prefix}/home/larry/file2.txt" )
        items.should     include( "#{prefix}/home/larry/archive1.jar" )
      end

      it "should allow for double-star globbing within archives" do
        items = Dir.glob( "#{prefix}/home/larry/archive1.jar/**/*.jar" )
        items.should_not be_empty
        #items.size.should eql 1
        items.should     include( "#{prefix}/home/larry/archive1.jar/lib/archive2.jar" )
        items.should     include( "#{prefix}/home/larry/archive1.jar/other_lib/subdir/archive6.jar" )
        items.should_not include( "#{prefix}/home/larry/archive1.jar/lib/archive4.txt" )
      end

      it "should create new Dirs" do
        lambda {
          Dir.new(prefix)
        }.should_not raise_error
      end

    end
  end

  describe "mkdir" do
    it "should mkdir inside vfs archive when directory mounted on filesystem" do
      FileUtils.rm_rf "target/mnt"
      archive = org.jboss.vfs::VFS.child( @archive1_path )
      logical = archive.getChild( "lib" )
      physical = java.io::File.new( "target/mnt" )
      physical.mkdirs
      mount = org.jboss.vfs::VFS.mountReal( physical, logical )
      prefix = @archive1_path
      if ( prefix =~ %r(^/([a-zA-Z]:.*)$) )
        prefix = $1
      end
      begin
        lambda {
          Dir.mkdir("#{prefix}/lib/should_mkdir_inside_vfs_archive")
          File.directory?("target/mnt/should_mkdir_inside_vfs_archive").should be_true
        }.should_not raise_error
      ensure
        mount.close
      end
    end
  end


end
