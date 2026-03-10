class GatherWindows < Formula
  desc "macOS CLI that moves windows from external displays to built-in display"
  homepage "https://github.com/bsander/homebrew-gather-windows"
  url "https://github.com/bsander/homebrew-gather-windows/releases/download/v0.2026.0310.1/gather-windows-v0.2026.0310.1-macos.tar.gz"
  version "0.2026.0310.1"
  sha256 "8af7dbbeecd82655337ab795558386606ee41b112ec600b5a12185c2654e8b77"
  license "MIT"

  depends_on :macos

  def install
    bin.install "gather-windows"
  end

  test do
    assert_match "OVERVIEW:", shell_output("#{bin}/gather-windows --help")
  end
end
