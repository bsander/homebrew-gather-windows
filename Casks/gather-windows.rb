cask "gather-windows" do
  version "0.2026.0313"
  sha256 "16eee3c5f8b529d1af7e4ac84169c45823ea57ce2408d694b3247a9d0692e0a9"

  url "https://github.com/bsander/homebrew-gather-windows/releases/download/v0.2026.0313/Gather-Windows-v0.2026.0313.zip"
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
