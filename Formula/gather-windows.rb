class GatherWindows < Formula
  desc "macOS CLI that moves windows from external displays to built-in display"
  homepage "https://github.com/bsander/homebrew-gather-windows"
  url "https://github.com/bsander/homebrew-gather-windows/releases/download/v0.2026.0311.1/gather-windows-v0.2026.0311.1-macos.tar.gz"
  version "0.2026.0311.1"
  sha256 "3e03c1126f93b348f80e04d14f626dc080017f4cb7762c963f5a65a648cd2e6e"
  license "MIT"

  depends_on :macos

  def install
    bin.install "gather-windows"
  end

  test do
    assert_match "OVERVIEW:", shell_output("#{bin}/gather-windows --help")
  end
end
