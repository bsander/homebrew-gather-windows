cask "gather-windows" do
  version "0.2026.0313.4"
  sha256 "d32026221f4e00f4884a8a0e4007a7a69a98c1597edbe72611b8e383abe5b894"

  url "https://github.com/bsander/homebrew-gather-windows/releases/download/v0.2026.0313.4/Gather-Windows-v0.2026.0313.4.zip"
  name "Gather Windows"
  desc "Move windows from external displays to a target display"
  homepage "https://github.com/bsander/homebrew-gather-windows"

  depends_on macos: ">= :sonoma"

  app "Gather Windows.app"

  binary "#{appdir}/Gather Windows.app/Contents/MacOS/Gather Windows", target: "gather-windows"

  postflight do
    system_command "/usr/bin/xattr",
                   args: ["-cr", "#{appdir}/Gather Windows.app"]
  end

  zap trash: [
    "~/Library/Preferences/com.vibed.gather-windows.plist",
  ]
end
