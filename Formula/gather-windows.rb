class GatherWindows < Formula
  desc "macOS CLI that moves windows from external displays to built-in display"
  homepage "https://github.com/bsander/homebrew-gather-windows"
  url "https://github.com/bsander/homebrew-gather-windows/releases/download/v0.2026.0313/gather-windows-v0.2026.0313-macos.tar.gz"
  version "0.2026.0313"
  sha256 "d50e8c5d4a8d5fde1356dbb72d49bc576c3995a1c7c98a0c1f82435d7005c13d"
  license "MIT"

  depends_on :macos

  def install
    bin.install "gather-windows"
  end

  test do
    assert_match "OVERVIEW:", shell_output("#{bin}/gather-windows --help")
  end
end
