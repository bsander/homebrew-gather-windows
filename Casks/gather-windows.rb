cask "gather-windows" do
  version "0.2026.0313.1"
  sha256 "33ff262c4d4fc33ff054577b98b35993e5316d115ac92318dc14f51f6a34534c"

  url "https://github.com/bsander/homebrew-gather-windows/releases/download/v0.2026.0313.1/Gather-Windows-v0.2026.0313.1.zip"
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
