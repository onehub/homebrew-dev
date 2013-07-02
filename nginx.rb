require 'formula'

class Nginx < Formula
  homepage 'http://nginx.org/'
  url 'http://nginx.org/download/nginx-1.2.9.tar.gz'
  sha1 '9f31266c0088561b0bdaa9238af8adf1a2fd0ba4'

  depends_on 'pcre'
  depends_on 'openssl'

  skip_clean 'logs'

  def patches
    [
      "http://apt.onehub.com/homebrew/nginx/msec_start_msec.patch",
      "http://apt.onehub.com/homebrew/nginx/url-encode.patch"
    ]
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
    args = [
      "--prefix=#{prefix}",
      "--conf-path=#{etc}/nginx/nginx.conf",
      "--error-log-path=#{var}/nginx/error.log",
      "--http-log-path=#{var}/nginx/access.log",
      "--http-client-body-temp-path=#{var}/cache/nginx/client_temp",
      "--http-proxy-temp-path=#{var}/cache/nginx/proxy_temp",
      "--http-fastcgi-temp-path=#{var}/cache/nginx/fastcgi_temp",
      "--http-uwsgi-temp-path=#{var}/cache/nginx/uwsgi_temp",
      "--http-scgi-temp-path=#{var}/cache/nginx/scgi_temp",
      "--lock-path=#{var}/lock/nginx.lock",
      "--pid-path=#{var}/run/nginx.pid",
      "--with-pcre-jit",
      "--with-debug",
      "--with-ipv6",
      "--without-http_browser_module",
      "--without-http_empty_gif_module",
      "--without-http_fastcgi_module",
      "--without-http_geo_module",
      "--without-http_memcached_module",
      "--without-http_referer_module",
      "--without-http_scgi_module",
      "--without-http_split_clients_module",
      "--without-http_ssi_module",
      "--without-http_userid_module",
      "--without-http_uwsgi_module",
      "--without-mail_pop3_module",
      "--without-mail_imap_module",
      "--without-mail_smtp_module",
      "--with-http_gzip_static_module",
      "--with-http_realip_module",
      "--with-http_ssl_module",
      "--with-http_stub_status_module"
    ]

    # Third party modules
    args << upload_config_args
    args << zip_config_args
    args << headers_more_config_args

  system "./configure", *args
    system "make"
    system "make install"
    man8.install "objs/nginx.8"
    (var/'run/nginx').mkpath
    (var/'cache/nginx/client_temp').mkpath
  end

  def caveats; <<-EOS.undent
    You can start nginx automatically on login running as your user with:
      mkdir -p ~/Library/LaunchAgents
      sudo cp #{plist_path} ~/Library/LaunchAgents/
      sudo launchctl load -w ~/Library/LaunchAgents/#{plist_path.basename}

    Though note that if running as your user, the launch agent will fail if you
    try to use a port below 1024 (such as http's default of 80.)
    EOS
  end

  def plist; <<-EOS.undent
    <?xml version="1.0" encoding="UTF-8"?>
    <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
    <plist version="1.0">
      <dict>
        <key>Label</key>
        <string>#{plist_name}</string>
        <key>RunAtLoad</key>
        <true/>
        <key>KeepAlive</key>
        <false/>
        <key>UserName</key>
        <string>root</string>
        <key>ProgramArguments</key>
        <array>
            <string>#{opt_prefix}/sbin/nginx</string>
        </array>
        <key>WorkingDirectory</key>
        <string>#{HOMEBREW_PREFIX}</string>
      </dict>
    </plist>
    EOS
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
    "http://apt.onehub.com/homebrew/nginx/nginx_upload_module-2.0.12c.tar.gz"
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
    "http://apt.onehub.com/homebrew/nginx/mod_zip-1.1.6.tar.gz"
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
    "http://apt.onehub.com/homebrew/nginx/headers-more-nginx-module-0.19.tar.gz"
  end

  def nginx_headers_more_module_filename
    @nginx_headers_more_module_filename ||= nginx_headers_more_module_url.split('/').last
  end

  def nginx_headers_more_module_dirname
    nginx_headers_more_module_filename.sub(".tar.gz", "")
  end
end
