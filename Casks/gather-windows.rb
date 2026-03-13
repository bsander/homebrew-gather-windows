cask "gather-windows" do
  version "0.2026.0313.2"
  sha256 "523f659c9aeca2f9a19654806eb2029fe6c4e39dd6cef83035da574057a63087"

  url "https://github.com/bsander/homebrew-gather-windows/releases/download/v0.2026.0313.2/Gather-Windows-v0.2026.0313.2.zip"
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
