class ApacheSerf < Formula
  desc "HTTP client library based on APR"
  homepage "https://serf.apache.org/"
  url "https://www.apache.org/dyn/closer.lua?path=serf/serf-1.3.10.tar.bz2"
  mirror "https://archive.apache.org/dist/serf/serf-1.3.10.tar.bz2"
  sha256 "be81ef08baa2516ecda76a77adf7def7bc3227eeb578b9a33b45f7b41dc064e6"
  license "Apache-2.0"

  depends_on "scons" => :build
  depends_on "pkgconf" => :test
  depends_on "apr"
  depends_on "apr-util"
  depends_on "openssl@3"

  uses_from_macos "zlib"

  def install
    if OS.linux?
      inreplace "SConstruct" do |s|
        s.gsub! "env.Append(LIBPATH=['$OPENSSL/lib'])",
        "\\1\nenv.Append(CPPPATH=['$ZLIB/include'])\nenv.Append(LIBPATH=['$ZLIB/lib'])"
      end
    end

    inreplace "SConstruct" do |s|
      s.gsub! "variables=opts,",
      "variables=opts, RPATHPREFIX = '-Wl,-rpath,',"
    end

    # scons ignores our compiler and flags unless explicitly passed
    krb5 = if OS.mac?
      "/usr"
    else
      Formula["krb5"].opt_prefix
    end

    args = %W[
      PREFIX=#{prefix} GSSAPI=#{krb5} CC=#{ENV.cc}
      CFLAGS=#{ENV.cflags} LINKFLAGS=#{ENV.ldflags}
      OPENSSL=#{Formula["openssl@3"].opt_prefix}
      APR=#{Formula["apr"].opt_prefix}
      APU=#{Formula["apr-util"].opt_prefix}
    ]

    args << "ZLIB=#{Formula["zlib"].opt_prefix}" if OS.linux?

    system "scons", *args
    system "scons", "install"
  end

  test do
    (testpath/"test.c").write <<~C
      #include <serf.h>
      #include <stdio.h>

      int main(void) {
        int major, minor, patch;
        serf_lib_version(&major, &minor, &patch);
        printf("%d.%d.%d", major, minor, patch);
        return 0;
      }
    C

    ENV.append_path "PKG_CONFIG_PATH", Formula["apr"].opt_lib/"pkgconfig"
    ENV.append_path "PKG_CONFIG_PATH", Formula["apr-util"].opt_lib/"pkgconfig"
    flags = shell_output("pkgconf --cflags --libs serf-1 apr-1 apr-util-1").chomp.split
    system ENV.cc, "test.c", "-o", "test", *flags

    assert_equal version.to_s, shell_output("./test")
  end
end
