cask "gather-windows" do
  version "0.2026.0311.1"
  sha256 "b75a294c4ab84f0c8e244cb5001ceb0ce056ea9b55f37abfebe80e546edb70f6"

  url "https://github.com/bsander/homebrew-gather-windows/releases/download/v0.2026.0311.1/Gather-Windows-v0.2026.0311.1.zip"
  name "Gather Windows"
  desc "Move windows from external displays to a target display"
  homepage "https://github.com/bsander/homebrew-gather-windows"

  depends_on macos: ">= :sonoma"

  app "Gather Windows.app"

  binary "#{appdir}/Gather Windows.app/Contents/MacOS/Gather Windows", target: "gather-windows"

  zap trash: [
    "~/Library/Preferences/com.vibed.gather-windows.plist",
  ]
end
