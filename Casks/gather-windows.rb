cask "gather-windows" do
  version "0.2026.0313.3"
  sha256 "c62d0992edc734e3bfb4efad07005692e876b688bbae2b1104b4ed172cefb501"

  url "https://github.com/bsander/homebrew-gather-windows/releases/download/v0.2026.0313.3/Gather-Windows-v0.2026.0313.3.zip"
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
