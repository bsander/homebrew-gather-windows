class GatherWindows < Formula
  desc "macOS CLI that moves windows from external displays to built-in display"
  homepage "https://github.com/bsander/homebrew-gather-windows"
  url "https://github.com/bsander/homebrew-gather-windows/releases/download/v0.2026.0313.3/gather-windows-v0.2026.0313.3-macos.tar.gz"
  version "0.2026.0313.3"
  sha256 "7084a731c9d881b005b996a84e541a9e4c9ceda49ba4ba93bc84ddbc979b4f76"
  license "MIT"

  depends_on :macos

  def install
    bin.install "gather-windows"
  end

  test do
    assert_match "OVERVIEW:", shell_output("#{bin}/gather-windows --help")
  end
end
