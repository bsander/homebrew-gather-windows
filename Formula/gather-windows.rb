class GatherWindows < Formula
  desc "macOS CLI that moves windows from external displays to built-in display"
  homepage "https://github.com/bsander/homebrew-gather-windows"
  url "https://github.com/bsander/homebrew-gather-windows/releases/download/v0.2026.0311/gather-windows-v0.2026.0311-macos.tar.gz"
  version "0.2026.0311"
  sha256 "319578731a3176209d2c7a3af2610a97607b4a8e51985d7aac1424aeb0cd816e"
  license "MIT"

  depends_on :macos

  def install
    bin.install "gather-windows"
  end

  test do
    assert_match "OVERVIEW:", shell_output("#{bin}/gather-windows --help")
  end
end
