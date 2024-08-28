class Zx < Formula
  desc "Tool for writing better scripts"
  homepage "https://github.com/google/zx"
  url "https://registry.npmjs.org/zx/-/zx-8.1.5.tgz"
  sha256 "0e395f2bcaa39240b23a15277e12d17b6d01d81fe0d88250c3654b92fb123107"
  license "Apache-2.0"

  bottle do
    rebuild 2
    sha256 cellar: :any_skip_relocation, all: "3cbc1055efd0b053b9d83760d3fe209894a2546a1031c757198a88a70ead82ad"
  end

  depends_on "node"

  def install
    system "npm", "install", *std_npm_args
    bin.install_symlink Dir["#{libexec}/bin/*"]

    # Make the bottles uniform
    inreplace_file = libexec/"lib/node_modules/zx/node_modules/@types/node/process.d.ts"
    inreplace inreplace_file, "/usr/local/bin", "#{HOMEBREW_PREFIX}/bin"
  end

  test do
    (testpath/"test.mjs").write <<~EOS
      #!/usr/bin/env zx

      let name = YAML.parse('foo: bar').foo
      console.log(`name is ${name}`)
      await $`touch ${name}`
    EOS

    output = shell_output("#{bin}/zx #{testpath}/test.mjs")
    assert_match "name is bar", output
    assert_predicate testpath/"bar", :exist?

    assert_match version.to_s, shell_output("#{bin}/zx --version")
  end
end
