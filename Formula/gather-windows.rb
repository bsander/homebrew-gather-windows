class GatherWindows < Formula
  desc "macOS CLI that moves windows from external displays to built-in display"
  homepage "https://github.com/bsander/homebrew-gather-windows"
  url "https://github.com/bsander/homebrew-gather-windows/releases/download/v0.2026.0313.2/gather-windows-v0.2026.0313.2-macos.tar.gz"
  version "0.2026.0313.2"
  sha256 "8d0e0785ac544d461143c936ec79ca97b5dce80fe94f0aacf656510e32f07291"
  license "MIT"

  depends_on :macos

  def install
    bin.install "gather-windows"
  end

  test do
    assert_match "OVERVIEW:", shell_output("#{bin}/gather-windows --help")
  end
end
