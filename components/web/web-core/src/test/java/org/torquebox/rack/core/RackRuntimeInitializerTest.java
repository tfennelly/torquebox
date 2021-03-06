/*
 * Copyright 2008-2011 Red Hat, Inc, and individual contributors.
 * 
 * This is free software; you can redistribute it and/or modify it
 * under the terms of the GNU Lesser General Public License as
 * published by the Free Software Foundation; either version 2.1 of
 * the License, or (at your option) any later version.
 * 
 * This software is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * Lesser General Public License for more details.
 * 
 * You should have received a copy of the GNU Lesser General Public
 * License along with this software; if not, write to the Free
 * Software Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA
 * 02110-1301 USA, or see the FSF site: http://www.fsf.org.
 */

package org.torquebox.rack.core;

import static org.junit.Assert.*;

import org.jboss.vfs.VFS;
import org.jruby.Ruby;
import org.junit.Test;
import org.torquebox.base.metadata.RubyApplicationMetaData;
import org.torquebox.rack.metadata.RackApplicationMetaData;
import org.torquebox.test.ruby.AbstractRubyTestCase;

public class RackRuntimeInitializerTest extends AbstractRubyTestCase {

    @Test
    public void testInitializer() throws Exception {
        RubyApplicationMetaData rubyAppMetaData = new RubyApplicationMetaData();
        RackApplicationMetaData rackAppMetaData = new RackApplicationMetaData();
        rubyAppMetaData.setApplicationName( "app_name" );
        rubyAppMetaData.setRoot( VFS.getChild( "/myapp" ) );
        rubyAppMetaData.setEnvironmentName( "test" );
        rackAppMetaData.setContextPath( "/mycontext" );

        RackRuntimeInitializer initializer = new RackRuntimeInitializer( rubyAppMetaData, rackAppMetaData );

        Ruby ruby = createRuby();
        initializer.initialize( ruby );

        String rackRoot = (String) ruby.evalScriptlet( "RACK_ROOT" ).toJava( String.class );
        assertEquals( "vfs:" + vfsAbsolutePrefix() + "/myapp", rackRoot );

        String rackEnv = (String) ruby.evalScriptlet( "RACK_ENV" ).toJava( String.class );
        assertEquals( "test", rackEnv );

        String pwd = (String) ruby.evalScriptlet( "Dir.pwd" ).toJava( String.class );
        assertEquals( absolutePrefix() + "/myapp", pwd );

        String baseUri = (String) ruby.evalScriptlet( "ENV['RACK_BASE_URI']" ).toJava( String.class );
        assertEquals( "/mycontext", baseUri );

        String appName = (String) ruby.evalScriptlet( "ENV['TORQUEBOX_APP_NAME']" ).toJava( String.class );
        assertEquals( "app_name", appName );

        appName = (String) ruby.evalScriptlet( "TORQUEBOX_APP_NAME" ).toJava( String.class );
        assertEquals( "app_name", appName );

    }
}
