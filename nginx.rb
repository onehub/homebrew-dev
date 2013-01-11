require 'formula'

class Nginx < Formula
  homepage 'http://nginx.org/'
  url 'http://nginx.org/download/nginx-1.0.0.tar.gz'
  md5 '5751c920c266ea5bb5fc38af77e9c71c'

  depends_on 'pcre'

  skip_clean 'logs'

  def patches
    # Changes default port to 8080
    # Set configure to look in homebrew prefix for pcre
    DATA
  end

  def options
    [
      ['--with-debug',        "Compile with support for debugging"],
      ['--with-gzip-static',  "Compile with support for Gzip Static module"],
      ['--with-stub-status',  "Compile with support for Stub Status module"],
      ['--with-passenger',    "Compile with support for Phusion Passenger module"],
      ['--with-webdav',       "Compile with support for WebDAV module"],
      ['--with-upload',       "Compile with support for Upload module"],
      ['--with-zip',          "Compile with support for Zip module"],
      ['--with-headers-more', "Compile with support for Headers More module"]
    ]
  end

  def passenger_config_args
      passenger_root = `passenger-config --root`.chomp

      if File.directory?(passenger_root)
        return "--add-module=#{passenger_root}/ext/nginx"
      end

      puts "Unable to install nginx with passenger support. The passenger"
      puts "gem must be installed and passenger-config must be in your path"
      puts "in order to continue."
      exit
  end

  def upload_config_args
    prepare_nginx_upload_module

    "--add-module=#{nginx_upload_module_dirname}"
  end

  def zip_config_args
    prepare_nginx_zip_module

    "--add-module=#{nginx_zip_module_dirname}"
  end

  def headers_more_config_args
    prepare_nginx_headers_more_module

    "--add-module=#{nginx_headers_more_module_dirname}"
  end

  def install
    args = ["--prefix=#{prefix}",
            "--with-http_ssl_module",
            "--with-pcre",
            "--conf-path=#{etc}/nginx/nginx.conf",
            "--pid-path=#{var}/run/nginx.pid",
            "--lock-path=#{var}/nginx/nginx.lock"]

    # Core modules
    args << "--with-debug" if ARGV.include? '--with-debug'
    args << "--with-http_gzip_static_module" if ARGV.include? "--with-gzip-static"
    args << "--with-http_stub_status_module" if ARGV.include? "--with-stub-status"
    args << "--with-http_dav_module" if ARGV.include? '--with-webdav'

    # Third party modules
    args << passenger_config_args if ARGV.include? '--with-passenger'
    args << upload_config_args if ARGV.include? '--with-upload'
    args << zip_config_args if ARGV.include? '--with-zip'
    args << headers_more_config_args if ARGV.include? '--with-headers-more'

    system "./configure", *args
    system "make install"

    (prefix+'org.nginx.plist').write startup_plist
  end

  def caveats
    <<-CAVEATS
In the interest of allowing you to run `nginx` without `sudo`, the default
port is set to localhost:8080.

If you want to host pages on your local machine to the public, you should
change that to localhost:80, and run `sudo nginx`. You'll need to turn off
any other web servers running port 80, of course.

You can start nginx automatically on login with:
    mkdir -p ~/Library/LaunchAgents
    cp #{prefix}/org.nginx.plist ~/Library/LaunchAgents/
    launchctl load -w ~/Library/LaunchAgents/org.nginx.plist

    CAVEATS
  end

  def startup_plist
    return <<-EOPLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
  <dict>
    <key>Label</key>
    <string>org.nginx</string>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <true/>
    <key>UserName</key>
    <string>#{`whoami`.chomp}</string>
    <key>ProgramArguments</key>
    <array>
        <string>#{sbin}/nginx</string>
        <string>-g</string>
        <string>daemon off;</string>
    </array>
    <key>WorkingDirectory</key>
    <string>#{HOMEBREW_PREFIX}</string>
  </dict>
</plist>
    EOPLIST
  end

  protected

  # Upload Module
  def prepare_nginx_upload_module
    ohai "Downloading #{nginx_upload_module_url}"
    curl "-O", nginx_upload_module_url

    ohai "Extracting #{nginx_upload_module_filename}"
    safe_system "/usr/bin/tar", "-zxvf", nginx_upload_module_filename
  end

  def nginx_upload_module_url
    "http://apt.onehub.com/nginx_modules/nginx_upload_module-2.0.12c.tar.gz"
  end

  def nginx_upload_module_filename
    @nginx_upload_module_filename ||= nginx_upload_module_url.split('/').last
  end

  def nginx_upload_module_dirname
    nginx_upload_module_filename.sub(".tar.gz", "")
  end

  # Zip Module
  def prepare_nginx_zip_module
    ohai "Downloading #{nginx_zip_module_url}"
    curl "-O", nginx_zip_module_url

    ohai "Extracting #{nginx_zip_module_filename}"
    safe_system "/usr/bin/tar", "-zxvf", nginx_zip_module_filename
  end

  def nginx_zip_module_url
    "http://apt.onehub.com/nginx_modules/mod_zip-1.1.6.tar.gz"
  end

  def nginx_zip_module_filename
    @nginx_zip_module_filename ||= nginx_zip_module_url.split('/').last
  end

  def nginx_zip_module_dirname
    nginx_zip_module_filename.sub(".tar.gz", "")
  end

  # Headers More Module
  def prepare_nginx_headers_more_module
    ohai "Downloading #{nginx_headers_more_module_url}"
    curl "-O", nginx_headers_more_module_url

    ohai "Extracting #{nginx_headers_more_module_filename}"
    safe_system "/usr/bin/tar", "-zxvf", nginx_headers_more_module_filename
  end

  def nginx_headers_more_module_url
    "http://apt.onehub.com/nginx_modules/headers-more-0.13.tar.gz"
  end

  def nginx_headers_more_module_filename
    @nginx_headers_more_module_filename ||= nginx_headers_more_module_url.split('/').last
  end

  def nginx_headers_more_module_dirname
    nginx_headers_more_module_filename.sub(".tar.gz", "")
  end
end

__END__
--- a/auto/lib/pcre/conf
+++ b/auto/lib/pcre/conf
@@ -155,6 +155,22 @@ else
             . auto/feature
         fi

+        if [ $ngx_found = no ]; then
+
+            # Homebrew
+            HOMEBREW_PREFIX=${NGX_PREFIX%Cellar*}
+            ngx_feature="PCRE library in ${HOMEBREW_PREFIX}"
+            ngx_feature_path="${HOMEBREW_PREFIX}/include"
+
+            if [ $NGX_RPATH = YES ]; then
+                ngx_feature_libs="-R${HOMEBREW_PREFIX}/lib -L${HOMEBREW_PREFIX}/lib -lpcre"
+            else
+                ngx_feature_libs="-L${HOMEBREW_PREFIX}/lib -lpcre"
+            fi
+
+            . auto/feature
+        fi
+
         if [ $ngx_found = yes ]; then
             CORE_DEPS="$CORE_DEPS $REGEX_DEPS"
             CORE_SRCS="$CORE_SRCS $REGEX_SRCS"
--- a/conf/nginx.conf
+++ b/conf/nginx.conf
@@ -33,7 +33,7 @@
     #gzip  on;

     server {
-        listen       80;
+        listen       8080;
         server_name  localhost;

         #charset koi8-r;

